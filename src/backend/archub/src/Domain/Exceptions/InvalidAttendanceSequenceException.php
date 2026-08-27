<?php

declare(strict_types=1);

namespace Domain\Exceptions;

final class InvalidAttendanceSequenceException extends DomainException
{
    public static function alreadyClockedOut(string $userId): self
    {
        return new self("User [{$userId}] cannot clock out without an active clock in.");
    }

    public static function noActiveClockIn(string $userId): self
    {
        return new self("User [{$userId}] has no active clock-in recorded.");
    }

    public static function invalidTransition(string $userId, string $from, string $to): self
    {
        return new self("User [{$userId}] cannot transition attendance state from [{$from}] to [{$to}].");
    }
}
