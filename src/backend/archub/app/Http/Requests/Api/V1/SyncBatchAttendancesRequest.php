<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Application\Commands\SyncBatchAttendances\SyncBatchAttendancesCommand;
use Application\Commands\SyncBatchAttendances\SyncBatchItemDto;
use DateTimeImmutable;
use Illuminate\Foundation\Http\FormRequest;

class SyncBatchAttendancesRequest extends FormRequest
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
            'items' => ['required', 'array', 'min:1'],
            'items.*.user_id' => ['required', 'uuid', 'exists:users,id'],
            'items.*.type' => ['required', 'string', 'in:CLOCK_IN,CLOCK_OUT,BREAK_START,BREAK_END'],
            'items.*.recorded_at' => ['required', 'date'],
            'items.*.sync_id' => ['required', 'string', 'max:255'],
            'items.*.id' => ['nullable', 'uuid'],
            'items.*.latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'items.*.longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'items.*.device_id' => ['nullable', 'string', 'max:255'],
            'items.*.is_manual_override' => ['nullable', 'boolean'],
        ];
    }

    public function toCommand(): SyncBatchAttendancesCommand
    {
        /** @var array{items: array<array<string, mixed>>} $data */
        $data = $this->validated();

        $items = array_map(function (array $item): SyncBatchItemDto {
            return new SyncBatchItemDto(
                userId: (string) $item['user_id'],
                type: (string) $item['type'],
                recordedAt: new DateTimeImmutable((string) $item['recorded_at']),
                syncId: (string) $item['sync_id'],
                id: isset($item['id']) && $item['id'] !== null ? (string) $item['id'] : null,
                latitude: isset($item['latitude']) && $item['latitude'] !== null ? (float) $item['latitude'] : null,
                longitude: isset($item['longitude']) && $item['longitude'] !== null ? (float) $item['longitude'] : null,
                deviceId: isset($item['device_id']) && $item['device_id'] !== null ? (string) $item['device_id'] : null,
                isManualOverride: (bool) ($item['is_manual_override'] ?? false),
            );
        }, $data['items']);

        return new SyncBatchAttendancesCommand($items);
    }
}
