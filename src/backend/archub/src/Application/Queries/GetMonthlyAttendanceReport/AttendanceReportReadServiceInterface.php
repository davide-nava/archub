<?php

declare(strict_types=1);

namespace Application\Queries\GetMonthlyAttendanceReport;

use Application\DTOs\MonthlyAttendanceReportDto;

interface AttendanceReportReadServiceInterface
{
    /**
     * Retrieves an aggregated, read-only monthly attendance report with anomaly detection.
     */
    public function getMonthlyReport(string $userId, int $year, int $month): MonthlyAttendanceReportDto;
}
