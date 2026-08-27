<?php

declare(strict_types=1);

namespace Application\Commands\ClockOut;

use Application\DTOs\AttendanceDto;
use Domain\Model\Attendance;
use Domain\Repositories\AttendanceRepositoryInterface;
use Domain\ValueObjects\Coordinates;
use Domain\ValueObjects\SyncId;

final readonly class ClockOutCommandHandler
{
    public function __construct(
        private AttendanceRepositoryInterface $repository,
    ) {}

    public function handle(ClockOutCommand $command): AttendanceDto
    {
        $syncId = $command->syncId !== null
            ? SyncId::fromString($command->syncId)
            : SyncId::generate();

        // Check if punch with this syncId already exists (idempotency)
        $existing = $this->repository->findBySyncId($syncId);
        if ($existing !== null) {
            return AttendanceDto::fromDomain($existing);
        }

        $latestPunch = $this->repository->findLatestByUserId($command->userId);
        $lastAttendanceType = $latestPunch?->type();

        $coordinates = Coordinates::from($command->latitude, $command->longitude);

        $attendance = Attendance::clockOut(
            userId: $command->userId,
            recordedAt: $command->recordedAt,
            coordinates: $coordinates,
            deviceId: $command->deviceId,
            syncId: $syncId,
            isManualOverride: $command->isManualOverride,
            lastAttendanceType: $lastAttendanceType,
            id: $command->id,
        );

        $this->repository->save($attendance);

        return AttendanceDto::fromDomain($attendance);
    }
}
