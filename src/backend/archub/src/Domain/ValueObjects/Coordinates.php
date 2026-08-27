<?php

declare(strict_types=1);

namespace Domain\ValueObjects;

use InvalidArgumentException;

final readonly class Coordinates
{
    public function __construct(
        public float $latitude,
        public float $longitude,
    ) {
        if ($this->latitude < -90.0 || $this->latitude > 90.0) {
            throw new InvalidArgumentException("Latitude must be between -90 and 90 degrees. Given: {$this->latitude}");
        }

        if ($this->longitude < -180.0 || $this->longitude > 180.0) {
            throw new InvalidArgumentException("Longitude must be between -180 and 180 degrees. Given: {$this->longitude}");
        }
    }

    public static function from(?float $latitude, ?float $longitude): ?self
    {
        if ($latitude === null || $longitude === null) {
            return null;
        }

        return new self($latitude, $longitude);
    }

    public function latitude(): float
    {
        return $this->latitude;
    }

    public function longitude(): float
    {
        return $this->longitude;
    }

    public function equals(self $other): bool
    {
        return abs($this->latitude - $other->latitude) < 0.0000001
            && abs($this->longitude - $other->longitude) < 0.0000001;
    }

    /**
     * @return array{latitude: float, longitude: float}
     */
    public function toArray(): array
    {
        return [
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
        ];
    }
}
