<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Application\Commands\ClockIn\ClockInCommand;
use DateTimeImmutable;
use Illuminate\Foundation\Http\FormRequest;

class ClockInRequest extends FormRequest
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
            'recorded_at' => ['required', 'date'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'device_id' => ['nullable', 'string', 'max:255'],
            'sync_id' => ['nullable', 'string', 'max:255'],
            'is_manual_override' => ['nullable', 'boolean'],
        ];
    }

    public function toCommand(): ClockInCommand
    {
        /** @var array{user_id: string, recorded_at: string, latitude?: ?float, longitude?: ?float, device_id?: ?string, sync_id?: ?string, is_manual_override?: ?bool} $data */
        $data = $this->validated();

        return new ClockInCommand(
            userId: $data['user_id'],
            recordedAt: new DateTimeImmutable($data['recorded_at']),
            latitude: isset($data['latitude']) && $data['latitude'] !== null ? (float) $data['latitude'] : null,
            longitude: isset($data['longitude']) && $data['longitude'] !== null ? (float) $data['longitude'] : null,
            deviceId: $data['device_id'] ?? null,
            syncId: $data['sync_id'] ?? null,
            isManualOverride: (bool) ($data['is_manual_override'] ?? false),
        );
    }
}
