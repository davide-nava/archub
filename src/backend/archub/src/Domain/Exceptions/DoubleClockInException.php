<?php

declare(strict_types=1);

namespace Domain\Exceptions;

final class DoubleClockInException extends DomainException
{
    public static function alreadyClockedIn(string $userId): self
    {
        return new self("User [{$userId}] is already clocked in. A CLOCK_OUT is required before a new CLOCK_IN.");
    }
}
