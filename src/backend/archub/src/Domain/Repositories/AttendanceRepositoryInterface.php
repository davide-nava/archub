<?php

declare(strict_types=1);

namespace Domain\Repositories;

use DateTimeImmutable;
use Domain\Model\Attendance;
use Domain\ValueObjects\SyncId;

interface AttendanceRepositoryInterface
{
    /**
     * Persist a single Attendance aggregate root.
     */
    public function save(Attendance $attendance): void;

    /**
     * Find attendance by its UUID.
     */
    public function findById(string $id): ?Attendance;

    /**
     * Find attendance by its client sync ID.
     */
    public function findBySyncId(SyncId $syncId): ?Attendance;

    /**
     * Find the most recent attendance punch recorded for a user.
     */
    public function findLatestByUserId(string $userId): ?Attendance;

    /**
     * Bulk save / upsert attendances idempotently based on sync_id.
     *
     * @param  array<Attendance>  $attendances
     * @return int Number of records processed
     */
    public function saveBatch(array $attendances): int;

    /**
     * Get attendances for a user in a given date range ordered chronologically.
     *
     * @return array<Attendance>
     */
    public function getByUserIdAndDateRange(string $userId, DateTimeImmutable $startDate, DateTimeImmutable $endDate): array;
}
