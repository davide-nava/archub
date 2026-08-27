import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  computed,
  inject,
  signal
} from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { AttendanceService } from '../../services/attendance.service';
import {
  AttendanceFilter,
  AttendancePunchType,
  DailyAttendanceReport,
  MonthlyAttendanceReport,
  MonthlyAttendanceReportSummary
} from '../../models/attendance.model';
import { KpiCardComponent } from '../../components/kpi-card/kpi-card.component';
import { PunchBadgeComponent } from '../../components/punch-badge/punch-badge.component';
import { AnomalyBadgeComponent } from '../../components/anomaly-badge/anomaly-badge.component';
import { AuthService } from '@core/services/auth.service';

export interface MonthOption {
  readonly value: number;
  readonly label: string;
}

@Component({
  selector: 'app-monthly-report',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    ReactiveFormsModule,
    KpiCardComponent,
    PunchBadgeComponent,
    AnomalyBadgeComponent
  ],
  templateUrl: './monthly-report.component.html',
  styleUrl: './monthly-report.component.scss'
})
export class MonthlyReportComponent implements OnInit {
  private readonly attendanceService = inject(AttendanceService);
  protected readonly authService = inject(AuthService);

  // State Signals
  protected readonly isLoading = signal<boolean>(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly successMessage = signal<string | null>(null);
  protected readonly reportData = signal<MonthlyAttendanceReport | null>(null);
  protected readonly isPunching = signal<boolean>(false);

  // Filter Form State
  protected readonly filterForm = new FormGroup({
    year: new FormControl<number>(2026, { nonNullable: true }),
    month: new FormControl<number>(8, { nonNullable: true }),
    onlyAnomalies: new FormControl<boolean>(false, { nonNullable: true })
  });

  // Current Filter Signal
  protected readonly activeFilter = signal<AttendanceFilter>({
    year: 2026,
    month: 8,
    onlyAnomalies: false
  });

  // Options
  protected readonly yearOptions = signal<readonly number[]>([2024, 2025, 2026, 2027]);
  protected readonly monthOptions = signal<readonly MonthOption[]>([
    { value: 1, label: 'January' },
    { value: 2, label: 'February' },
    { value: 3, label: 'March' },
    { value: 4, label: 'April' },
    { value: 5, label: 'May' },
    { value: 6, label: 'June' },
    { value: 7, label: 'July' },
    { value: 8, label: 'August' },
    { value: 9, label: 'September' },
    { value: 10, label: 'October' },
    { value: 11, label: 'November' },
    { value: 12, label: 'December' }
  ]);

  // Derived Computed State
  public readonly summary = computed<MonthlyAttendanceReportSummary | null>(
    () => this.reportData()?.summary ?? null
  );

  public readonly allDays = computed<readonly DailyAttendanceReport[]>(
    () => this.reportData()?.days ?? []
  );

  public readonly displayedDays = computed<readonly DailyAttendanceReport[]>(() => {
    const days = this.allDays();
    if (this.activeFilter().onlyAnomalies) {
      return days.filter((d) => d.hasAnomalies);
    }
    return days;
  });

  public readonly workedHoursProgress = computed<string>(() => {
    const sum = this.summary();
    if (!sum || sum.totalExpectedHours === 0) return '0%';
    const pct = Math.min(Math.round((sum.totalWorkedHours / sum.totalExpectedHours) * 100), 100);
    return `${pct}% of expected ${sum.totalExpectedHours}h`;
  });

  public readonly overtimeFormatted = computed<string>(() => {
    const sum = this.summary();
    if (!sum) return '0.0h';
    const sign = sum.totalOvertimeHours > 0 ? '+' : '';
    return `${sign}${sum.totalOvertimeHours.toFixed(1)}h`;
  });

  public readonly balanceFormatted = computed<string>(() => {
    const sum = this.summary();
    if (!sum) return '0.0h';
    const sign = sum.totalBalanceHours > 0 ? '+' : '';
    return `${sign}${sum.totalBalanceHours.toFixed(1)}h`;
  });

  public readonly workingDaysRatio = computed<string>(() => {
    const sum = this.summary();
    if (!sum) return '0 / 0';
    return `${sum.presentDays} / ${sum.totalWorkingDays}`;
  });

  public ngOnInit(): void {
    this.fetchReport(this.activeFilter());
  }

  public onApplyFilter(): void {
    const formValues = this.filterForm.getRawValue();
    const updatedFilter: AttendanceFilter = {
      year: formValues.year,
      month: formValues.month,
      onlyAnomalies: formValues.onlyAnomalies
    };

    this.activeFilter.set(updatedFilter);
    this.fetchReport(updatedFilter);
  }

  public onResetFilter(): void {
    const defaultFilter: AttendanceFilter = {
      year: 2026,
      month: 8,
      onlyAnomalies: false
    };

    this.filterForm.setValue(defaultFilter);
    this.activeFilter.set(defaultFilter);
    this.fetchReport(defaultFilter);
  }

  public onToggleAnomaliesOnly(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.filterForm.controls.onlyAnomalies.setValue(input.checked);
    this.onApplyFilter();
  }

  public recordQuickPunch(type: AttendancePunchType): void {
    this.isPunching.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);

    const typeLabel = type === 'in' ? 'Clocked In' : type === 'out' ? 'Clocked Out' : 'Break Logged';

    this.attendanceService.recordPunch({ type }).subscribe({
      next: (punch) => {
        this.isPunching.set(false);
        this.successMessage.set(`Successfully recorded ${typeLabel} at ${punch.time}.`);
        // Refresh report
        this.fetchReport(this.activeFilter());
        // Clear message after 4s
        setTimeout(() => this.successMessage.set(null), 4000);
      },
      error: () => {
        this.isPunching.set(false);
        this.errorMessage.set('Failed to register punch. Please verify network connection.');
      }
    });
  }

  public resolveAnomaly(day: DailyAttendanceReport, anomalyCode: string): void {
    this.attendanceService.resolveAnomaly(day.date, anomalyCode, 'Approved by supervisor').subscribe({
      next: () => {
        this.successMessage.set(`Anomaly [${anomalyCode}] for ${day.date} submitted for resolution.`);
        this.fetchReport(this.activeFilter());
        setTimeout(() => this.successMessage.set(null), 4000);
      }
    });
  }

  private fetchReport(filter: AttendanceFilter): void {
    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.attendanceService.getMonthlyReport(filter).subscribe({
      next: (report) => {
        this.reportData.set(report);
        this.isLoading.set(false);
      },
      error: (err: unknown) => {
        this.isLoading.set(false);
        this.errorMessage.set('Unable to load attendance monthly report from the server.');
        console.error('[MonthlyReportComponent] Fetch error:', err);
      }
    });
  }
}
