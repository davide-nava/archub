# Testing Guidelines & Test Automation Standards

This document outlines the testing strategy, frameworks, conventions, and patterns used in the ArcHub backend.

---

## 1. Test Framework & Configuration

- **Framework:** **Pest PHP 5.x** with `pest-plugin-laravel`.
- **Base Test Case:** `Tests\TestCase` extending `Illuminate\Foundation\Testing\TestCase`.
- **Database Isolation:** `Illuminate\Foundation\Testing\RefreshDatabase` is enabled for Feature tests in `tests/Pest.php` to ensure clean database state for every test case.

```php
// tests/Pest.php
pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');
```

---

## 2. Test Suite Organization

```
tests/
├── Feature/
│   └── Attendance/
│       ├── ClockInTest.php                # Clock In endpoints, invariants & idempotency
│       ├── ClockOutTest.php               # Clock Out sequence validations & transitions
│       ├── SyncBatchAttendancesTest.php   # Bulk idempotent upserts & batch updates
│       └── MonthlyAttendanceReportTest.php# Work/overtime/pay calculations & anomalies
│
└── Unit/
    └── Domain/
        └── AttendanceDomainTest.php       # Value objects, Aggregate rules, Enum helpers
```

---

## 3. Writing Feature Tests

Feature tests verify end-to-end HTTP behavior, input validation, domain invariant enforcement via HTTP responses, and database side effects.

### A. Testing Domain Invariants via HTTP
```php
// tests/Feature/Attendance/ClockInTest.php
test('domain invariant rejects double clock in without clock out', function (): void {
    $user = User::factory()->create();

    // 1. First Clock In
    $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ])->assertCreated();

    // 2. Second consecutive Clock In must fail with 422
    $response = $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 10:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('error', 'DoubleClockInException');

    expect(Attendance::where('user_id', $user->id)->count())->toBe(1);
});
```

### B. Testing Idempotent Batch Synchronization
```php
// tests/Feature/Attendance/SyncBatchAttendancesTest.php
test('can bulk synchronize attendance punches with idempotent upsert', function (): void {
    $user = User::factory()->create();
    $syncId = (string) Str::uuid();

    $batchPayload = [
        'items' => [
            [
                'user_id' => $user->id,
                'type' => 'CLOCK_IN',
                'recorded_at' => '2026-03-01 08:30:00',
                'sync_id' => $syncId,
            ],
        ],
    ];

    // First POST
    $this->postJson(route('api.v1.attendances.sync'), $batchPayload)->assertOk();
    expect(Attendance::count())->toBe(1);

    // Second POST with identical sync_id (Idempotency assertion)
    $this->postJson(route('api.v1.attendances.sync'), $batchPayload)->assertOk();
    expect(Attendance::count())->toBe(1);
});
```

### C. Testing Calculations & Anomaly Detection
```php
// tests/Feature/Attendance/MonthlyAttendanceReportTest.php
test('calculates accurate monthly totals including worked hours, breaks, overtime, and estimated pay', function (): void {
    $user = User::factory()->employee(20.00)->create();

    // Setup 8-hour shift + 10-hour shift...
    $response = $this->getJson(route('api.v1.attendances.monthly-report', [
        'user_id' => $user->id,
        'year' => 2026,
        'month' => 3,
    ]));

    $response->assertOk()
        ->assertJsonPath('data.total_worked_hours', fn ($v) => (float) $v === 18.0)
        ->assertJsonPath('data.total_overtime_hours', fn ($v) => (float) $v === 2.0)
        ->assertJsonPath('data.total_estimated_pay', fn ($v) => (float) $v === 360.0);
});
```

---

## 4. Writing Unit Tests

Unit tests verify pure domain rules, Value Objects, and calculation algorithms without database or framework boot overhead.

```php
// tests/Unit/Domain/AttendanceDomainTest.php
test('coordinates value object enforces valid latitude and longitude boundaries', function (): void {
    $valid = new Coordinates(45.1234, 9.5678);
    expect($valid->latitude())->toBe(45.1234)
        ->and($valid->longitude())->toBe(9.5678);

    // Out-of-bounds latitude throws InvalidArgumentException
    expect(fn () => new Coordinates(90.1, 0.0))->toThrow(InvalidArgumentException::class);
    expect(fn () => new Coordinates(-90.1, 0.0))->toThrow(InvalidArgumentException::class);
});
```

---

## 5. Factory & Seeder Conventions

- Always use model factories (`User::factory()`, `Attendance::factory()`) for test setup.
- Utilize expressive custom states:
  ```php
  // Users
  User::factory()->admin()->create();
  User::factory()->manager()->create();
  User::factory()->employee(hourlyRate: 30.00)->create();

  // Attendances
  Attendance::factory()->clockIn()->create();
  Attendance::factory()->clockOut()->create();
  Attendance::factory()->manualOverride()->create();
  ```

---

## 6. Running Tests

```bash
# Run all tests
php artisan test --compact

# Run a specific test file
php artisan test tests/Feature/Attendance/ClockInTest.php

# Filter by test name
php artisan test --filter="domain invariant rejects double clock in"
```
