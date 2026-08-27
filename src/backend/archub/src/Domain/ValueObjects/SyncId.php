<?php

declare(strict_types=1);

namespace Domain\ValueObjects;

use Illuminate\Support\Str;
use InvalidArgumentException;
use Stringable;

final readonly class SyncId implements Stringable
{
    public function __construct(public string $value)
    {
        $trimmed = trim($this->value);
        if ($trimmed === '') {
            throw new InvalidArgumentException('SyncId cannot be empty.');
        }
    }

    public static function fromString(string $value): self
    {
        return new self($value);
    }

    public static function generate(): self
    {
        return new self((string) Str::uuid());
    }

    public function value(): string
    {
        return $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
