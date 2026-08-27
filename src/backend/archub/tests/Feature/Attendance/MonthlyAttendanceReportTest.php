<?php

declare(strict_types=1);

use App\Models\Attendance;
use App\Models\User;
use Domain\Enums\AttendanceType;
use Illuminate\Support\Str;

test('calculates accurate monthly totals including worked hours, breaks, overtime, and estimated pay', function (): void {
    // Hourly rate of $20.00
    $user = User::factory()->employee(20.00)->create();

    // Day 1: Regular 8-hour shift (09:00 - 18:00 with 1 hour lunch break: 12:00 - 13:00) -> 8.0 worked hours, 0 overtime
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_IN,
        'recorded_at' => '2026-03-02 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::BREAK_START,
        'recorded_at' => '2026-03-02 12:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::BREAK_END,
        'recorded_at' => '2026-03-02 13:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_OUT,
        'recorded_at' => '2026-03-02 18:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    // Day 2: Overtime shift: 08:00 - 19:00 (1 hour lunch 12:00 - 13:00) -> 10.0 worked hours (2.0 overtime)
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_IN,
        'recorded_at' => '2026-03-03 08:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::BREAK_START,
        'recorded_at' => '2026-03-03 12:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::BREAK_END,
        'recorded_at' => '2026-03-03 13:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_OUT,
        'recorded_at' => '2026-03-03 19:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response = $this->getJson(route('api.v1.attendances.monthly-report', [
        'user_id' => $user->id,
        'year' => 2026,
        'month' => 3,
    ]));

    $response->assertOk()
        ->assertJsonPath('data.user_id', $user->id)
        ->assertJsonPath('data.hourly_rate', fn ($val) => (float) $val === 20.0)
        ->assertJsonPath('data.total_worked_hours', fn ($val) => (float) $val === 18.0)
        ->assertJsonPath('data.total_overtime_hours', fn ($val) => (float) $val === 2.0)
        ->assertJsonPath('data.total_break_hours', fn ($val) => (float) $val === 2.0)
        ->assertJsonPath('data.total_estimated_pay', fn ($val) => (float) $val === 360.0)
        ->assertJsonPath('data.anomaly_count', 0);
});

test('anomaly detection algorithm flags missing clock out, excessive shifts, and manual overrides', function (): void {
    $user = User::factory()->employee(25.00)->create();

    // Day 1: Missing Clock Out (has CLOCK_IN at 09:00, no CLOCK_OUT)
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_IN,
        'recorded_at' => '2026-03-04 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    // Day 2: Shift with Manual Override
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_IN,
        'recorded_at' => '2026-03-05 09:00:00',
        'sync_id' => (string) Str::uuid(),
        'is_manual_override' => true,
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_OUT,
        'recorded_at' => '2026-03-05 17:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    // Day 3: Excessive shift > 12 hours (06:00 to 22:00 = 16 hours)
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_IN,
        'recorded_at' => '2026-03-06 06:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);
    Attendance::create([
        'id' => (string) Str::uuid(),
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_OUT,
        'recorded_at' => '2026-03-06 22:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response = $this->getJson(route('api.v1.attendances.monthly-report', [
        'user_id' => $user->id,
        'year' => 2026,
        'month' => 3,
    ]));

    $response->assertOk();
    $data = $response->json('data');

    expect($data['anomaly_count'])->toBeGreaterThanOrEqual(3);

    // Verify Day 1 anomaly
    $day1 = collect($data['daily_reports'])->firstWhere('date', '2026-03-04');
    expect($day1['has_anomaly'])->toBeTrue()
        ->and($day1['anomalies'])->toContain('Missing CLOCK_OUT for shift started at 2026-03-04 09:00:00.');

    // Verify Day 2 anomaly (manual override)
    $day2 = collect($data['daily_reports'])->firstWhere('date', '2026-03-05');
    expect($day2['has_anomaly'])->toBeTrue()
        ->and($day2['anomalies'][0])->toContain('manual override');

    // Verify Day 3 anomaly (excessive duration)
    $day3 = collect($data['daily_reports'])->firstWhere('date', '2026-03-06');
    expect($day3['has_anomaly'])->toBeTrue()
        ->and((float) $day3['worked_hours'])->toEqual(16.0)
        ->and(collect($day3['anomalies'])->first(fn ($msg) => str_contains((string) $msg, 'Excessive shift duration')))->not->toBeNull();
});
