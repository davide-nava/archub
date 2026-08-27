<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ClockInRequest;
use App\Http\Requests\Api\V1\ClockOutRequest;
use App\Http\Requests\Api\V1\GetMonthlyAttendanceReportRequest;
use App\Http\Requests\Api\V1\SyncBatchAttendancesRequest;
use App\Http\Resources\Api\V1\AttendanceResource;
use App\Http\Resources\Api\V1\MonthlyAttendanceReportResource;
use App\Http\Resources\Api\V1\SyncBatchResultResource;
use Application\Commands\ClockIn\ClockInCommandHandler;
use Application\Commands\ClockOut\ClockOutCommandHandler;
use Application\Commands\SyncBatchAttendances\SyncBatchAttendancesCommandHandler;
use Application\Queries\GetMonthlyAttendanceReport\GetMonthlyAttendanceReportQueryHandler;
use Domain\Exceptions\DomainException;
use Domain\Exceptions\DoubleClockInException;
use Domain\Exceptions\InvalidAttendanceSequenceException;
use Illuminate\Http\JsonResponse;
use Symfony\Component\HttpFoundation\Response;

class AttendanceController extends Controller
{
    /**
     * Record a CLOCK_IN attendance punch.
     */
    public function clockIn(ClockInRequest $request, ClockInCommandHandler $handler): JsonResponse
    {
        try {
            $command = $request->toCommand();
            $dto = $handler->handle($command);

            return (new AttendanceResource($dto))
                ->response()
                ->setStatusCode(Response::HTTP_CREATED);
        } catch (DoubleClockInException|InvalidAttendanceSequenceException|DomainException $e) {
            return response()->json([
                'message' => $e->getMessage(),
                'error' => class_basename($e),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }
    }

    /**
     * Record a CLOCK_OUT attendance punch.
     */
    public function clockOut(ClockOutRequest $request, ClockOutCommandHandler $handler): JsonResponse
    {
        try {
            $command = $request->toCommand();
            $dto = $handler->handle($command);

            return (new AttendanceResource($dto))
                ->response()
                ->setStatusCode(Response::HTTP_OK);
        } catch (DoubleClockInException|InvalidAttendanceSequenceException|DomainException $e) {
            return response()->json([
                'message' => $e->getMessage(),
                'error' => class_basename($e),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }
    }

    /**
     * Bulk idempotent synchronization of attendance punches.
     */
    public function syncBatch(SyncBatchAttendancesRequest $request, SyncBatchAttendancesCommandHandler $handler): JsonResponse
    {
        try {
            $command = $request->toCommand();
            $dto = $handler->handle($command);

            return (new SyncBatchResultResource($dto))
                ->response()
                ->setStatusCode(Response::HTTP_OK);
        } catch (DomainException $e) {
            return response()->json([
                'message' => $e->getMessage(),
                'error' => class_basename($e),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }
    }

    /**
     * Retrieve aggregated monthly attendance report with anomaly calculation.
     */
    public function monthlyReport(GetMonthlyAttendanceReportRequest $request, GetMonthlyAttendanceReportQueryHandler $handler): JsonResponse
    {
        $query = $request->toQuery();
        $dto = $handler->handle($query);

        return (new MonthlyAttendanceReportResource($dto))
            ->response()
            ->setStatusCode(Response::HTTP_OK);
    }
}
