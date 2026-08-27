import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { AttendancePunch } from '../../models/attendance.model';

@Component({
  selector: 'app-punch-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span
      class="punch-badge"
      [class.punch-in]="punch().type === 'in'"
      [class.punch-out]="punch().type === 'out'"
      [class.punch-break-start]="punch().type === 'break_start'"
      [class.punch-break-end]="punch().type === 'break_end'"
      [attr.title]="tooltipText()"
    >
      <span class="punch-indicator" aria-hidden="true"></span>
      <span class="punch-type">{{ typeLabel() }}</span>
      <span class="punch-time">{{ punch().time }}</span>
      @if (punch().isManual) {
        <span class="manual-tag" title="Manual entry">*</span>
      }
    </span>
  `,
  styles: [`
    :host {
      display: inline-block;
    }

    .punch-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.375rem;
      padding: 0.2rem 0.5rem;
      border-radius: 0.375rem;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 0.75rem;
      font-weight: 500;
      line-height: 1.2;
      border: 1px solid transparent;
      user-select: none;
      transition: all 0.15s ease-in-out;

      &:hover {
        transform: translateY(-1px);
      }
    }

    .punch-indicator {
      width: 6px;
      height: 6px;
      border-radius: 50%;
    }

    .punch-type {
      font-weight: 700;
      letter-spacing: 0.02em;
    }

    .punch-time {
      font-weight: 600;
    }

    .manual-tag {
      font-weight: 800;
      color: #b45309;
    }

    /* IN Punch: Emerald */
    .punch-in {
      background-color: #ecfdf5;
      color: #065f46;
      border-color: #a7f3d0;

      .punch-indicator {
        background-color: #10b981;
      }
    }

    /* OUT Punch: Indigo / Slate */
    .punch-out {
      background-color: #eef2ff;
      color: #3730a3;
      border-color: #c7d2fe;

      .punch-indicator {
        background-color: #6366f1;
      }
    }

    /* BREAK START Punch: Amber */
    .punch-break-start {
      background-color: #fffbeb;
      color: #92400e;
      border-color: #fde68a;

      .punch-indicator {
        background-color: #f59e0b;
      }
    }

    /* BREAK END Punch: Cyan / Teal */
    .punch-break-end {
      background-color: #f0fdfa;
      color: #115e59;
      border-color: #99f6e4;

      .punch-indicator {
        background-color: #14b8a6;
      }
    }
  `]
})
export class PunchBadgeComponent {
  public readonly punch = input.required<AttendancePunch>();

  protected readonly typeLabel = computed<string>(() => {
    switch (this.punch().type) {
      case 'in':
        return 'IN';
      case 'out':
        return 'OUT';
      case 'break_start':
        return 'BRK-OUT';
      case 'break_end':
        return 'BRK-IN';
      default:
        return 'PUNCH';
    }
  });

  protected readonly tooltipText = computed<string>(() => {
    const p = this.punch();
    const parts = [`${this.typeLabel()} at ${p.time}`];
    if (p.device) parts.push(`Device: ${p.device}`);
    if (p.location) parts.push(`Location: ${p.location}`);
    if (p.isManual) parts.push('(Manual adjustment)');
    if (p.note) parts.push(`Note: ${p.note}`);
    return parts.join(' | ');
  });
}
