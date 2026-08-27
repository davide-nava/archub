<?php

declare(strict_types=1);

use Domain\Enums\AttendanceType;
use Domain\Enums\UserRole;
use Domain\Exceptions\DoubleClockInException;
use Domain\Exceptions\InvalidAttendanceSequenceException;
use Domain\Model\Attendance;
use Domain\ValueObjects\Coordinates;
use Domain\ValueObjects\SyncId;
use Illuminate\Support\Str;

test('coordinates value object enforces valid latitude and longitude boundaries', function (): void {
    $valid = new Coordinates(45.1234, 9.5678);
    expect($valid->latitude())->toBe(45.1234)
        ->and($valid->longitude())->toBe(9.5678)
        ->and($valid->toArray())->toBe(['latitude' => 45.1234, 'longitude' => 9.5678]);

    // Invalid Latitude > 90
    expect(fn () => new Coordinates(90.1, 0.0))->toThrow(InvalidArgumentException::class);

    // Invalid Latitude < -90
    expect(fn () => new Coordinates(-90.1, 0.0))->toThrow(InvalidArgumentException::class);

    // Invalid Longitude > 180
    expect(fn () => new Coordinates(0.0, 180.1))->toThrow(InvalidArgumentException::class);

    // Invalid Longitude < -180
    expect(fn () => new Coordinates(0.0, -180.1))->toThrow(InvalidArgumentException::class);
});

test('sync id value object rejects empty string and generates valid UUIDs', function (): void {
    $generated = SyncId::generate();
    expect(Str::isUuid($generated->value()))->toBeTrue();

    $fromString = SyncId::fromString('custom-sync-id-123');
    expect($fromString->value())->toBe('custom-sync-id-123')
        ->and((string) $fromString)->toBe('custom-sync-id-123');

    expect(fn () => SyncId::fromString('   '))->toThrow(InvalidArgumentException::class);
});

test('attendance aggregate root enforces double clock in rejection invariant', function (): void {
    $userId = (string) Str::uuid();
    $recordedAt = new DateTimeImmutable('2026-03-01 09:00:00');

    // Attempting CLOCK_IN when previous punch was CLOCK_IN
    expect(fn () => Attendance::clockIn(
        userId: $userId,
        recordedAt: $recordedAt,
        lastAttendanceType: AttendanceType::CLOCK_IN,
    ))->toThrow(DoubleClockInException::class);
});

test('attendance aggregate root enforces clock out sequence invariants', function (): void {
    $userId = (string) Str::uuid();
    $recordedAt = new DateTimeImmutable('2026-03-01 17:00:00');

    // Clock out with no active punch
    expect(fn () => Attendance::clockOut(
        userId: $userId,
        recordedAt: $recordedAt,
        lastAttendanceType: null,
    ))->toThrow(InvalidAttendanceSequenceException::class);

    // Clock out when already clocked out
    expect(fn () => Attendance::clockOut(
        userId: $userId,
        recordedAt: $recordedAt,
        lastAttendanceType: AttendanceType::CLOCK_OUT,
    ))->toThrow(InvalidAttendanceSequenceException::class);
});

test('user role enum helper methods', function (): void {
    expect(UserRole::ADMIN->isAdmin())->toBeTrue()
        ->and(UserRole::ADMIN->isManager())->toBeFalse()
        ->and(UserRole::MANAGER->isManager())->toBeTrue()
        ->and(UserRole::EMPLOYEE->isEmployee())->toBeTrue();
});
