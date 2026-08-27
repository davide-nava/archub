<?php

declare(strict_types=1);

namespace Infrastructure\ReadServices;

use Application\DTOs\AttendancePunchDto;
use Application\DTOs\MonthlyAttendanceReportDto;
use Application\Queries\GetMonthlyAttendanceReport\AttendanceReportReadServiceInterface;
use Application\Services\AttendanceAnomalyDetector;
use DateTimeImmutable;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;

final readonly class SqliteAttendanceReportReadService implements AttendanceReportReadServiceInterface
{
    public function __construct(
        private AttendanceAnomalyDetector $anomalyDetector = new AttendanceAnomalyDetector,
    ) {}

    public function getMonthlyReport(string $userId, int $year, int $month): MonthlyAttendanceReportDto
    {
        // 1. Fetch User data directly via optimized query
        $user = DB::table('users')
            ->where('id', $userId)
            ->first(['id', 'name', 'email', 'role', 'hourly_rate']);

        if ($user === null) {
            throw (new ModelNotFoundException)->setModel('User', [$userId]);
        }

        // 2. Define Month Date Boundaries
        $startOfMonth = new DateTimeImmutable(sprintf('%04d-%02d-01 00:00:00', $year, $month));
        $endOfMonth = $startOfMonth->modify('last day of this month')->setTime(23, 59, 59);

        // 3. Fetch all month attendance records leveraging the (user_id, recorded_at) index
        $rawRecords = DB::table('attendances')
            ->where('user_id', $userId)
            ->whereBetween('recorded_at', [
                $startOfMonth->format('Y-m-d H:i:s'),
                $endOfMonth->format('Y-m-d H:i:s'),
            ])
            ->orderBy('recorded_at', 'asc')
            ->get([
                'id',
                'type',
                'recorded_at',
                'latitude',
                'longitude',
                'device_id',
                'sync_id',
                'is_manual_override',
            ]);

        // 4. Group punches by calendar date (Y-m-d)
        $punchesByDate = [];
        foreach ($rawRecords as $record) {
            $dateKey = substr((string) $record->recorded_at, 0, 10);
            $punchesByDate[$dateKey][] = new AttendancePunchDto(
                id: (string) $record->id,
                type: (string) $record->type,
                recordedAt: (string) $record->recorded_at,
                latitude: $record->latitude !== null ? (float) $record->latitude : null,
                longitude: $record->longitude !== null ? (float) $record->longitude : null,
                deviceId: $record->device_id !== null ? (string) $record->device_id : null,
                syncId: (string) $record->sync_id,
                isManualOverride: (bool) $record->is_manual_override,
            );
        }

        // 5. Analyze each active day using the anomaly detector
        $dailyReports = [];
        $totalWorkedHours = 0.0;
        $totalOvertimeHours = 0.0;
        $totalBreakHours = 0.0;
        $totalAnomalies = 0;

        foreach ($punchesByDate as $dateKey => $punches) {
            $dailyReport = $this->anomalyDetector->analyzeDay($dateKey, $punches);
            $dailyReports[] = $dailyReport;

            $totalWorkedHours += $dailyReport->workedHours;
            $totalOvertimeHours += $dailyReport->overtimeHours;
            $totalBreakHours += $dailyReport->breakHours;
            $totalAnomalies += count($dailyReport->anomalies);
        }

        $hourlyRate = (float) $user->hourly_rate;
        $totalEstimatedPay = round($totalWorkedHours * $hourlyRate, 2);

        return new MonthlyAttendanceReportDto(
            userId: (string) $user->id,
            userName: (string) $user->name,
            userEmail: (string) $user->email,
            userRole: (string) $user->role,
            hourlyRate: $hourlyRate,
            year: $year,
            month: $month,
            totalWorkedHours: round($totalWorkedHours, 2),
            totalOvertimeHours: round($totalOvertimeHours, 2),
            totalBreakHours: round($totalBreakHours, 2),
            totalEstimatedPay: $totalEstimatedPay,
            dailyReports: $dailyReports,
            anomalyCount: $totalAnomalies,
        );
    }
}
