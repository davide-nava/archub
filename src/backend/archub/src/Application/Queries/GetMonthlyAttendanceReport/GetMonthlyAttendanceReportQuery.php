<?php

declare(strict_types=1);

namespace Application\Queries\GetMonthlyAttendanceReport;

final readonly class GetMonthlyAttendanceReportQuery
{
    public function __construct(
        public string $userId,
        public int $year,
        public int $month,
    ) {}
}
