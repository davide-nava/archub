import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { AuthService } from './auth.service';
import { TokenStorageService } from './token-storage.service';

describe('AuthService', () => {
  let service: AuthService;
  let tokenStorage: TokenStorageService;
  let httpTestingController: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AuthService,
        TokenStorageService,
        provideRouter([]),
        provideHttpClient(),
        provideHttpClientTesting()
      ]
    });

    service = TestBed.inject(AuthService);
    tokenStorage = TestBed.inject(TokenStorageService);
    httpTestingController = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpTestingController.verify();
  });

  it('should maintain reactive signals for authentication state', () => {
    service.setSession({
      token: 'jwt_sanctum_abc',
      tokenType: 'Bearer',
      user: {
        id: 1,
        name: 'Jane Doe',
        email: 'jane@archub.internal',
        role: 'manager'
      }
    });

    expect(service.isAuthenticated()).toBe(true);
    expect(service.token()).toBe('jwt_sanctum_abc');
    expect(service.currentUser()?.name).toBe('Jane Doe');
    expect(service.userRole()).toBe('manager');

    service.clearSession();
    expect(service.isAuthenticated()).toBe(false);
    expect(service.token()).toBeNull();
    expect(service.currentUser()).toBeNull();
  });
});
