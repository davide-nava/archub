# Architecture Guide & System Design

This document details the architectural layout, design patterns, and request lifecycle for the ArcHub Attendance & Workforce Management backend.

---

## 1. Architectural Style: Clean Architecture + DDD + CQRS

The application is structured into four primary layers following Hexagonal/Clean Architecture and Domain-Driven Design:

```
                  ┌──────────────────────────────────────────────┐
                  │              HTTP / API Layer                │
                  │  (Routes, Controllers, FormRequests, JSON)   │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │              Application Layer               │
                  │   (Commands, Handlers, Queries, DTOs, Svc)   │
                  └──────────────┬───────────────────────────────┘
                                 │               │
                     (Write Model)               (Read Model)
                                 │               │
                                 ▼               ▼
        ┌──────────────────────────────────┐   ┌──────────────────────────────────┐
        │           Domain Layer           │   │       Infrastructure Layer       │
        │ (Aggregates, VOs, Enums, Invars) │   │ (SqliteReadService, Direct DB)   │
        └────────────────┬─────────────────┘   └──────────────────────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────┐
        │       Infrastructure Layer       │
        │ (EloquentRepository, Migrations) │
        └──────────────────────────────────┘
```

---

## 2. Directory Layout & Layer Responsibilities

```
archub/
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/V1/        # Thin REST API Controllers
│   │   ├── Requests/Api/V1/           # FormRequests with strict validation & command mapping
│   │   └── Resources/Api/V1/          # JsonResources formatting output contracts
│   ├── Models/                        # Eloquent ORM Models (User, Attendance)
│   └── Providers/                     # Dependency Injection bindings (AppServiceProvider)
│
├── src/
│   ├── Domain/                        # Pure Domain Layer (Zero Framework Dependencies)
│   │   ├── Enums/                     # AttendanceType, UserRole
│   │   ├── Exceptions/                # DoubleClockInException, DomainException
│   │   ├── Model/                     # Attendance Aggregate Root (protects invariants)
│   │   ├── Repositories/              # AttendanceRepositoryInterface
│   │   └── ValueObjects/              # Coordinates, SyncId
│   │
│   ├── Application/                   # Application Use Cases & CQRS
│   │   ├── Commands/                  # Write operations (ClockIn, ClockOut, SyncBatch)
│   │   ├── Queries/                   # Read operations (GetMonthlyAttendanceReport)
│   │   ├── DTOs/                      # Immutable read/write data transfer objects
│   │   └── Services/                  # AttendanceAnomalyDetector
│   │
│   └── Infrastructure/                # Adapters & Framework Bridges
│       ├── Persistence/               # EloquentAttendanceRepository (implements domain repo)
│       └── ReadServices/              # SqliteAttendanceReportReadService (direct DB read model)
│
├── database/
│   ├── factories/                     # Model factories for testing & seeding
│   ├── migrations/                    # Database schema definitions
│   └── seeders/                       # DatabaseSeeder (Admins, Managers, Employees, Logs)
│
├── routes/
│   ├── api.php                        # Versioned API routes (/api/v1/attendances/...)
│   ├── console.php                    # Scheduled artisan tasks and console commands
│   └── web.php                        # Root web entry points
│
└── tests/
    ├── Feature/Attendance/            # Feature tests for ClockIn, ClockOut, Sync, Reports
    └── Unit/Domain/                   # Unit tests for Value Objects, Invariants, Enums
```

---

## 3. Data & Request Lifecycle

### A. Command Lifecycle (Write Path)
1. **HTTP Request:** Client sends `POST /api/v1/attendances/clock-in`.
2. **Validation:** `ClockInRequest` validates parameters (e.g. UUID, coordinate bounds) and converts input to `ClockInCommand`.
3. **Command Handling:** `ClockInCommandHandler` receives the command, checks `SyncId` idempotency, and loads prior punch state via `AttendanceRepositoryInterface`.
4. **Domain Invariant Enforcement:** `Attendance::clockIn(...)` validates sequence rules (e.g., rejects double `CLOCK_IN` without `CLOCK_OUT`).
5. **Persistence:** `EloquentAttendanceRepository` persists the aggregate root.
6. **Response:** DTO is transformed into `AttendanceResource` returning HTTP 201 Created.

```
Client ──► ClockInRequest ──► ClockInCommand ──► ClockInCommandHandler
                                                        │
                   ┌────────────────────────────────────┴─────────────────────────┐
                   ▼                                                              ▼
        Attendance Aggregate                              AttendanceRepositoryInterface
  (Enforces Domain Invariants)                                    (save / upsert)
                   │                                                              │
                   └───────────────────► AttendanceDto ◄──────────────────────────┘
                                               │
                                               ▼
                                      AttendanceResource ──► HTTP 201 JSON
```

### B. Query Lifecycle (Read Path)
1. **HTTP Request:** Client sends `GET /api/v1/attendances/monthly-report?user_id=...&year=2026&month=3`.
2. **Validation:** `GetMonthlyAttendanceReportRequest` validates query params and instantiates `GetMonthlyAttendanceReportQuery`.
3. **Query Handling:** `GetMonthlyAttendanceReportQueryHandler` invokes `AttendanceReportReadServiceInterface`.
4. **Optimized Read Service:** `SqliteAttendanceReportReadService` executes indexed queries against SQLite directly without ORM hydration overhead.
5. **Anomaly Analysis:** `AttendanceAnomalyDetector` processes daily punch sequences, detecting missing punches, excessive shifts, and breaks.
6. **Response:** Returns `MonthlyAttendanceReportDto` serialized through `MonthlyAttendanceReportResource` (HTTP 200 OK).

---

## 4. CQRS Implementation

| Concern | Write Side (Commands) | Read Side (Queries) |
| :--- | :--- | :--- |
| **Focus** | Business rules, invariants, state transitions | Fast queries, aggregation, anomaly analysis |
| **Model** | `Domain\Model\Attendance` Aggregate Root | `Application\DTOs\*` read-only DTOs |
| **Data Access** | `Domain\Repositories\AttendanceRepositoryInterface` | `Application\Queries\*\AttendanceReportReadServiceInterface` |
| **Implementation** | `Infrastructure\Persistence\EloquentAttendanceRepository` | `Infrastructure\ReadServices\SqliteAttendanceReportReadService` |
| **Idempotency** | Enforced via `sync_id` unique constraint & repository checks | Read-only idempotent queries |

---

## 5. Async & Background Processing

- **Queues & Jobs:** Queue driver configured in `config/queue.php` (default `database`).
- **Events & Listeners:** Domain events dispatched upon punch creation or anomaly discovery can be handled by background listeners.
- **Scheduled Tasks:** Registered in `routes/console.php` using the schedule builder:
  ```php
  // routes/console.php
  use Illuminate\Support\Facades\Schedule;

  Schedule::command('queue:work --stop-when-empty')->everyMinute();
  ```
