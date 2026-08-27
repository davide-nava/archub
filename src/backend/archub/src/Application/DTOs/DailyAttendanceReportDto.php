<?php

declare(strict_types=1);

namespace Application\DTOs;

final readonly class DailyAttendanceReportDto
{
    /**
     * @param  array<AttendancePunchDto>  $punches
     * @param  array<string>  $anomalies
     */
    public function __construct(
        public string $date,
        public array $punches,
        public ?string $firstClockIn,
        public ?string $lastClockOut,
        public float $workedHours,
        public float $breakHours,
        public float $overtimeHours,
        public array $anomalies,
        public bool $hasAnomaly,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'date' => $this->date,
            'punches' => array_map(fn (AttendancePunchDto $punch) => $punch->toArray(), $this->punches),
            'first_clock_in' => $this->firstClockIn,
            'last_clock_out' => $this->lastClockOut,
            'worked_hours' => $this->workedHours,
            'break_hours' => $this->breakHours,
            'overtime_hours' => $this->overtimeHours,
            'anomalies' => $this->anomalies,
            'has_anomaly' => $this->hasAnomaly,
        ];
    }
}
