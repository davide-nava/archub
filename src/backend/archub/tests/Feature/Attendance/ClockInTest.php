<?php

declare(strict_types=1);

use App\Models\Attendance;
use App\Models\User;
use Domain\Enums\AttendanceType;
use Illuminate\Support\Str;

test('employee can successfully clock in', function (): void {
    $user = User::factory()->create();

    $response = $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'latitude' => 45.4642,
        'longitude' => 9.1900,
        'device_id' => 'DEV_TEST_001',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response->assertCreated()
        ->assertJsonPath('data.user_id', $user->id)
        ->assertJsonPath('data.type', AttendanceType::CLOCK_IN->value)
        ->assertJsonPath('data.recorded_at', '2026-03-01 09:00:00');

    $this->assertDatabaseHas('attendances', [
        'user_id' => $user->id,
        'type' => AttendanceType::CLOCK_IN->value,
    ]);
});

test('domain invariant rejects double clock in without clock out', function (): void {
    $user = User::factory()->create();

    // First Clock In
    $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ])->assertCreated();

    // Second consecutive Clock In without Clock Out must be rejected
    $response = $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 10:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('error', 'DoubleClockInException');

    expect(Attendance::where('user_id', $user->id)->count())->toBe(1);
});

test('manual override allows clock in even if already clocked in', function (): void {
    $user = User::factory()->create();

    // First Clock In
    $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ])->assertCreated();

    // Second Clock In with manual override
    $response = $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 10:00:00',
        'sync_id' => (string) Str::uuid(),
        'is_manual_override' => true,
    ]);

    $response->assertCreated()
        ->assertJsonPath('data.is_manual_override', true);

    expect(Attendance::where('user_id', $user->id)->count())->toBe(2);
});

test('submitting identical sync_id returns idempotent response without creating duplicate', function (): void {
    $user = User::factory()->create();
    $syncId = (string) Str::uuid();

    $payload = [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'sync_id' => $syncId,
    ];

    $response1 = $this->postJson(route('api.v1.attendances.clock-in'), $payload);
    $response1->assertCreated();

    $response2 = $this->postJson(route('api.v1.attendances.clock-in'), $payload);
    $response2->assertCreated();

    expect(Attendance::where('user_id', $user->id)->count())->toBe(1);
});

test('validates coordinate boundaries', function (): void {
    $user = User::factory()->create();

    $response = $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'latitude' => 95.0, // Invalid: > 90
        'longitude' => 10.0,
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['latitude']);
});
