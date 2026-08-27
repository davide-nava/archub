<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Application\Queries\GetMonthlyAttendanceReport\GetMonthlyAttendanceReportQuery;
use Illuminate\Foundation\Http\FormRequest;

class GetMonthlyAttendanceReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'user_id' => ['required', 'uuid', 'exists:users,id'],
            'year' => ['required', 'integer', 'min:2000', 'max:2100'],
            'month' => ['required', 'integer', 'min:1', 'max:12'],
        ];
    }

    public function toQuery(): GetMonthlyAttendanceReportQuery
    {
        /** @var array{user_id: string, year: int|string, month: int|string} $data */
        $data = $this->validated();

        return new GetMonthlyAttendanceReportQuery(
            userId: $data['user_id'],
            year: (int) $data['year'],
            month: (int) $data['month'],
        );
    }
}
