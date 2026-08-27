export interface ApiResponse<T> {
  readonly success: boolean;
  readonly message?: string;
  readonly data: T;
  readonly meta?: Record<string, unknown>;
}

export interface ApiPaginatedResponse<T> {
  readonly success: boolean;
  readonly message?: string;
  readonly data: readonly T[];
  readonly meta: {
    readonly currentPage: number;
    readonly lastPage: number;
    readonly perPage: number;
    readonly total: number;
  };
}

export interface ApiErrorDetail {
  readonly field?: string;
  readonly message: string;
}

export interface ApiErrorResponse {
  readonly success: false;
  readonly message: string;
  readonly errors?: Record<string, readonly string[]>;
}
