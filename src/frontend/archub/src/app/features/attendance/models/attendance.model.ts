export type AttendancePunchType = 'in' | 'out' | 'break_start' | 'break_end';

export interface AttendancePunch {
  readonly id: string | number;
  readonly time: string;
  readonly type: AttendancePunchType;
  readonly device?: string;
  readonly location?: string;
  readonly isManual?: boolean;
  readonly note?: string;
}

export type AnomalySeverity = 'critical' | 'warning' | 'info';

export interface AttendanceAnomaly {
  readonly code: string;
  readonly message: string;
  readonly severity: AnomalySeverity;
  readonly resolved?: boolean;
}

export type DailyAttendanceStatus = 'present' | 'absent' | 'leave' | 'holiday' | 'incomplete';

export interface DailyAttendanceReport {
  readonly date: string; // YYYY-MM-DD
  readonly dayOfWeek: string; // e.g. "Mon"
  readonly dayNumber: number; // e.g. 1
  readonly isWeekend: boolean;
  readonly isHoliday: boolean;
  readonly holidayName?: string;
  readonly expectedHours: number;
  readonly workedHours: number;
  readonly overtimeHours: number;
  readonly balanceHours: number;
  readonly status: DailyAttendanceStatus;
  readonly punches: readonly AttendancePunch[];
  readonly anomalies: readonly AttendanceAnomaly[];
  readonly hasAnomalies: boolean;
  readonly note?: string;
}

export interface MonthlyAttendanceReportSummary {
  readonly totalWorkedHours: number;
  readonly totalExpectedHours: number;
  readonly totalOvertimeHours: number;
  readonly totalBalanceHours: number;
  readonly totalWorkingDays: number;
  readonly presentDays: number;
  readonly absentDays: number;
  readonly leaveDays: number;
  readonly anomaliesCount: number;
}

export interface MonthlyAttendanceReport {
  readonly year: number;
  readonly month: number;
  readonly monthName: string;
  readonly employeeId: number | string;
  readonly employeeName: string;
  readonly department?: string;
  readonly summary: MonthlyAttendanceReportSummary;
  readonly days: readonly DailyAttendanceReport[];
}

export interface AttendanceFilter {
  readonly year: number;
  readonly month: number;
  readonly onlyAnomalies: boolean;
}
