import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

/**
 * Functional HTTP Interceptor for Laravel Sanctum Bearer Token injection
 * and global 401 Unauthorized / 403 Forbidden response handling.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.token();

  // Clone the request with necessary headers
  const headers: Record<string, string> = {
    Accept: 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const authReq = req.clone({ setHeaders: headers });

  return next(authReq).pipe(
    catchError((error: unknown) => {
      if (error instanceof HttpErrorResponse) {
        if (error.status === 401) {
          // Token expired or invalid: flush session and redirect
          authService.handleUnauthorized();
        } else if (error.status === 403) {
          // Forbidden access
          console.error(`[AuthInterceptor] 403 Forbidden: Access denied for ${req.url}`);
        }
      }
      return throwError(() => error);
    })
  );
};
