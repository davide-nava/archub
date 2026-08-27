<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Attendance;
use App\Models\User;
use Carbon\CarbonImmutable;
use Domain\Enums\AttendanceType;
use Domain\Enums\UserRole;
use Domain\ValueObjects\SyncId;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Create 1 Admin
        $admin = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Admin User',
            'email' => 'admin@archub.local',
            'password' => Hash::make('password'),
            'role' => UserRole::ADMIN,
            'hourly_rate' => 50.00,
            'email_verified_at' => now(),
        ]);

        // 2. Create 2 Managers
        $manager1 = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Sarah Operations',
            'email' => 'sarah.manager@archub.local',
            'password' => Hash::make('password'),
            'role' => UserRole::MANAGER,
            'hourly_rate' => 38.00,
            'email_verified_at' => now(),
        ]);

        $manager2 = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Michael Logistics',
            'email' => 'michael.manager@archub.local',
            'password' => Hash::make('password'),
            'role' => UserRole::MANAGER,
            'hourly_rate' => 36.50,
            'email_verified_at' => now(),
        ]);

        // 3. Create 5 Employees
        $employeesData = [
            ['name' => 'Alice Johnson', 'email' => 'alice@archub.local', 'rate' => 22.50],
            ['name' => 'Bob Smith', 'email' => 'bob@archub.local', 'rate' => 24.00],
            ['name' => 'Charlie Brown', 'email' => 'charlie@archub.local', 'rate' => 25.00],
            ['name' => 'Diana Prince', 'email' => 'diana@archub.local', 'rate' => 28.00],
            ['name' => 'Evan Wright', 'email' => 'evan@archub.local', 'rate' => 23.00],
        ];

        /** @var list<User> $employees */
        $employees = [];
        foreach ($employeesData as $data) {
            $employees[] = User::create([
                'id' => (string) Str::uuid(),
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make('password'),
                'role' => UserRole::EMPLOYEE,
                'hourly_rate' => $data['rate'],
                'email_verified_at' => now(),
            ]);
        }

        // 4. Seed 30 Days of realistic daily attendance logs for employees
        $now = CarbonImmutable::now();
        $startDate = $now->subDays(30);

        $officeLat = 45.4642;
        $officeLng = 9.1900;

        $attendanceRows = [];

        foreach ($employees as $index => $employee) {
            $deviceId = sprintf('DEV_EMP_%03d', $index + 1);

            for ($dayOffset = 0; $dayOffset < 30; $dayOffset++) {
                $currentDay = $startDate->addDays($dayOffset);

                // Skip weekends for regular work
                if ($currentDay->isWeekend()) {
                    continue;
                }

                $latJitter = $officeLat + (float) (mt_rand(-50, 50) / 100000.0);
                $lngJitter = $officeLng + (float) (mt_rand(-50, 50) / 100000.0);

                // Scenario A: Charlie has 1 missing clock-out anomaly on day 10
                if ($index === 2 && $dayOffset === 10) {
                    $clockInTime = $currentDay->setTime(8, 45, 0);
                    $attendanceRows[] = [
                        'id' => (string) Str::uuid(),
                        'user_id' => $employee->id,
                        'type' => AttendanceType::CLOCK_IN->value,
                        'recorded_at' => $clockInTime->toDateTimeString(),
                        'latitude' => $latJitter,
                        'longitude' => $lngJitter,
                        'device_id' => $deviceId,
                        'sync_id' => (string) SyncId::generate(),
                        'is_manual_override' => false,
                        'created_at' => $clockInTime->toDateTimeString(),
                        'updated_at' => $clockInTime->toDateTimeString(),
                    ];

                    continue;
                }

                // Scenario B: Bob has 1 manual override punch on day 15
                $isBobManualDay = ($index === 1 && $dayOffset === 15);

                // Scenario C: Alice has 1 overtime day (10.5 hours worked) on day 8
                $isAliceOvertimeDay = ($index === 0 && $dayOffset === 8);

                $clockInMin = mt_rand(25, 45);
                $clockInTime = $currentDay->setTime(8, $clockInMin, 0);
                $breakStartTime = $currentDay->setTime(12, 30, 0);
                $breakEndTime = $currentDay->setTime(13, 30, 0);
                $clockOutTime = $isAliceOvertimeDay
                    ? $currentDay->setTime(20, 0, 0)
                    : $currentDay->setTime(17, mt_rand(30, 45), 0);

                // 1. Clock In
                $attendanceRows[] = [
                    'id' => (string) Str::uuid(),
                    'user_id' => $employee->id,
                    'type' => AttendanceType::CLOCK_IN->value,
                    'recorded_at' => $clockInTime->toDateTimeString(),
                    'latitude' => $latJitter,
                    'longitude' => $lngJitter,
                    'device_id' => $deviceId,
                    'sync_id' => (string) SyncId::generate(),
                    'is_manual_override' => $isBobManualDay,
                    'created_at' => $clockInTime->toDateTimeString(),
                    'updated_at' => $clockInTime->toDateTimeString(),
                ];

                // 2. Break Start
                $attendanceRows[] = [
                    'id' => (string) Str::uuid(),
                    'user_id' => $employee->id,
                    'type' => AttendanceType::BREAK_START->value,
                    'recorded_at' => $breakStartTime->toDateTimeString(),
                    'latitude' => $latJitter,
                    'longitude' => $lngJitter,
                    'device_id' => $deviceId,
                    'sync_id' => (string) SyncId::generate(),
                    'is_manual_override' => false,
                    'created_at' => $breakStartTime->toDateTimeString(),
                    'updated_at' => $breakStartTime->toDateTimeString(),
                ];

                // 3. Break End
                $attendanceRows[] = [
                    'id' => (string) Str::uuid(),
                    'user_id' => $employee->id,
                    'type' => AttendanceType::BREAK_END->value,
                    'recorded_at' => $breakEndTime->toDateTimeString(),
                    'latitude' => $latJitter,
                    'longitude' => $lngJitter,
                    'device_id' => $deviceId,
                    'sync_id' => (string) SyncId::generate(),
                    'is_manual_override' => false,
                    'created_at' => $breakEndTime->toDateTimeString(),
                    'updated_at' => $breakEndTime->toDateTimeString(),
                ];

                // 4. Clock Out
                $attendanceRows[] = [
                    'id' => (string) Str::uuid(),
                    'user_id' => $employee->id,
                    'type' => AttendanceType::CLOCK_OUT->value,
                    'recorded_at' => $clockOutTime->toDateTimeString(),
                    'latitude' => $latJitter,
                    'longitude' => $lngJitter,
                    'device_id' => $deviceId,
                    'sync_id' => (string) SyncId::generate(),
                    'is_manual_override' => false,
                    'created_at' => $clockOutTime->toDateTimeString(),
                    'updated_at' => $clockOutTime->toDateTimeString(),
                ];
            }
        }

        foreach (array_chunk($attendanceRows, 100) as $chunk) {
            Attendance::insert($chunk);
        }
    }
}
