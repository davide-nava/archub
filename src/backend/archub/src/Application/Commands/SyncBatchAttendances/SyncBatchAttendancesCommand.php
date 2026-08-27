<?php

declare(strict_types=1);

namespace Application\Commands\SyncBatchAttendances;

final readonly class SyncBatchAttendancesCommand
{
    /**
     * @param  array<SyncBatchItemDto>  $items
     */
    public function __construct(
        public array $items,
    ) {}

    /**
     * @param  array<array<string, mixed>>  $rawItems
     */
    public static function fromArray(array $rawItems): self
    {
        $items = array_map(
            fn (array $item) => SyncBatchItemDto::fromArray($item),
            $rawItems,
        );

        return new self($items);
    }
}
