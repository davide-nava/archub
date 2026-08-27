import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, catchError, map, of } from 'rxjs';
import { environment } from '@env/environment';
import { ApiResponse } from '@core/models/api-response.model';
import {
  AttendanceFilter,
  AttendancePunch,
  AttendancePunchType,
  DailyAttendanceReport,
  MonthlyAttendanceReport,
  MonthlyAttendanceReportSummary
} from '../models/attendance.model';

@Injectable({
  providedIn: 'root'
})
export class AttendanceService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/attendance`;

  /**
   * Retrieves the comprehensive monthly attendance report for a specified year and month.
   */
  public getMonthlyReport(filter: AttendanceFilter): Observable<MonthlyAttendanceReport> {
    const params = new HttpParams()
      .set('year', filter.year.toString())
      .set('month', filter.month.toString())
      .set('only_anomalies', filter.onlyAnomalies ? '1' : '0');

    return this.http
      .get<ApiResponse<MonthlyAttendanceReport>>(`${this.baseUrl}/monthly-report`, { params })
      .pipe(
        map((response) => response.data),
        catchError(() => {
          // Graceful fallback to generate realistic monthly dataset for offline dev / demo
          return of(this.generateMockMonthlyReport(filter.year, filter.month));
        })
      );
  }

  /**
   * Submits a manual or automated time clock punch to the Laravel backend.
   */
  public recordPunch(payload: {
    type: AttendancePunchType;
    note?: string;
    location?: string;
  }): Observable<AttendancePunch> {
    return this.http
      .post<ApiResponse<AttendancePunch>>(`${this.baseUrl}/punch`, payload)
      .pipe(
        map((response) => response.data),
        catchError(() => {
          const mockPunch: AttendancePunch = {
            id: `punch_${Date.now()}`,
            time: new Date().toTimeString().substring(0, 5),
            type: payload.type,
            device: 'Web Portal',
            location: payload.location ?? 'HQ Office',
            isManual: true,
            note: payload.note
          };
          return of(mockPunch);
        })
      );
  }

  /**
   * Submits justification or resolution request for an attendance anomaly.
   */
  public resolveAnomaly(date: string, code: string, justification: string): Observable<boolean> {
    return this.http
      .post<ApiResponse<{ resolved: boolean }>>(`${this.baseUrl}/anomalies/resolve`, {
        date,
        code,
        justification
      })
      .pipe(
        map((response) => response.data.resolved),
        catchError(() => of(true))
      );
  }

  /**
   * Generates mock monthly attendance report adhering strictly to domain business logic.
   */
  private generateMockMonthlyReport(year: number, month: number): MonthlyAttendanceReport {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthName = monthNames[month - 1] ?? 'Current Month';
    const daysInMonth = new Date(year, month, 0).getDate();
    const dayOfWeekNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    const days: DailyAttendanceReport[] = [];
    let totalWorkedHours = 0;
    let totalExpectedHours = 0;
    let totalOvertimeHours = 0;
    let totalWorkingDays = 0;
    let presentDays = 0;
    let absentDays = 0;
    const leaveDays = 0;
    let anomaliesCount = 0;

    for (let day = 1; day <= daysInMonth; day++) {
      const dateObj = new Date(year, month - 1, day);
      const dayOfWeekIndex = dateObj.getDay();
      const dayOfWeek = dayOfWeekNames[dayOfWeekIndex] ?? 'Mon';
      const isWeekend = dayOfWeekIndex === 0 || dayOfWeekIndex === 6;
      const formattedDate = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;

      // Fixed holiday for demonstration (e.g., Aug 15 or Jan 1)
      const isHoliday = (month === 8 && day === 15) || (month === 1 && day === 1) || (month === 12 && day === 25);
      const holidayName = isHoliday ? (month === 8 ? 'Ferragosto / Assumption' : 'Public Holiday') : undefined;

      if (isWeekend || isHoliday) {
        days.push({
          date: formattedDate,
          dayOfWeek,
          dayNumber: day,
          isWeekend,
          isHoliday,
          holidayName,
          expectedHours: 0,
          workedHours: 0,
          overtimeHours: 0,
          balanceHours: 0,
          status: isHoliday ? 'holiday' : 'absent',
          punches: [],
          anomalies: [],
          hasAnomalies: false,
          note: isHoliday ? holidayName : 'Weekend'
        });
        continue;
      }

      totalWorkingDays++;
      const expected = 8.0;
      totalExpectedHours += expected;

      // Simulate varying day patterns (Regular, Overtime, Anomalous, Absent)
      if (day === 4) {
        // Missing OUT punch anomaly
        anomaliesCount++;
        days.push({
          date: formattedDate,
          dayOfWeek,
          dayNumber: day,
          isWeekend: false,
          isHoliday: false,
          expectedHours: expected,
          workedHours: 4.0,
          overtimeHours: 0,
          balanceHours: -4.0,
          status: 'incomplete',
          punches: [
            { id: `p_${day}_1`, time: '09:02', type: 'in', device: 'Turnstile A' }
          ],
          anomalies: [
            {
              code: 'MISSING_CLOCK_OUT',
              message: 'Missing evening clock-out punch. Action required.',
              severity: 'critical',
              resolved: false
            }
          ],
          hasAnomalies: true,
          note: 'Requires manager approval for clock-out'
        });
      } else if (day === 11) {
        // Late arrival & short day anomaly
        anomaliesCount++;
        days.push({
          date: formattedDate,
          dayOfWeek,
          dayNumber: day,
          isWeekend: false,
          isHoliday: false,
          expectedHours: expected,
          workedHours: 6.5,
          overtimeHours: 0,
          balanceHours: -1.5,
          status: 'present',
          punches: [
            { id: `p_${day}_1`, time: '10:30', type: 'in', device: 'Turnstile B' },
            { id: `p_${day}_2`, time: '13:00', type: 'break_start' },
            { id: `p_${day}_3`, time: '14:00', type: 'break_end' },
            { id: `p_${day}_4`, time: '18:00', type: 'out', device: 'Turnstile B' }
          ],
          anomalies: [
            {
              code: 'LATE_ARRIVAL',
              message: 'Arrival at 10:30 exceeds core shift window (09:00 max).',
              severity: 'warning',
              resolved: false
            }
          ],
          hasAnomalies: true
        });
        totalWorkedHours += 6.5;
        presentDays++;
      } else if (day === 18) {
        // Excessive overtime unapproved anomaly
        anomaliesCount++;
        const worked = 10.5;
        const overtime = 2.5;
        totalWorkedHours += worked;
        totalOvertimeHours += overtime;
        presentDays++;

        days.push({
          date: formattedDate,
          dayOfWeek,
          dayNumber: day,
          isWeekend: false,
          isHoliday: false,
          expectedHours: expected,
          workedHours: worked,
          overtimeHours: overtime,
          balanceHours: overtime,
          status: 'present',
          punches: [
            { id: `p_${day}_1`, time: '08:45', type: 'in', device: 'Turnstile A' },
            { id: `p_${day}_2`, time: '12:30', type: 'break_start' },
            { id: `p_${day}_3`, time: '13:15', type: 'break_end' },
            { id: `p_${day}_4`, time: '20:00', type: 'out', device: 'Turnstile A' }
          ],
          anomalies: [
            {
              code: 'OVERTIME_UNAPPROVED',
              message: 'Overtime (>2.0h) exceeded without pre-authorization.',
              severity: 'warning',
              resolved: false
            }
          ],
          hasAnomalies: true
        });
      } else if (day === 22) {
        // Unexcused absence
        absentDays++;
        days.push({
          date: formattedDate,
          dayOfWeek,
          dayNumber: day,
          isWeekend: false,
          isHoliday: false,
          expectedHours: expected,
          workedHours: 0,
          overtimeHours: 0,
          balanceHours: -8.0,
          status: 'absent',
          punches: [],
          anomalies: [
            {
              code: 'ABSENT_WITHOUT_NOTICE',
              message: 'No punches recorded and no leave request filed.',
              severity: 'critical',
              resolved: false
            }
          ],
          hasAnomalies: true,
          note: 'Unexcused Absence'
        });
        anomaliesCount++;
      } else {
        // Standard normal working day (8.0 to 8.5 hours)
        const worked = day % 3 === 0 ? 8.5 : 8.0;
        const overtime = worked > expected ? worked - expected : 0;
        totalWorkedHours += worked;
        totalOvertimeHours += overtime;
        presentDays++;

        days.push({
          date: formattedDate,
          dayOfWeek,
          dayNumber: day,
          isWeekend: false,
          isHoliday: false,
          expectedHours: expected,
          workedHours: worked,
          overtimeHours: overtime,
          balanceHours: worked - expected,
          status: 'present',
          punches: [
            { id: `p_${day}_1`, time: '08:58', type: 'in', device: 'Turnstile A' },
            { id: `p_${day}_2`, time: '12:45', type: 'break_start' },
            { id: `p_${day}_3`, time: '13:45', type: 'break_end' },
            {
              id: `p_${day}_4`,
              time: worked > 8.0 ? '18:28' : '17:58',
              type: 'out',
              device: 'Turnstile A'
            }
          ],
          anomalies: [],
          hasAnomalies: false
        });
      }
    }

    const summary: MonthlyAttendanceReportSummary = {
      totalWorkedHours: Math.round(totalWorkedHours * 10) / 10,
      totalExpectedHours: Math.round(totalExpectedHours * 10) / 10,
      totalOvertimeHours: Math.round(totalOvertimeHours * 10) / 10,
      totalBalanceHours: Math.round((totalWorkedHours - totalExpectedHours) * 10) / 10,
      totalWorkingDays,
      presentDays,
      absentDays,
      leaveDays,
      anomaliesCount
    };

    return {
      year,
      month,
      monthName,
      employeeId: 101,
      employeeName: 'Alex Mercer',
      department: 'Platform Engineering',
      summary,
      days
    };
  }
}
