import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

export type KpiTone = 'default' | 'primary' | 'success' | 'warning' | 'danger';

@Component({
  selector: 'app-kpi-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div
      class="kpi-card"
      [class.tone-default]="tone() === 'default'"
      [class.tone-primary]="tone() === 'primary'"
      [class.tone-success]="tone() === 'success'"
      [class.tone-warning]="tone() === 'warning'"
      [class.tone-danger]="tone() === 'danger'"
      role="region"
      [attr.aria-label]="ariaLabel()"
    >
      <div class="kpi-header">
        <span class="kpi-title">{{ title() }}</span>
        @if (badge()) {
          <span
            class="kpi-badge"
            [class.badge-default]="tone() === 'default'"
            [class.badge-primary]="tone() === 'primary'"
            [class.badge-success]="tone() === 'success'"
            [class.badge-warning]="tone() === 'warning'"
            [class.badge-danger]="tone() === 'danger'"
          >
            {{ badge() }}
          </span>
        }
      </div>

      <div class="kpi-body">
        <div class="kpi-value">{{ value() }}</div>
        @if (subtitle()) {
          <div class="kpi-subtitle">{{ subtitle() }}</div>
        }
      </div>
    </div>
  `,
  styles: [`
    :host {
      display: block;
      height: 100%;
    }

    .kpi-card {
      background: #ffffff;
      border: 1px solid #e2e8f0;
      border-radius: 0.75rem;
      padding: 1.25rem;
      box-shadow: 0 1px 3px 0 rgba(15, 23, 42, 0.05);
      transition: box-shadow 0.2s ease, border-color 0.2s ease;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      height: 100%;
      box-sizing: border-box;

      &:hover {
        border-color: #cbd5e1;
        box-shadow: 0 4px 6px -1px rgba(15, 23, 42, 0.08);
      }

      &.tone-primary {
        border-left: 4px solid #2563eb;
      }

      &.tone-success {
        border-left: 4px solid #16a34a;
      }

      &.tone-warning {
        border-left: 4px solid #d97706;
      }

      &.tone-danger {
        border-left: 4px solid #dc2626;
      }
    }

    .kpi-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 0.5rem;
      margin-bottom: 0.75rem;
    }

    .kpi-title {
      font-size: 0.8125rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #64748b;
    }

    .kpi-badge {
      font-size: 0.75rem;
      font-weight: 600;
      padding: 0.125rem 0.5rem;
      border-radius: 9999px;
      line-height: 1.25;

      &.badge-default {
        background-color: #f1f5f9;
        color: #475569;
      }
      &.badge-primary {
        background-color: #eff6ff;
        color: #1d4ed8;
      }
      &.badge-success {
        background-color: #f0fdf4;
        color: #15803d;
      }
      &.badge-warning {
        background-color: #fffbeb;
        color: #b45309;
      }
      &.badge-danger {
        background-color: #fef2f2;
        color: #b91c1c;
      }
    }

    .kpi-body {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }

    .kpi-value {
      font-size: 1.75rem;
      font-weight: 700;
      color: #0f172a;
      line-height: 1.15;
      letter-spacing: -0.02em;
    }

    .kpi-subtitle {
      font-size: 0.8125rem;
      color: #64748b;
    }
  `]
})
export class KpiCardComponent {
  public readonly title = input.required<string>();
  public readonly value = input.required<string | number>();
  public readonly subtitle = input<string | undefined>(undefined);
  public readonly tone = input<KpiTone>('default');
  public readonly badge = input<string | undefined>(undefined);

  protected readonly ariaLabel = computed<string>(() => {
    const sub = this.subtitle() ? `, ${this.subtitle()}` : '';
    return `${this.title()}: ${this.value()}${sub}`;
  });
}
