<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use Application\DTOs\SyncBatchResultDto;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property-read SyncBatchResultDto $resource
 */
class SyncBatchResultResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        if ($this->resource instanceof SyncBatchResultDto) {
            return $this->resource->toArray();
        }

        return parent::toArray($request);
    }
}
