import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { AttendanceAnomaly } from '../../models/attendance.model';

@Component({
  selector: 'app-anomaly-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div
      class="anomaly-badge"
      [class.severity-critical]="anomaly().severity === 'critical'"
      [class.severity-warning]="anomaly().severity === 'warning'"
      [class.severity-info]="anomaly().severity === 'info'"
      role="status"
      [attr.aria-label]="ariaDescription()"
    >
      <svg
        class="anomaly-icon"
        viewBox="0 0 20 20"
        fill="currentColor"
        aria-hidden="true"
      >
        <path
          fill-rule="evenodd"
          d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
          clip-rule="evenodd"
        />
      </svg>
      <div class="anomaly-content">
        <span class="anomaly-code">{{ anomaly().code }}</span>
        @if (!compact()) {
          <span class="anomaly-message">{{ anomaly().message }}</span>
        }
      </div>
    </div>
  `,
  styles: [`
    :host {
      display: inline-block;
      max-width: 100%;
    }

    .anomaly-badge {
      display: inline-flex;
      align-items: flex-start;
      gap: 0.375rem;
      padding: 0.25rem 0.5rem;
      border-radius: 0.375rem;
      font-size: 0.75rem;
      line-height: 1.25;
      border: 1px solid transparent;
      max-width: 100%;
    }

    .anomaly-icon {
      width: 0.875rem;
      height: 0.875rem;
      flex-shrink: 0;
      margin-top: 0.05rem;
    }

    .anomaly-content {
      display: flex;
      flex-direction: column;
      gap: 0.125rem;
      word-break: break-word;
    }

    .anomaly-code {
      font-weight: 700;
      letter-spacing: 0.02em;
    }

    .anomaly-message {
      font-weight: 400;
      opacity: 0.9;
    }

    .severity-critical {
      background-color: #fef2f2;
      color: #991b1b;
      border-color: #fecaca;

      .anomaly-icon {
        color: #dc2626;
      }
    }

    .severity-warning {
      background-color: #fffbeb;
      color: #92400e;
      border-color: #fde68a;

      .anomaly-icon {
        color: #d97706;
      }
    }

    .severity-info {
      background-color: #f0f9ff;
      color: #075985;
      border-color: #bae6fd;

      .anomaly-icon {
        color: #0284c7;
      }
    }
  `]
})
export class AnomalyBadgeComponent {
  public readonly anomaly = input.required<AttendanceAnomaly>();
  public readonly compact = input<boolean>(false);

  protected readonly ariaDescription = computed<string>(() => {
    const a = this.anomaly();
    return `Anomaly [${a.severity.toUpperCase()}]: ${a.code} - ${a.message}`;
  });
}
