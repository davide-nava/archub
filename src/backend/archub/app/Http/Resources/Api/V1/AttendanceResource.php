<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use Application\DTOs\AttendanceDto;
use Domain\Model\Attendance;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property-read Attendance|AttendanceDto $resource
 */
class AttendanceResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        if ($this->resource instanceof AttendanceDto) {
            return $this->resource->toArray();
        }

        if ($this->resource instanceof Attendance) {
            return $this->resource->toArray();
        }

        return parent::toArray($request);
    }
}
