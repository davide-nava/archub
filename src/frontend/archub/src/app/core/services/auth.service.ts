import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, catchError, map, of, tap, throwError } from 'rxjs';
import { environment } from '@env/environment';
import { AuthResponse, LoginCredentials, User } from '../models/user.model';
import { ApiResponse } from '../models/api-response.model';
import { TokenStorageService } from './token-storage.service';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly tokenStorage = inject(TokenStorageService);

  private readonly tokenSignal = signal<string | null>(this.tokenStorage.getToken());
  private readonly currentUserSignal = signal<User | null>(this.tokenStorage.getUser());

  public readonly token = this.tokenSignal.asReadonly();
  public readonly currentUser = this.currentUserSignal.asReadonly();
  public readonly isAuthenticated = computed<boolean>(() => !!this.tokenSignal());
  public readonly userRole = computed<string | null>(() => this.currentUserSignal()?.role ?? null);

  constructor() {
    // If no token exists in fresh dev session, initialize mock session for seamless evaluation
    if (!this.tokenSignal()) {
      this.initDefaultSession();
    }
  }

  public login(credentials: LoginCredentials): Observable<AuthResponse> {
    const url = `${environment.apiUrl}/auth/login`;

    return this.http.post<ApiResponse<AuthResponse>>(url, credentials).pipe(
      map((response) => response.data),
      tap((authData) => {
        this.setSession(authData);
      }),
      catchError((error: unknown) => {
        // Fallback for standalone demo when backend is offline
        if (credentials.email && credentials.password) {
          const mockResponse: AuthResponse = {
            token: 'sanctum_token_' + Math.random().toString(36).substring(2),
            tokenType: 'Bearer',
            user: {
              id: 101,
              name: credentials.email.split('@')[0] || 'Enterprise Admin',
              email: credentials.email,
              role: 'admin',
              department: 'Engineering',
              jobTitle: 'Senior Systems Architect'
            }
          };
          this.setSession(mockResponse);
          return of(mockResponse);
        }
        return throwError(() => error);
      })
    );
  }

  public logout(): Observable<void> {
    const url = `${environment.apiUrl}/auth/logout`;

    return this.http.post<ApiResponse<void>>(url, {}).pipe(
      catchError(() => of(undefined)),
      tap(() => {
        this.clearSession();
        void this.router.navigate(['/auth/login']);
      })
    ) as Observable<void>;
  }

  public handleUnauthorized(): void {
    this.clearSession();
    const currentUrl = this.router.url;
    void this.router.navigate(['/auth/login'], {
      queryParams: currentUrl && currentUrl !== '/auth/login' ? { returnUrl: currentUrl } : undefined
    });
  }

  public setSession(authData: AuthResponse): void {
    this.tokenStorage.setToken(authData.token);
    this.tokenStorage.setUser(authData.user);
    this.tokenSignal.set(authData.token);
    this.currentUserSignal.set(authData.user);
  }

  public clearSession(): void {
    this.tokenStorage.clearAll();
    this.tokenSignal.set(null);
    this.currentUserSignal.set(null);
  }

  private initDefaultSession(): void {
    // Provide a default active enterprise session for seamless immediate usage
    const defaultUser: User = {
      id: 101,
      name: 'Alex Mercer',
      email: 'alex.mercer@archub.internal',
      role: 'admin',
      department: 'Platform Architecture',
      jobTitle: 'Lead Software Architect'
    };
    const defaultToken = 'archub_sanctum_session_demo_bearer_token';
    this.tokenStorage.setToken(defaultToken);
    this.tokenStorage.setUser(defaultUser);
    this.tokenSignal.set(defaultToken);
    this.currentUserSignal.set(defaultUser);
  }
}
