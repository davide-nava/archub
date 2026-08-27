<?php

declare(strict_types=1);

namespace Application\DTOs;

use Domain\Model\Attendance;

final readonly class AttendanceDto
{
    public function __construct(
        public string $id,
        public string $userId,
        public string $type,
        public string $recordedAt,
        public ?float $latitude,
        public ?float $longitude,
        public ?string $deviceId,
        public string $syncId,
        public bool $isManualOverride,
        public ?string $createdAt = null,
        public ?string $updatedAt = null,
    ) {}

    public static function fromDomain(Attendance $attendance): self
    {
        return new self(
            id: $attendance->id(),
            userId: $attendance->userId(),
            type: $attendance->type()->value,
            recordedAt: $attendance->recordedAt()->format('Y-m-d H:i:s'),
            latitude: $attendance->coordinates()?->latitude(),
            longitude: $attendance->coordinates()?->longitude(),
            deviceId: $attendance->deviceId(),
            syncId: $attendance->syncId()->value(),
            isManualOverride: $attendance->isManualOverride(),
            createdAt: $attendance->createdAt()?->format('Y-m-d H:i:s'),
            updatedAt: $attendance->updatedAt()?->format('Y-m-d H:i:s'),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->userId,
            'type' => $this->type,
            'recorded_at' => $this->recordedAt,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'device_id' => $this->deviceId,
            'sync_id' => $this->syncId,
            'is_manual_override' => $this->isManualOverride,
            'created_at' => $this->createdAt,
            'updated_at' => $this->updatedAt,
        ];
    }
}
