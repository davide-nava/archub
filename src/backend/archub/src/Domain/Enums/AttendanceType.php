<?php

declare(strict_types=1);

namespace Domain\Enums;

enum AttendanceType: string
{
    case CLOCK_IN = 'CLOCK_IN';
    case CLOCK_OUT = 'CLOCK_OUT';
    case BREAK_START = 'BREAK_START';
    case BREAK_END = 'BREAK_END';

    public function isClockIn(): bool
    {
        return $this === self::CLOCK_IN;
    }

    public function isClockOut(): bool
    {
        return $this === self::CLOCK_OUT;
    }

    public function isBreakStart(): bool
    {
        return $this === self::BREAK_START;
    }

    public function isBreakEnd(): bool
    {
        return $this === self::BREAK_END;
    }

    /**
     * @return array<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
