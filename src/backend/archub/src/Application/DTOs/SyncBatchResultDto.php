<?php

declare(strict_types=1);

namespace Application\DTOs;

final readonly class SyncBatchResultDto
{
    /**
     * @param  array<string>  $syncIds
     */
    public function __construct(
        public int $syncedCount,
        public array $syncIds,
        public string $message = 'Batch attendance synchronized successfully.',
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'synced_count' => $this->syncedCount,
            'sync_ids' => $this->syncIds,
            'message' => $this->message,
        ];
    }
}
