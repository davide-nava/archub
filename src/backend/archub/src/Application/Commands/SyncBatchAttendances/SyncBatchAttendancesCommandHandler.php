<?php

declare(strict_types=1);

namespace Application\Commands\SyncBatchAttendances;

use Application\DTOs\SyncBatchResultDto;
use Domain\Enums\AttendanceType;
use Domain\Model\Attendance;
use Domain\Repositories\AttendanceRepositoryInterface;
use Domain\ValueObjects\Coordinates;
use Domain\ValueObjects\SyncId;
use Illuminate\Support\Str;
use InvalidArgumentException;

final readonly class SyncBatchAttendancesCommandHandler
{
    public function __construct(
        private AttendanceRepositoryInterface $repository,
    ) {}

    public function handle(SyncBatchAttendancesCommand $command): SyncBatchResultDto
    {
        if (empty($command->items)) {
            return new SyncBatchResultDto(
                syncedCount: 0,
                syncIds: [],
                message: 'No attendance items provided for batch synchronization.',
            );
        }

        $attendances = [];
        $syncIds = [];

        foreach ($command->items as $item) {
            $type = AttendanceType::tryFrom($item->type);
            if ($type === null) {
                throw new InvalidArgumentException("Invalid attendance type [{$item->type}] in batch sync.");
            }

            $syncId = SyncId::fromString($item->syncId);
            $syncIds[] = $syncId->value();

            $coordinates = Coordinates::from($item->latitude, $item->longitude);

            $attendance = Attendance::reconstitute(
                id: $item->id ?? (string) Str::uuid(),
                userId: $item->userId,
                type: $type,
                recordedAt: $item->recordedAt,
                coordinates: $coordinates,
                deviceId: $item->deviceId,
                syncId: $syncId,
                isManualOverride: $item->isManualOverride,
            );

            $attendances[] = $attendance;
        }

        $syncedCount = $this->repository->saveBatch($attendances);

        return new SyncBatchResultDto(
            syncedCount: $syncedCount,
            syncIds: $syncIds,
            message: "Successfully synchronized {$syncedCount} attendance records.",
        );
    }
}
