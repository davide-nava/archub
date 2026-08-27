<?php

declare(strict_types=1);

use App\Models\Attendance;
use App\Models\User;
use Domain\Enums\AttendanceType;
use Illuminate\Support\Str;

test('employee can successfully clock out after clocking in', function (): void {
    $user = User::factory()->create();

    // 1. Clock In
    $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ])->assertCreated();

    // 2. Clock Out
    $response = $this->postJson(route('api.v1.attendances.clock-out'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 17:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response->assertOk()
        ->assertJsonPath('data.user_id', $user->id)
        ->assertJsonPath('data.type', AttendanceType::CLOCK_OUT->value)
        ->assertJsonPath('data.recorded_at', '2026-03-01 17:00:00');

    expect(Attendance::where('user_id', $user->id)->count())->toBe(2);
});

test('domain invariant rejects clock out without active clock in', function (): void {
    $user = User::factory()->create();

    $response = $this->postJson(route('api.v1.attendances.clock-out'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 17:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('error', 'InvalidAttendanceSequenceException');

    expect(Attendance::where('user_id', $user->id)->count())->toBe(0);
});

test('domain invariant rejects double clock out', function (): void {
    $user = User::factory()->create();

    // 1. Clock In
    $this->postJson(route('api.v1.attendances.clock-in'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 09:00:00',
        'sync_id' => (string) Str::uuid(),
    ])->assertCreated();

    // 2. Clock Out
    $this->postJson(route('api.v1.attendances.clock-out'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 17:00:00',
        'sync_id' => (string) Str::uuid(),
    ])->assertOk();

    // 3. Second Clock Out must be rejected
    $response = $this->postJson(route('api.v1.attendances.clock-out'), [
        'user_id' => $user->id,
        'recorded_at' => '2026-03-01 18:00:00',
        'sync_id' => (string) Str::uuid(),
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('error', 'InvalidAttendanceSequenceException');

    expect(Attendance::where('user_id', $user->id)->count())->toBe(2);
});
