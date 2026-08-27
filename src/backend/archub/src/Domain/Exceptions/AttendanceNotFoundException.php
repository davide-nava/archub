<?php

declare(strict_types=1);

namespace Domain\Exceptions;

final class AttendanceNotFoundException extends DomainException
{
    public static function forId(string $id): self
    {
        return new self("Attendance with ID [{$id}] was not found.");
    }

    public static function forSyncId(string $syncId): self
    {
        return new self("Attendance with Sync ID [{$syncId}] was not found.");
    }
}
