# AI Agent Guidelines & Operational Rules

This document defines the operational rules, architectural standards, coding conventions, and guardrails for AI agents working in this repository.

---

## 1. Project Overview & Tech Stack

- **PHP Version:** PHP 8.5+ (Strict typing enabled on all files via `declare(strict_types=1);`).
- **Framework:** Laravel 13.x (incorporating Laravel 11/12/13 architectural standards).
- **Architecture:** Clean Architecture + Domain-Driven Design (DDD) + CQRS + SOLID.
- **Database:** SQLite with WAL mode (`PRAGMA journal_mode=WAL;`), foreign key constraints enforced, and indexed `sync_id` for idempotent bulk synchronization. Supported: PostgreSQL / MySQL.
- **Cache / Session / Queue:** Configured for `database` (production-ready for `redis` or `sync`).
- **Frontend / Presentation:** Pure headless REST API versioned under `/api/v1/` with Blade + Tailwind CSS v4 (`@tailwindcss/vite`) for root entrypoints.
- **Key Tooling:**
  - Test runner: **Pest PHP 5.x** with `pest-plugin-laravel`.
  - Code style: **Laravel Pint**.
  - Agent tools: **Laravel Boost MCP**.

---

## 2. PSR-4 Namespaces & Clean Directory Mapping

The application enforces a strict separation between domain, application use cases, infrastructure adapters, and HTTP presentation:

```json
"autoload": {
    "psr-4": {
        "App\\": "app/",
        "Domain\\": "src/Domain/",
        "Application\\": "src/Application/",
        "Infrastructure\\": "src/Infrastructure/",
        "Database\\Factories\\": "database/factories/",
        "Database\\Seeders\\": "database/seeders/"
    }
}
```

---

## 3. Laravel & PHP Conventions

### A. Strict Typing & Modern PHP 8.5+ Standards
- Always declare strict types: `declare(strict_types=1);`.
- Use constructor property promotion:
  ```php
  public function __construct(
      private readonly AttendanceRepositoryInterface $repository,
  ) {}
  ```
- Use explicit return type declarations and type hints for all parameters and methods.
- Use backed Enums for fixed domain states (e.g., `AttendanceType: string`, `UserRole: string`) with TitleCase enum keys.
- Prefer `final readonly class` for DTOs, Value Objects, and Command/Query objects.

### B. Controller Conventions (Thin Controllers)
- Controllers must remain thin and strictly orchestrate HTTP inputs and outputs.
- Never write business logic, direct ORM writes, or complex calculations inside controllers.
- Delegate write operations to CQRS **Command Handlers** and read operations to CQRS **Query Handlers**.
- Always validate incoming inputs using dedicated **Form Requests**.
- Always serialize API outputs using **Json Resources** or typed DTOs.

```php
// app/Http/Controllers/Api/V1/AttendanceController.php
public function clockIn(ClockInRequest $request, ClockInCommandHandler $handler): JsonResponse
{
    try {
        $command = $request->toCommand();
        $dto = $handler->handle($command);

        return (new AttendanceResource($dto))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    } catch (DoubleClockInException|DomainException $e) {
        return response()->json([
            'message' => $e->getMessage(),
            'error' => class_basename($e),
        ], Response::HTTP_UNPROCESSABLE_ENTITY);
    }
}
```

### C. Business Logic Layer (Domain & CQRS)
- **Domain Layer (`src/Domain/`):** Pure PHP. Zero framework or Eloquent dependencies. Contains Aggregate Roots, Entities, Value Objects, Domain Exceptions, and Repository Interfaces.
- **Application Layer (`src/Application/`):** CQRS Command/Query Handlers, DTOs, and Domain Services (e.g. `AttendanceAnomalyDetector`).
- **Infrastructure Layer (`src/Infrastructure/`):** Eloquent repository implementations, direct DB read services, external integrations.

### D. Eloquent ORM & Query Performance Guidelines
- **Mass Assignment:** Use `protected $fillable = [...]` on all Eloquent models.
- **Primary Keys:** Use UUIDs (`HasUuids`) for entity primary keys.
- **Eager Loading:** Prevent N+1 queries by eager loading relationships or writing optimized direct database queries in Read Services.
- **Bulk Idempotent Operations:** Use `upsert` on unique keys (such as `sync_id`) for batch synchronization.

---

## 4. Essential Commands & Workflows

### Setup & Package Management
```bash
# Install PHP dependencies
composer install

# Regenerate autoload files after adding classes/namespaces
composer dump-autoload

# Install Node dependencies and build assets
npm install
npm run build
```

### Database Management
```bash
# Run pending migrations
php artisan migrate

# Reset database fresh and execute seeders
php artisan migrate:fresh --seed
```

### Static Analysis, Linting & Testing
```bash
# Run Pint code formatter
vendor/bin/pint --format agent

# Run Pest test suite
php artisan test --compact
```

---

## 5. Constraints & Guardrails (DO / DO NOT)

### Database & Migrations
- **DO NOT** edit existing database migrations that have already been executed or committed to master. Always generate new migration files.
- **DO NOT** write raw unparameterized SQL queries. Use Eloquent or `DB::table(...)` with parameterized bindings.
- **DO** index foreign keys and columns frequently queried in range or filtering queries (e.g., `(user_id, recorded_at)`, unique index on `sync_id`).

### Architecture & Request Validation
- **DO NOT** bypass Form Requests to validate input inside controller actions.
- **DO NOT** import Eloquent models directly inside `src/Domain/`. Domain aggregates must remain independent of the ORM.
- **DO NOT** place domain invariants in controllers or frontend code. The `Attendance` Aggregate Root must enforce state transition rules (e.g., rejecting double `CLOCK_IN` without `CLOCK_OUT`).

### Security & Configuration
- **DO NOT** commit `.env` files or API keys. Always keep `.env.example` updated with mock default values.
- **DO** rely on dependency injection through `AppServiceProvider` or constructor injection rather than hardcoding static facades in application logic.
