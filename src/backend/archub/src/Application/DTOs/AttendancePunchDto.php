<?php

declare(strict_types=1);

namespace Application\DTOs;

final readonly class AttendancePunchDto
{
    public function __construct(
        public string $id,
        public string $type,
        public string $recordedAt,
        public ?float $latitude,
        public ?float $longitude,
        public ?string $deviceId,
        public string $syncId,
        public bool $isManualOverride,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'recorded_at' => $this->recordedAt,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'device_id' => $this->deviceId,
            'sync_id' => $this->syncId,
            'is_manual_override' => $this->isManualOverride,
        ];
    }
}
