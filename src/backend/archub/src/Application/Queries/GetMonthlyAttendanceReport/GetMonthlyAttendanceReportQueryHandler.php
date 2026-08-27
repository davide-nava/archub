<?php

declare(strict_types=1);

namespace Application\Queries\GetMonthlyAttendanceReport;

use Application\DTOs\MonthlyAttendanceReportDto;

final readonly class GetMonthlyAttendanceReportQueryHandler
{
    public function __construct(
        private AttendanceReportReadServiceInterface $readService,
    ) {}

    public function handle(GetMonthlyAttendanceReportQuery $query): MonthlyAttendanceReportDto
    {
        return $this->readService->getMonthlyReport(
            userId: $query->userId,
            year: $query->year,
            month: $query->month,
        );
    }
}
