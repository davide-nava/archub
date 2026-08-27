<?php

declare(strict_types=1);

namespace Application\DTOs;

final readonly class MonthlyAttendanceReportDto
{
    /**
     * @param  array<DailyAttendanceReportDto>  $dailyReports
     */
    public function __construct(
        public string $userId,
        public string $userName,
        public string $userEmail,
        public string $userRole,
        public float $hourlyRate,
        public int $year,
        public int $month,
        public float $totalWorkedHours,
        public float $totalOvertimeHours,
        public float $totalBreakHours,
        public float $totalEstimatedPay,
        public array $dailyReports,
        public int $anomalyCount,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'user_id' => $this->userId,
            'user_name' => $this->userName,
            'user_email' => $this->userEmail,
            'user_role' => $this->userRole,
            'hourly_rate' => $this->hourlyRate,
            'year' => $this->year,
            'month' => $this->month,
            'total_worked_hours' => $this->totalWorkedHours,
            'total_overtime_hours' => $this->totalOvertimeHours,
            'total_break_hours' => $this->totalBreakHours,
            'total_estimated_pay' => $this->totalEstimatedPay,
            'anomaly_count' => $this->anomalyCount,
            'daily_reports' => array_map(fn (DailyAttendanceReportDto $report) => $report->toArray(), $this->dailyReports),
        ];
    }
}
