<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Attendance;
use App\Models\User;
use Domain\Enums\AttendanceType;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Attendance>
 */
class AttendanceFactory extends Factory
{
    protected $model = Attendance::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'id' => (string) Str::uuid(),
            'user_id' => User::factory(),
            'type' => AttendanceType::CLOCK_IN,
            'recorded_at' => now(),
            'latitude' => 45.4642 + fake()->randomFloat(6, -0.01, 0.01),
            'longitude' => 9.1900 + fake()->randomFloat(6, -0.01, 0.01),
            'device_id' => 'DEV_'.fake()->lexify('??????'),
            'sync_id' => (string) Str::uuid(),
            'is_manual_override' => false,
        ];
    }

    public function clockIn(): static
    {
        return $this->state(fn () => [
            'type' => AttendanceType::CLOCK_IN,
        ]);
    }

    public function clockOut(): static
    {
        return $this->state(fn () => [
            'type' => AttendanceType::CLOCK_OUT,
        ]);
    }

    public function breakStart(): static
    {
        return $this->state(fn () => [
            'type' => AttendanceType::BREAK_START,
        ]);
    }

    public function breakEnd(): static
    {
        return $this->state(fn () => [
            'type' => AttendanceType::BREAK_END,
        ]);
    }

    public function manualOverride(): static
    {
        return $this->state(fn () => [
            'is_manual_override' => true,
        ]);
    }
}
