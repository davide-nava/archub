# ArcHub Enterprise Frontend Architecture

This document describes the architectural layout, directory boundaries, reactive state management patterns, and routing paradigms implemented in the **ArcHub** frontend codebase.

---

## 1. High-Level Architectural Pattern

The application follows **Clean Modular Architecture** with strict layer separation:

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                    │
│   Smart Components (Pages) & Dumb Components (Presentational)│
└──────────────────────────────┬──────────────────────────────┘
                               │ Signals & Actions
┌──────────────────────────────▼──────────────────────────────┐
│                        Feature Services                     │
│           Domain Business Logic & Reactive Data Streams     │
└──────────────────────────────┬──────────────────────────────┘
                               │ HttpClient
┌──────────────────────────────▼──────────────────────────────┐
│                           Core Layer                        │
│   Auth Interceptor (Sanctum), Route Guards, Token Storage   │
└──────────────────────────────┬──────────────────────────────┘
                               │ REST API (Bearer Token)
┌──────────────────────────────▼──────────────────────────────┐
│                    Laravel Backend API                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Layout & Module Boundaries

```
src/
├── environments/                     # Environment configuration & API endpoints
│   ├── environment.ts                # Production settings
│   └── environment.development.ts    # Development settings
│
├── app/
│   ├── core/                         # Singleton infrastructure & cross-cutting concerns
│   │   ├── guards/                   # Functional Route Guards (authGuard, guestGuard)
│   │   ├── interceptors/             # Functional HTTP Interceptors (authInterceptor)
│   │   ├── models/                   # Core contracts (ApiResponse, User, AuthResponse)
│   │   ├── services/                 # Singleton services (AuthService, TokenStorageService)
│   │   └── index.ts                  # Core barrel export
│   │
│   ├── features/                     # Domain-driven feature modules
│   │   ├── auth/                     # Authentication & Login feature
│   │   │   ├── pages/login/          # Login container page
│   │   │   └── auth.routes.ts        # Auth lazy routing
│   │   │
│   │   └── attendance/               # Attendance & Timesheet feature
│   │       ├── models/               # Feature domain models (AttendancePunch, DailyReport)
│   │       ├── services/             # Attendance API service (Laravel endpoint client)
│   │       ├── components/           # Presentational (Dumb) Components
│   │       │   ├── kpi-card/         # Summary KPI metric display widget
│   │       │   ├── punch-badge/      # Time punch indicator badge
│   │       │   └── anomaly-badge/    # Anomaly status warning pill
│   │       ├── pages/                # Smart (Container) Components
│   │       │   └── monthly-report/   # Monthly attendance report page
│   │       ├── attendance.routes.ts  # Attendance lazy routes
│   │       └── index.ts              # Attendance barrel export
│   │
│   ├── layout/                       # Application Shell & Shared UI Shell components
│   │   └── header/                   # Top navigation bar & user session indicator
│   │
│   ├── app.config.ts                 # Root ApplicationConfig with providers & interceptors
│   ├── app.routes.ts                 # Root route configuration with lazy routes
│   ├── app.ts                        # Root standalone component
│   ├── app.html                      # App layout template (<app-header /> + <router-outlet />)
│   └── app.scss                      # Global layout styling
│
└── styles.scss                       # Enterprise global styles & accessibility tokens
```

---

## 3. Layer Separation & Responsibilities

### 3.1 Core Layer (`src/app/core/`)
Contains code instantiated only once as application singletons:
- **`authInterceptor`**: Clones every outgoing `HttpRequest`, injecting the Laravel Sanctum Bearer token and headers (`Accept: application/json`, `X-Requested-With: XMLHttpRequest`). Catches `401 Unauthorized` responses to invalidate the session and redirect to `/auth/login`.
- **`authGuard`**: Protects secure application routes (`/attendance`), redirecting unauthenticated visitors to `/auth/login?returnUrl=...`.
- **`guestGuard`**: Prevents authenticated users from accessing guest pages (e.g. login).
- **`AuthService`**: Exposes reactive signals (`currentUser`, `token`, `isAuthenticated`, `userRole`) representing user state.
- **`TokenStorageService`**: Secure token persistence supporting local storage with memory fallback for SSR and headless Vitest runners.

### 3.2 Feature Layer (`src/app/features/`)
Each domain feature is self-contained:
- **Models (`models/`)**: Strongly-typed interfaces describing domain entities.
- **Services (`services/`)**: Injectable services responsible for interacting with Laravel API endpoints.
- **Smart Components (`pages/`)**: Container components that manage signals, orchestrate form input, trigger API requests, and coordinate presentation.
- **Dumb Components (`components/`)**: Pure presentational components receiving data via `input()` signals and emitting events via `output()`.

---

## 4. Reactive Data Flow & State Management

The application strictly utilizes **Angular Signals** for synchronous reactivity and **RxJS** for asynchronous event streams:

```
[ Laravel API ] 
      │ (Observable)
[ AttendanceService.getMonthlyReport() ]
      │ (Subscribe)
[ MonthlyReportComponent.reportData (Signal) ]
      │
      ├──> [ computed: summary ] ────────────> [ <app-kpi-card [value]="..." /> ]
      └──> [ computed: displayedDays ] ──────> [ @for (day of displayedDays()) ]
                                                      │
                                                      ├──> [ <app-punch-badge /> ]
                                                      └──> [ <app-anomaly-badge /> ]
```

### Signal Derivation Example:
```typescript
// Local Writable Signals
protected readonly activeFilter = signal<AttendanceFilter>({ year: 2026, month: 8, onlyAnomalies: false });
protected readonly reportData = signal<MonthlyAttendanceReport | null>(null);

// Derived Computed Signals (Pure, Auto-cached)
public readonly summary = computed(() => this.reportData()?.summary ?? null);

public readonly displayedDays = computed(() => {
  const days = this.reportData()?.days ?? [];
  return this.activeFilter().onlyAnomalies ? days.filter((d) => d.hasAnomalies) : days;
});
```

---

## 5. Routing & Navigation Strategy

### 5.1 Route Tree & Lazy Loading
All feature routes are lazily loaded on demand to minimize the initial bundle transfer size:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { authGuard } from '@core/guards/auth.guard';

export const routes: Routes = [
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.routes').then((m) => m.AUTH_ROUTES)
  },
  {
    path: 'attendance',
    canActivate: [authGuard],
    loadChildren: () => import('./features/attendance/attendance.routes').then((m) => m.ATTENDANCE_ROUTES)
  },
  {
    path: '',
    redirectTo: 'attendance',
    pathMatch: 'full'
  },
  {
    path: '**',
    redirectTo: 'attendance'
  }
];
```

### 5.2 Functional Route Guard Pattern
```typescript
// src/app/core/guards/auth.guard.ts
export const authGuard: CanActivateFn = (_route, state): boolean | UrlTree => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  return router.createUrlTree(['/auth/login'], {
    queryParams: state.url && state.url !== '/' ? { returnUrl: state.url } : undefined
  });
};
```
