<?php

declare(strict_types=1);

namespace Application\Services;

use Application\DTOs\AttendancePunchDto;
use Application\DTOs\DailyAttendanceReportDto;
use DateTimeImmutable;
use Domain\Enums\AttendanceType;

final class AttendanceAnomalyDetector
{
    private const STANDARD_DAILY_HOURS = 8.0;

    private const MAX_STANDARD_DAILY_HOURS = 12.0;

    private const MAX_STANDARD_BREAK_HOURS = 2.0;

    /**
     * Analyzes punches for a specific day and builds a DailyAttendanceReportDto with calculated hours and anomalies.
     *
     * @param  string  $date  Y-m-d
     * @param  array<AttendancePunchDto>  $punches  Chronologically sorted punches
     */
    public function analyzeDay(string $date, array $punches): DailyAttendanceReportDto
    {
        if (empty($punches)) {
            return new DailyAttendanceReportDto(
                date: $date,
                punches: [],
                firstClockIn: null,
                lastClockOut: null,
                workedHours: 0.0,
                breakHours: 0.0,
                overtimeHours: 0.0,
                anomalies: [],
                hasAnomaly: false,
            );
        }

        // Sort punches chronologically just in case
        usort($punches, fn (AttendancePunchDto $a, AttendancePunchDto $b) => strcmp($a->recordedAt, $b->recordedAt));

        $anomalies = [];
        $firstClockIn = null;
        $lastClockOut = null;

        $totalWorkedSeconds = 0;
        $totalBreakSeconds = 0;

        $currentClockInTime = null;
        $currentBreakStartTime = null;
        $currentState = null; // 'CLOCK_IN', 'BREAK', 'CLOCK_OUT' or null

        foreach ($punches as $punch) {
            $punchType = AttendanceType::tryFrom($punch->type);
            $punchTimestamp = (new DateTimeImmutable($punch->recordedAt))->getTimestamp();

            if ($punch->isManualOverride) {
                $anomalies[] = "Punch at {$punch->recordedAt} ({$punch->type}) was recorded via manual override.";
            }

            if ($punchType === null) {
                $anomalies[] = "Unrecognized punch type [{$punch->type}] at {$punch->recordedAt}.";

                continue;
            }

            switch ($punchType) {
                case AttendanceType::CLOCK_IN:
                    if ($firstClockIn === null) {
                        $firstClockIn = $punch->recordedAt;
                    }

                    if ($currentState === 'CLOCK_IN') {
                        $anomalies[] = "Duplicate consecutive CLOCK_IN at {$punch->recordedAt} without prior CLOCK_OUT.";
                    } elseif ($currentState === 'BREAK') {
                        $anomalies[] = "CLOCK_IN at {$punch->recordedAt} while break was still active.";
                        // Close dangling break
                        if ($currentBreakStartTime !== null) {
                            $totalBreakSeconds += max(0, $punchTimestamp - $currentBreakStartTime);
                            $currentBreakStartTime = null;
                        }
                    }

                    $currentClockInTime = $punchTimestamp;
                    $currentState = 'CLOCK_IN';
                    break;

                case AttendanceType::BREAK_START:
                    if ($currentState !== 'CLOCK_IN') {
                        $anomalies[] = "BREAK_START at {$punch->recordedAt} without an active CLOCK_IN.";
                    }

                    if ($currentState === 'BREAK') {
                        $anomalies[] = "Duplicate consecutive BREAK_START at {$punch->recordedAt}.";
                    } else {
                        $currentBreakStartTime = $punchTimestamp;
                        $currentState = 'BREAK';
                    }
                    break;

                case AttendanceType::BREAK_END:
                    if ($currentState !== 'BREAK' || $currentBreakStartTime === null) {
                        $anomalies[] = "BREAK_END at {$punch->recordedAt} without preceding BREAK_START.";
                    } else {
                        $breakDuration = max(0, $punchTimestamp - $currentBreakStartTime);
                        $totalBreakSeconds += $breakDuration;
                        $currentBreakStartTime = null;
                        $currentState = 'CLOCK_IN';
                    }
                    break;

                case AttendanceType::CLOCK_OUT:
                    $lastClockOut = $punch->recordedAt;

                    if ($currentState === 'BREAK') {
                        $anomalies[] = "CLOCK_OUT at {$punch->recordedAt} while still in active break.";
                        if ($currentBreakStartTime !== null) {
                            $totalBreakSeconds += max(0, $punchTimestamp - $currentBreakStartTime);
                            $currentBreakStartTime = null;
                        }
                    }

                    if ($currentState === null || ($currentClockInTime === null && $currentState !== 'CLOCK_IN')) {
                        $anomalies[] = "CLOCK_OUT at {$punch->recordedAt} without a preceding CLOCK_IN.";
                    } else {
                        if ($currentClockInTime !== null) {
                            $segmentDuration = max(0, $punchTimestamp - $currentClockInTime);
                            $totalWorkedSeconds += $segmentDuration;
                            $currentClockInTime = null;
                        }
                    }

                    $currentState = 'CLOCK_OUT';
                    break;
            }
        }

        // Check dangling end of day states
        if ($currentState === 'CLOCK_IN' && $currentClockInTime !== null) {
            $anomalies[] = 'Missing CLOCK_OUT for shift started at '.(new DateTimeImmutable("@{$currentClockInTime}"))->format('Y-m-d H:i:s').'.';
        } elseif ($currentState === 'BREAK') {
            $anomalies[] = 'Incomplete day: Shift ended while still in active BREAK.';
        }

        // Total worked seconds is clock-in-to-clock-out minus break duration
        $netWorkedSeconds = max(0, $totalWorkedSeconds - $totalBreakSeconds);
        $workedHours = round($netWorkedSeconds / 3600, 2);
        $breakHours = round($totalBreakSeconds / 3600, 2);
        $overtimeHours = round(max(0.0, $workedHours - self::STANDARD_DAILY_HOURS), 2);

        if ($workedHours > self::MAX_STANDARD_DAILY_HOURS) {
            $anomalies[] = "Excessive shift duration: {$workedHours} hours worked (exceeds threshold of ".self::MAX_STANDARD_DAILY_HOURS.'h).';
        }

        if ($breakHours > self::MAX_STANDARD_BREAK_HOURS) {
            $anomalies[] = "Excessive break duration: {$breakHours} hours of break (exceeds threshold of ".self::MAX_STANDARD_BREAK_HOURS.'h).';
        }

        return new DailyAttendanceReportDto(
            date: $date,
            punches: $punches,
            firstClockIn: $firstClockIn,
            lastClockOut: $lastClockOut,
            workedHours: $workedHours,
            breakHours: $breakHours,
            overtimeHours: $overtimeHours,
            anomalies: $anomalies,
            hasAnomaly: count($anomalies) > 0,
        );
    }
}
