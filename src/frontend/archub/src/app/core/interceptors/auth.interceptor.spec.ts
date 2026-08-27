import { TestBed } from '@angular/core/testing';
import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { authInterceptor } from './auth.interceptor';
import { AuthService } from '../services/auth.service';

describe('authInterceptor', () => {
  let httpClient: HttpClient;
  let httpTestingController: HttpTestingController;
  let authService: AuthService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([
          { path: 'auth/login', component: class {} }
        ]),
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting()
      ]
    });

    httpClient = TestBed.inject(HttpClient);
    httpTestingController = TestBed.inject(HttpTestingController);
    authService = TestBed.inject(AuthService);
  });

  afterEach(() => {
    httpTestingController.verify();
  });

  it('should inject Authorization Bearer header when token exists', () => {
    authService.setSession({
      token: 'test_sanctum_bearer_token',
      tokenType: 'Bearer',
      user: {
        id: 1,
        name: 'Test User',
        email: 'test@archub.internal',
        role: 'employee'
      }
    });

    httpClient.get('/api/v1/test-resource').subscribe();

    const req = httpTestingController.expectOne('/api/v1/test-resource');
    expect(req.request.headers.get('Authorization')).toBe('Bearer test_sanctum_bearer_token');
    expect(req.request.headers.get('Accept')).toBe('application/json');
    req.flush({});
  });

  it('should trigger handleUnauthorized when 401 response is returned', () => {
    const unauthorizedSpy = vi.spyOn(authService, 'handleUnauthorized');

    httpClient.get('/api/v1/secure-data').subscribe({
      error: () => {
        // Expected error response
      }
    });

    const req = httpTestingController.expectOne('/api/v1/secure-data');
    req.flush({ message: 'Unauthenticated.' }, { status: 401, statusText: 'Unauthorized' });

    expect(unauthorizedSpy).toHaveBeenCalled();
  });
});
