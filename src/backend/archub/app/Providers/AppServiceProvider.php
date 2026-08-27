<?php

declare(strict_types=1);

namespace App\Providers;

use Application\Queries\GetMonthlyAttendanceReport\AttendanceReportReadServiceInterface;
use Domain\Repositories\AttendanceRepositoryInterface;
use Illuminate\Support\ServiceProvider;
use Infrastructure\Persistence\EloquentAttendanceRepository;
use Infrastructure\ReadServices\SqliteAttendanceReportReadService;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(
            AttendanceRepositoryInterface::class,
            EloquentAttendanceRepository::class,
        );

        $this->app->bind(
            AttendanceReportReadServiceInterface::class,
            SqliteAttendanceReportReadService::class,
        );
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
