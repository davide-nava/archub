<?php

declare(strict_types=1);

use App\Models\Attendance;
use App\Models\User;
use Domain\Enums\AttendanceType;
use Illuminate\Support\Str;

test('can bulk synchronize attendance punches with idempotent upsert', function (): void {
    $user1 = User::factory()->create();
    $user2 = User::factory()->create();

    $syncId1 = (string) Str::uuid();
    $syncId2 = (string) Str::uuid();
    $syncId3 = (string) Str::uuid();
    $syncId4 = (string) Str::uuid();

    $batchPayload = [
        'items' => [
            [
                'user_id' => $user1->id,
                'type' => AttendanceType::CLOCK_IN->value,
                'recorded_at' => '2026-03-01 08:30:00',
                'latitude' => 45.4642,
                'longitude' => 9.1900,
                'device_id' => 'DEV_001',
                'sync_id' => $syncId1,
            ],
            [
                'user_id' => $user1->id,
                'type' => AttendanceType::CLOCK_OUT->value,
                'recorded_at' => '2026-03-01 17:30:00',
                'latitude' => 45.4642,
                'longitude' => 9.1900,
                'device_id' => 'DEV_001',
                'sync_id' => $syncId2,
            ],
            [
                'user_id' => $user2->id,
                'type' => AttendanceType::CLOCK_IN->value,
                'recorded_at' => '2026-03-01 09:00:00',
                'latitude' => 45.4645,
                'longitude' => 9.1905,
                'device_id' => 'DEV_002',
                'sync_id' => $syncId3,
            ],
            [
                'user_id' => $user2->id,
                'type' => AttendanceType::CLOCK_OUT->value,
                'recorded_at' => '2026-03-01 18:00:00',
                'latitude' => 45.4645,
                'longitude' => 9.1905,
                'device_id' => 'DEV_002',
                'sync_id' => $syncId4,
            ],
        ],
    ];

    // First batch sync
    $response1 = $this->postJson(route('api.v1.attendances.sync'), $batchPayload);

    $response1->assertOk()
        ->assertJsonPath('data.synced_count', 4);

    expect(Attendance::count())->toBe(4);

    // Second batch sync with EXACT SAME payload (Idempotency test)
    $response2 = $this->postJson(route('api.v1.attendances.sync'), $batchPayload);

    $response2->assertOk()
        ->assertJsonPath('data.synced_count', 4);

    // Total count must still be exactly 4, not 8!
    expect(Attendance::count())->toBe(4);
});

test('batch sync updates existing records without duplicate insertions', function (): void {
    $user = User::factory()->create();
    $syncId = (string) Str::uuid();

    // Initial punch
    $this->postJson(route('api.v1.attendances.sync'), [
        'items' => [
            [
                'user_id' => $user->id,
                'type' => AttendanceType::CLOCK_IN->value,
                'recorded_at' => '2026-03-01 08:30:00',
                'device_id' => 'DEV_OLD',
                'sync_id' => $syncId,
                'is_manual_override' => false,
            ],
        ],
    ])->assertOk();

    expect(Attendance::where('sync_id', $syncId)->first()->device_id)->toBe('DEV_OLD');

    // Updated punch with same sync_id but corrected device_id and manual override
    $this->postJson(route('api.v1.attendances.sync'), [
        'items' => [
            [
                'user_id' => $user->id,
                'type' => AttendanceType::CLOCK_IN->value,
                'recorded_at' => '2026-03-01 08:30:00',
                'device_id' => 'DEV_NEW',
                'sync_id' => $syncId,
                'is_manual_override' => true,
            ],
        ],
    ])->assertOk();

    expect(Attendance::where('user_id', $user->id)->count())->toBe(1);
    $updated = Attendance::where('sync_id', $syncId)->first();
    expect($updated->device_id)->toBe('DEV_NEW')
        ->and($updated->is_manual_override)->toBeTrue();
});
