import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot, UrlTree, provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { authGuard, guestGuard } from './auth.guard';
import { AuthService } from '../services/auth.service';

describe('Route Guards', () => {
  let authService: AuthService;
  let router: Router;

  const mockRouteSnapshot = {} as ActivatedRouteSnapshot;
  const mockStateSnapshot = { url: '/attendance' } as RouterStateSnapshot;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([]),
        provideHttpClient(),
        provideHttpClientTesting()
      ]
    });

    authService = TestBed.inject(AuthService);
    router = TestBed.inject(Router);
  });

  describe('authGuard', () => {
    it('should allow access when user is authenticated', () => {
      authService.setSession({
        token: 'active_token',
        tokenType: 'Bearer',
        user: { id: 1, name: 'User', email: 'u@archub.internal', role: 'admin' }
      });

      const result = TestBed.runInInjectionContext(() =>
        authGuard(mockRouteSnapshot, mockStateSnapshot)
      );

      expect(result).toBe(true);
    });

    it('should return UrlTree redirecting to /auth/login when user is unauthenticated', () => {
      authService.clearSession();

      const result = TestBed.runInInjectionContext(() =>
        authGuard(mockRouteSnapshot, mockStateSnapshot)
      );

      expect(result instanceof UrlTree).toBe(true);
      if (result instanceof UrlTree) {
        expect(router.serializeUrl(result)).toContain('/auth/login');
      }
    });
  });

  describe('guestGuard', () => {
    it('should allow access when user is unauthenticated', () => {
      authService.clearSession();

      const result = TestBed.runInInjectionContext(() =>
        guestGuard(mockRouteSnapshot, mockStateSnapshot)
      );

      expect(result).toBe(true);
    });

    it('should redirect authenticated user to /attendance', () => {
      authService.setSession({
        token: 'active_token',
        tokenType: 'Bearer',
        user: { id: 1, name: 'User', email: 'u@archub.internal', role: 'admin' }
      });

      const result = TestBed.runInInjectionContext(() =>
        guestGuard(mockRouteSnapshot, mockStateSnapshot)
      );

      expect(result instanceof UrlTree).toBe(true);
      if (result instanceof UrlTree) {
        expect(router.serializeUrl(result)).toContain('/attendance');
      }
    });
  });
});
