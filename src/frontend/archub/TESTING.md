# ArcHub Frontend Testing Guidelines

This document outlines the testing strategy, toolchain configuration, patterns, and conventions for unit and integration testing across the **ArcHub** Angular frontend.

---

## 1. Testing Toolchain & Runner

- **Runner / Framework:** Vitest integrated via `@angular/build:unit-test`.
- **DOM Simulation:** JSDOM.
- **Mocking & Test Utilities:** Angular Testing Package (`TestBed`), `provideHttpClientTesting()`, `HttpTestingController`.

### Running Tests:
```bash
# Execute full test suite once (CI / Verification)
npx ng test --watch=false

# Run tests in watch mode during development
npm test
```

---

## 2. Test Structure & Naming Conventions (AAA Pattern)

All tests must follow the **Arrange-Act-Assert (AAA)** pattern and descriptive `it('should ... when ...')` or `it('should ...')` titles:

```typescript
it('should inject Authorization Bearer header when token exists', () => {
  // 1. Arrange
  authService.setSession({
    token: 'valid_token_123',
    tokenType: 'Bearer',
    user: { id: 1, name: 'Alex', email: 'alex@archub.internal', role: 'admin' }
  });

  // 2. Act
  httpClient.get('/api/v1/test-resource').subscribe();

  // 3. Assert
  const req = httpTestingController.expectOne('/api/v1/test-resource');
  expect(req.request.headers.get('Authorization')).toBe('Bearer valid_token_123');
  req.flush({});
});
```

---

## 3. Standard Testing Patterns & Code Examples

### 3.1 Testing Standalone Components with Signals & OnPush

When testing Standalone components with `OnPush` change detection and HTTP dependencies:
1. Provide `provideHttpClientTesting()`.
2. Flush expected mock API payloads through `HttpTestingController`.
3. Call `fixture.detectChanges()` to evaluate template bindings and signal updates.

```typescript
// src/app/features/attendance/pages/monthly-report/monthly-report.component.spec.ts
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
          }
        ]
      }
    });

    fixture.detectChanges();

    expect(component).toBeTruthy();
    expect(component.summary()?.totalWorkedHours).toBe(168.5);
    expect(component.displayedDays().length).toBe(1);
  });
});
```

---

### 3.2 Testing API Services with `HttpTestingController`

Verify HTTP method, request parameters, URL paths, and mapped response models:

```typescript
// src/app/features/attendance/services/attendance.service.spec.ts
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

  it('should fetch monthly attendance report with query parameters', () => {
    const filter = { year: 2026, month: 8, onlyAnomalies: false };

    service.getMonthlyReport(filter).subscribe((report) => {
      expect(report).toBeDefined();
      expect(report.year).toBe(2026);
      expect(report.summary.totalWorkingDays).toBe(1);
    });

    const req = httpTestingController.expectOne((r) =>
      r.url.includes('/attendance/monthly-report') &&
      r.params.get('year') === '2026' &&
      r.params.get('month') === '8'
    );

    expect(req.request.method).toBe('GET');
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
        days: []
      }
    });
  });
});
```

---

### 3.3 Testing Functional Route Guards (`CanActivateFn`)

Execute functional guards inside `TestBed.runInInjectionContext()`:

```typescript
// src/app/core/guards/auth.guard.spec.ts
import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot, UrlTree, provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { authGuard, guestGuard } from './auth.guard';
import { AuthService } from '../services/auth.service';

describe('Route Guards', () => {
  let authService: AuthService;
  let router: Router;

  const mockRouteSnapshot = {} as ActivatedRouteSnapshot;
  const mockStateSnapshot = { url: '/attendance' } as RouterStateSnapshot;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([]),
        provideHttpClient(),
        provideHttpClientTesting()
      ]
    });

    authService = TestBed.inject(AuthService);
    router = TestBed.inject(Router);
  });

  describe('authGuard', () => {
    it('should allow access when user is authenticated', () => {
      authService.setSession({
        token: 'active_token',
        tokenType: 'Bearer',
        user: { id: 1, name: 'User', email: 'u@archub.internal', role: 'admin' }
      });

      const result = TestBed.runInInjectionContext(() =>
        authGuard(mockRouteSnapshot, mockStateSnapshot)
      );

      expect(result).toBe(true);
    });

    it('should return UrlTree redirecting to /auth/login when user is unauthenticated', () => {
      authService.clearSession();

      const result = TestBed.runInInjectionContext(() =>
        authGuard(mockRouteSnapshot, mockStateSnapshot)
      );

      expect(result instanceof UrlTree).toBe(true);
      if (result instanceof UrlTree) {
        expect(router.serializeUrl(result)).toContain('/auth/login');
      }
    });
  });
});
```

---

### 3.4 Testing Functional HTTP Interceptors (`HttpInterceptorFn`)

Configure `withInterceptors([authInterceptor])` in `provideHttpClient`:

```typescript
// src/app/core/interceptors/auth.interceptor.spec.ts
import { TestBed } from '@angular/core/testing';
import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { authInterceptor } from './auth.interceptor';
import { AuthService } from '../services/auth.service';

describe('authInterceptor', () => {
  let httpClient: HttpClient;
  let httpTestingController: HttpTestingController;
  let authService: AuthService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([{ path: 'auth/login', component: class {} }]),
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting()
      ]
    });

    httpClient = TestBed.inject(HttpClient);
    httpTestingController = TestBed.inject(HttpTestingController);
    authService = TestBed.inject(AuthService);
  });

  afterEach(() => {
    httpTestingController.verify();
  });

  it('should trigger handleUnauthorized when 401 response is returned', () => {
    const unauthorizedSpy = vi.spyOn(authService, 'handleUnauthorized');

    httpClient.get('/api/v1/secure-data').subscribe({
      error: () => {}
    });

    const req = httpTestingController.expectOne('/api/v1/secure-data');
    req.flush({ message: 'Unauthenticated.' }, { status: 401, statusText: 'Unauthorized' });

    expect(unauthorizedSpy).toHaveBeenCalled();
  });
});
```

---

## 4. Quality Checklist Before Commits

- [ ] All unit tests pass (`npx ng test --watch=false`).
- [ ] Production build succeeds without budget warnings (`npm run build`).
- [ ] No `any` types or implicit any parameter errors.
- [ ] Every `@for` loop has a unique `track` expression.
- [ ] All components declare `changeDetection: ChangeDetectionStrategy.OnPush`.
- [ ] All `HttpTestingController` instances are verified with `.verify()`.
