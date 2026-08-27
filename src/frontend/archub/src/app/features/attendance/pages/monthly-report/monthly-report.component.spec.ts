import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { MonthlyReportComponent } from './monthly-report.component';
import { AttendanceService } from '../../services/attendance.service';

describe('MonthlyReportComponent', () => {
  let httpTestingController: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MonthlyReportComponent],
      providers: [
        AttendanceService,
        provideRouter([]),
        provideHttpClient(),
        provideHttpClientTesting()
      ]
    }).compileComponents();

    httpTestingController = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpTestingController.verify();
  });

  it('should initialize with default filter signals and load report', () => {
    const fixture = TestBed.createComponent(MonthlyReportComponent);
    const component = fixture.componentInstance;
    fixture.detectChanges();

    const req = httpTestingController.expectOne((r) =>
      r.url.includes('/attendance/monthly-report')
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
          totalWorkedHours: 168.5,
          totalExpectedHours: 160.0,
          totalOvertimeHours: 8.5,
          totalBalanceHours: 8.5,
          totalWorkingDays: 20,
          presentDays: 20,
          absentDays: 0,
          leaveDays: 0,
          anomaliesCount: 1
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
          },
          {
            date: '2026-08-04',
            dayOfWeek: 'Tue',
            dayNumber: 4,
            isWeekend: false,
            isHoliday: false,
            expectedHours: 8.0,
            workedHours: 4.0,
            overtimeHours: 0,
            balanceHours: -4.0,
            status: 'incomplete',
            punches: [{ id: 'p1', time: '09:00', type: 'in' }],
            anomalies: [{ code: 'MISSING_CLOCK_OUT', message: 'Missing clock out', severity: 'critical' }],
            hasAnomalies: true
          }
        ]
      }
    });

    fixture.detectChanges();

    expect(component).toBeTruthy();
    expect(component.summary()?.totalWorkedHours).toBe(168.5);
    expect(component.displayedDays().length).toBe(2);
  });
});
