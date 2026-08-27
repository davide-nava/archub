import { CanActivateFn, Router, UrlTree } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

/**
 * Functional Route Guard ensuring user is authenticated via Sanctum Bearer token.
 * Redirects unauthenticated users to /auth/login with returnUrl query parameter.
 */
export const authGuard: CanActivateFn = (_route, state): boolean | UrlTree => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  return router.createUrlTree(['/auth/login'], {
    queryParams: state.url && state.url !== '/' ? { returnUrl: state.url } : undefined
  });
};

/**
 * Functional Route Guard for guest-only pages (e.g. login, forgot-password).
 * Redirects already logged-in users to the main attendance dashboard.
 */
export const guestGuard: CanActivateFn = (): boolean | UrlTree => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (!authService.isAuthenticated()) {
    return true;
  }

  return router.createUrlTree(['/attendance']);
};
