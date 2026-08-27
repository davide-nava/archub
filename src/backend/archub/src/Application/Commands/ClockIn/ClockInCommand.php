<?php

declare(strict_types=1);

namespace Application\Commands\ClockIn;

use DateTimeImmutable;

final readonly class ClockInCommand
{
    public function __construct(
        public string $userId,
        public DateTimeImmutable $recordedAt,
        public ?float $latitude = null,
        public ?float $longitude = null,
        public ?string $deviceId = null,
        public ?string $syncId = null,
        public bool $isManualOverride = false,
        public ?string $id = null,
    ) {}
}
