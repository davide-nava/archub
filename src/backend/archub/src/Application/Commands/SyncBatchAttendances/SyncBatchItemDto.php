<?php

declare(strict_types=1);

namespace Application\Commands\SyncBatchAttendances;

use DateTimeImmutable;

final readonly class SyncBatchItemDto
{
    public function __construct(
        public string $userId,
        public string $type,
        public DateTimeImmutable $recordedAt,
        public string $syncId,
        public ?string $id = null,
        public ?float $latitude = null,
        public ?float $longitude = null,
        public ?string $deviceId = null,
        public bool $isManualOverride = false,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        $recordedAt = $data['recorded_at'] instanceof DateTimeImmutable
            ? $data['recorded_at']
            : new DateTimeImmutable((string) $data['recorded_at']);

        return new self(
            userId: (string) $data['user_id'],
            type: (string) $data['type'],
            recordedAt: $recordedAt,
            syncId: (string) $data['sync_id'],
            id: isset($data['id']) ? (string) $data['id'] : null,
            latitude: isset($data['latitude']) ? (float) $data['latitude'] : null,
            longitude: isset($data['longitude']) ? (float) $data['longitude'] : null,
            deviceId: isset($data['device_id']) ? (string) $data['device_id'] : null,
            isManualOverride: (bool) ($data['is_manual_override'] ?? false),
        );
    }
}
