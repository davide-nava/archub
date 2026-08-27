<?php

declare(strict_types=1);

namespace Infrastructure\Persistence;

use App\Models\Attendance as AttendanceModel;
use DateTimeImmutable;
use Domain\Enums\AttendanceType;
use Domain\Model\Attendance;
use Domain\Repositories\AttendanceRepositoryInterface;
use Domain\ValueObjects\Coordinates;
use Domain\ValueObjects\SyncId;
use Illuminate\Support\Carbon;

final class EloquentAttendanceRepository implements AttendanceRepositoryInterface
{
    public function save(Attendance $attendance): void
    {
        AttendanceModel::updateOrCreate(
            ['sync_id' => $attendance->syncId()->value()],
            [
                'id' => $attendance->id(),
                'user_id' => $attendance->userId(),
                'type' => $attendance->type(),
                'recorded_at' => $attendance->recordedAt()->format('Y-m-d H:i:s'),
                'latitude' => $attendance->coordinates()?->latitude(),
                'longitude' => $attendance->coordinates()?->longitude(),
                'device_id' => $attendance->deviceId(),
                'is_manual_override' => $attendance->isManualOverride(),
            ],
        );
    }

    public function findById(string $id): ?Attendance
    {
        $model = AttendanceModel::find($id);

        return $model !== null ? $this->toDomain($model) : null;
    }

    public function findBySyncId(SyncId $syncId): ?Attendance
    {
        $model = AttendanceModel::where('sync_id', $syncId->value())->first();

        return $model !== null ? $this->toDomain($model) : null;
    }

    public function findLatestByUserId(string $userId): ?Attendance
    {
        $model = AttendanceModel::where('user_id', $userId)
            ->orderByDesc('recorded_at')
            ->first();

        return $model !== null ? $this->toDomain($model) : null;
    }

    /**
     * @param  array<Attendance>  $attendances
     */
    public function saveBatch(array $attendances): int
    {
        if (empty($attendances)) {
            return 0;
        }

        $now = Carbon::now()->toDateTimeString();

        $rows = array_map(function (Attendance $attendance) use ($now): array {
            return [
                'id' => $attendance->id(),
                'user_id' => $attendance->userId(),
                'type' => $attendance->type()->value,
                'recorded_at' => $attendance->recordedAt()->format('Y-m-d H:i:s'),
                'latitude' => $attendance->coordinates()?->latitude(),
                'longitude' => $attendance->coordinates()?->longitude(),
                'device_id' => $attendance->deviceId(),
                'sync_id' => $attendance->syncId()->value(),
                'is_manual_override' => $attendance->isManualOverride() ? 1 : 0,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }, $attendances);

        AttendanceModel::upsert(
            $rows,
            ['sync_id'],
            ['user_id', 'type', 'recorded_at', 'latitude', 'longitude', 'device_id', 'is_manual_override', 'updated_at'],
        );

        return count($rows);
    }

    /**
     * @return array<Attendance>
     */
    public function getByUserIdAndDateRange(string $userId, DateTimeImmutable $startDate, DateTimeImmutable $endDate): array
    {
        $records = AttendanceModel::where('user_id', $userId)
            ->whereBetween('recorded_at', [
                $startDate->format('Y-m-d H:i:s'),
                $endDate->format('Y-m-d H:i:s'),
            ])
            ->orderBy('recorded_at', 'asc')
            ->get();

        return $records->map(fn (AttendanceModel $model) => $this->toDomain($model))->all();
    }

    private function toDomain(AttendanceModel $model): Attendance
    {
        $coordinates = Coordinates::from(
            $model->latitude !== null ? (float) $model->latitude : null,
            $model->longitude !== null ? (float) $model->longitude : null,
        );

        $type = $model->type instanceof AttendanceType
            ? $model->type
            : AttendanceType::from((string) $model->type);

        $recordedAt = $model->recorded_at instanceof Carbon
            ? DateTimeImmutable::createFromMutable($model->recorded_at->toDateTime())
            : new DateTimeImmutable((string) $model->recorded_at);

        $createdAt = $model->created_at !== null
            ? ($model->created_at instanceof Carbon
                ? DateTimeImmutable::createFromMutable($model->created_at->toDateTime())
                : new DateTimeImmutable((string) $model->created_at))
            : null;

        $updatedAt = $model->updated_at !== null
            ? ($model->updated_at instanceof Carbon
                ? DateTimeImmutable::createFromMutable($model->updated_at->toDateTime())
                : new DateTimeImmutable((string) $model->updated_at))
            : null;

        return Attendance::reconstitute(
            id: (string) $model->id,
            userId: (string) $model->user_id,
            type: $type,
            recordedAt: $recordedAt,
            coordinates: $coordinates,
            deviceId: $model->device_id,
            syncId: SyncId::fromString((string) $model->sync_id),
            isManualOverride: (bool) $model->is_manual_override,
            createdAt: $createdAt,
            updatedAt: $updatedAt,
        );
    }
}
