import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { AttendanceService } from './attendance.service';

describe('AttendanceService', () => {
  let service: AttendanceService;
  let httpTestingController: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AttendanceService,
        provideHttpClient(),
        provideHttpClientTesting()
      ]
    });

    service = TestBed.inject(AttendanceService);
    httpTestingController = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpTestingController.verify();
  });

  it('should fetch monthly attendance report with correct query parameters', () => {
    const filter = { year: 2026, month: 8, onlyAnomalies: false };

    service.getMonthlyReport(filter).subscribe((report) => {
      expect(report).toBeDefined();
      expect(report.year).toBe(2026);
      expect(report.month).toBe(8);
      expect(report.days.length).toBe(1);
      expect(report.summary).toBeDefined();
    });

    const req = httpTestingController.expectOne((r) =>
      r.url.includes('/attendance/monthly-report') &&
      r.params.get('year') === '2026' &&
      r.params.get('month') === '8'
    );

    req.flush({
      success: true,
      data: {
        year: 2026,
        month: 8,
        monthName: 'August',
        employeeId: 101,
        employeeName: 'Alex Mercer',
        summary: {
          totalWorkedHours: 8.0,
          totalExpectedHours: 8.0,
          totalOvertimeHours: 0,
          totalBalanceHours: 0,
          totalWorkingDays: 1,
          presentDays: 1,
          absentDays: 0,
          leaveDays: 0,
          anomaliesCount: 0
        },
        days: [
          {
            date: '2026-08-01',
            dayOfWeek: 'Sat',
            dayNumber: 1,
            isWeekend: true,
            isHoliday: false,
            expectedHours: 0,
            workedHours: 0,
            overtimeHours: 0,
            balanceHours: 0,
            status: 'absent',
            punches: [],
            anomalies: [],
            hasAnomalies: false
          }
        ]
      }
    });
  });
});
