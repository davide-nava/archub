<?php

declare(strict_types=1);

use App\Http\Controllers\Api\V1\AttendanceController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.v1.')->group(function (): void {
    Route::prefix('attendances')->name('attendances.')->group(function (): void {
        Route::post('clock-in', [AttendanceController::class, 'clockIn'])->name('clock-in');
        Route::post('clock-out', [AttendanceController::class, 'clockOut'])->name('clock-out');
        Route::post('sync', [AttendanceController::class, 'syncBatch'])->name('sync');
        Route::get('monthly-report', [AttendanceController::class, 'monthlyReport'])->name('monthly-report');
    });
});
