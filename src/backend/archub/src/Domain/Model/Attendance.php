<?php

declare(strict_types=1);

namespace Domain\Model;

use DateTimeImmutable;
use Domain\Enums\AttendanceType;
use Domain\Exceptions\DoubleClockInException;
use Domain\Exceptions\InvalidAttendanceSequenceException;
use Domain\ValueObjects\Coordinates;
use Domain\ValueObjects\SyncId;
use Illuminate\Support\Str;

final class Attendance
{
    public function __construct(
        private readonly string $id,
        private readonly string $userId,
        private AttendanceType $type,
        private DateTimeImmutable $recordedAt,
        private ?Coordinates $coordinates = null,
        private ?string $deviceId = null,
        private ?SyncId $syncId = null,
        private bool $isManualOverride = false,
        private ?DateTimeImmutable $createdAt = null,
        private ?DateTimeImmutable $updatedAt = null,
    ) {
        $this->syncId ??= SyncId::generate();
    }

    /**
     * Factory method for recording a CLOCK_IN punch while enforcing domain invariants.
     * Rejects double CLOCK_IN without CLOCK_OUT unless manual override is explicitly provided.
     */
    public static function clockIn(
        string $userId,
        DateTimeImmutable $recordedAt,
        ?Coordinates $coordinates = null,
        ?string $deviceId = null,
        ?SyncId $syncId = null,
        bool $isManualOverride = false,
        ?AttendanceType $lastAttendanceType = null,
        ?string $id = null,
    ): self {
        if (! $isManualOverride && $lastAttendanceType !== null) {
            if ($lastAttendanceType->isClockIn()) {
                throw DoubleClockInException::alreadyClockedIn($userId);
            }
            if ($lastAttendanceType->isBreakStart()) {
                throw InvalidAttendanceSequenceException::invalidTransition(
                    $userId,
                    $lastAttendanceType->value,
                    AttendanceType::CLOCK_IN->value,
                );
            }
        }

        return new self(
            id: $id ?? (string) Str::uuid(),
            userId: $userId,
            type: AttendanceType::CLOCK_IN,
            recordedAt: $recordedAt,
            coordinates: $coordinates,
            deviceId: $deviceId,
            syncId: $syncId ?? SyncId::generate(),
            isManualOverride: $isManualOverride,
        );
    }

    /**
     * Factory method for recording a CLOCK_OUT punch while enforcing domain invariants.
     */
    public static function clockOut(
        string $userId,
        DateTimeImmutable $recordedAt,
        ?Coordinates $coordinates = null,
        ?string $deviceId = null,
        ?SyncId $syncId = null,
        bool $isManualOverride = false,
        ?AttendanceType $lastAttendanceType = null,
        ?string $id = null,
    ): self {
        if (! $isManualOverride) {
            if ($lastAttendanceType === null) {
                throw InvalidAttendanceSequenceException::noActiveClockIn($userId);
            }
            if ($lastAttendanceType->isClockOut()) {
                throw InvalidAttendanceSequenceException::alreadyClockedOut($userId);
            }
            if ($lastAttendanceType->isBreakStart()) {
                throw InvalidAttendanceSequenceException::invalidTransition(
                    $userId,
                    $lastAttendanceType->value,
                    AttendanceType::CLOCK_OUT->value,
                );
            }
        }

        return new self(
            id: $id ?? (string) Str::uuid(),
            userId: $userId,
            type: AttendanceType::CLOCK_OUT,
            recordedAt: $recordedAt,
            coordinates: $coordinates,
            deviceId: $deviceId,
            syncId: $syncId ?? SyncId::generate(),
            isManualOverride: $isManualOverride,
        );
    }

    /**
     * Generic factory method to record any attendance punch with domain sequence checks.
     */
    public static function record(
        string $userId,
        AttendanceType $type,
        DateTimeImmutable $recordedAt,
        ?Coordinates $coordinates = null,
        ?string $deviceId = null,
        ?SyncId $syncId = null,
        bool $isManualOverride = false,
        ?AttendanceType $lastAttendanceType = null,
        ?string $id = null,
    ): self {
        return match ($type) {
            AttendanceType::CLOCK_IN => self::clockIn(
                userId: $userId,
                recordedAt: $recordedAt,
                coordinates: $coordinates,
                deviceId: $deviceId,
                syncId: $syncId,
                isManualOverride: $isManualOverride,
                lastAttendanceType: $lastAttendanceType,
                id: $id,
            ),
            AttendanceType::CLOCK_OUT => self::clockOut(
                userId: $userId,
                recordedAt: $recordedAt,
                coordinates: $coordinates,
                deviceId: $deviceId,
                syncId: $syncId,
                isManualOverride: $isManualOverride,
                lastAttendanceType: $lastAttendanceType,
                id: $id,
            ),
            AttendanceType::BREAK_START => self::breakStart(
                userId: $userId,
                recordedAt: $recordedAt,
                coordinates: $coordinates,
                deviceId: $deviceId,
                syncId: $syncId,
                isManualOverride: $isManualOverride,
                lastAttendanceType: $lastAttendanceType,
                id: $id,
            ),
            AttendanceType::BREAK_END => self::breakEnd(
                userId: $userId,
                recordedAt: $recordedAt,
                coordinates: $coordinates,
                deviceId: $deviceId,
                syncId: $syncId,
                isManualOverride: $isManualOverride,
                lastAttendanceType: $lastAttendanceType,
                id: $id,
            ),
        };
    }

    public static function breakStart(
        string $userId,
        DateTimeImmutable $recordedAt,
        ?Coordinates $coordinates = null,
        ?string $deviceId = null,
        ?SyncId $syncId = null,
        bool $isManualOverride = false,
        ?AttendanceType $lastAttendanceType = null,
        ?string $id = null,
    ): self {
        if (! $isManualOverride) {
            if ($lastAttendanceType === null || $lastAttendanceType->isClockOut()) {
                throw InvalidAttendanceSequenceException::invalidTransition(
                    $userId,
                    $lastAttendanceType?->value ?? 'NONE',
                    AttendanceType::BREAK_START->value,
                );
            }
            if ($lastAttendanceType->isBreakStart()) {
                throw InvalidAttendanceSequenceException::invalidTransition(
                    $userId,
                    $lastAttendanceType->value,
                    AttendanceType::BREAK_START->value,
                );
            }
        }

        return new self(
            id: $id ?? (string) Str::uuid(),
            userId: $userId,
            type: AttendanceType::BREAK_START,
            recordedAt: $recordedAt,
            coordinates: $coordinates,
            deviceId: $deviceId,
            syncId: $syncId ?? SyncId::generate(),
            isManualOverride: $isManualOverride,
        );
    }

    public static function breakEnd(
        string $userId,
        DateTimeImmutable $recordedAt,
        ?Coordinates $coordinates = null,
        ?string $deviceId = null,
        ?SyncId $syncId = null,
        bool $isManualOverride = false,
        ?AttendanceType $lastAttendanceType = null,
        ?string $id = null,
    ): self {
        if (! $isManualOverride) {
            if ($lastAttendanceType === null || ! $lastAttendanceType->isBreakStart()) {
                throw InvalidAttendanceSequenceException::invalidTransition(
                    $userId,
                    $lastAttendanceType?->value ?? 'NONE',
                    AttendanceType::BREAK_END->value,
                );
            }
        }

        return new self(
            id: $id ?? (string) Str::uuid(),
            userId: $userId,
            type: AttendanceType::BREAK_END,
            recordedAt: $recordedAt,
            coordinates: $coordinates,
            deviceId: $deviceId,
            syncId: $syncId ?? SyncId::generate(),
            isManualOverride: $isManualOverride,
        );
    }

    /**
     * Reconstitutes an Attendance entity from persistence.
     */
    public static function reconstitute(
        string $id,
        string $userId,
        AttendanceType $type,
        DateTimeImmutable $recordedAt,
        ?Coordinates $coordinates = null,
        ?string $deviceId = null,
        ?SyncId $syncId = null,
        bool $isManualOverride = false,
        ?DateTimeImmutable $createdAt = null,
        ?DateTimeImmutable $updatedAt = null,
    ): self {
        return new self(
            id: $id,
            userId: $userId,
            type: $type,
            recordedAt: $recordedAt,
            coordinates: $coordinates,
            deviceId: $deviceId,
            syncId: $syncId ?? SyncId::generate(),
            isManualOverride: $isManualOverride,
            createdAt: $createdAt,
            updatedAt: $updatedAt,
        );
    }

    public function id(): string
    {
        return $this->id;
    }

    public function userId(): string
    {
        return $this->userId;
    }

    public function type(): AttendanceType
    {
        return $this->type;
    }

    public function recordedAt(): DateTimeImmutable
    {
        return $this->recordedAt;
    }

    public function coordinates(): ?Coordinates
    {
        return $this->coordinates;
    }

    public function deviceId(): ?string
    {
        return $this->deviceId;
    }

    public function syncId(): SyncId
    {
        /** @var SyncId */
        return $this->syncId;
    }

    public function isManualOverride(): bool
    {
        return $this->isManualOverride;
    }

    public function createdAt(): ?DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function updatedAt(): ?DateTimeImmutable
    {
        return $this->updatedAt;
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->userId,
            'type' => $this->type->value,
            'recorded_at' => $this->recordedAt->format('Y-m-d H:i:s'),
            'latitude' => $this->coordinates?->latitude(),
            'longitude' => $this->coordinates?->longitude(),
            'device_id' => $this->deviceId,
            'sync_id' => $this->syncId()?->value(),
            'is_manual_override' => $this->isManualOverride,
            'created_at' => $this->createdAt?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updatedAt?->format('Y-m-d H:i:s'),
        ];
    }
}
