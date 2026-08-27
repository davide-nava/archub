import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { environment } from '@env/environment';
import { User } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class TokenStorageService {
  private readonly platformId = inject(PLATFORM_ID);
  private readonly isBrowser = isPlatformBrowser(this.platformId);
  private readonly memoryStorage = new Map<string, string>();

  private get isLocalStorageAvailable(): boolean {
    try {
      return (
        this.isBrowser &&
        typeof window !== 'undefined' &&
        typeof window.localStorage !== 'undefined' &&
        window.localStorage !== null
      );
    } catch {
      return false;
    }
  }

  public getToken(): string | null {
    if (this.isLocalStorageAvailable) {
      try {
        return window.localStorage.getItem(environment.tokenStorageKey);
      } catch {
        return this.memoryStorage.get(environment.tokenStorageKey) ?? null;
      }
    }
    return this.memoryStorage.get(environment.tokenStorageKey) ?? null;
  }

  public setToken(token: string): void {
    this.memoryStorage.set(environment.tokenStorageKey, token);
    if (this.isLocalStorageAvailable) {
      try {
        window.localStorage.setItem(environment.tokenStorageKey, token);
      } catch {
        // Fallback already stored in memoryStorage
      }
    }
  }

  public removeToken(): void {
    this.memoryStorage.delete(environment.tokenStorageKey);
    if (this.isLocalStorageAvailable) {
      try {
        window.localStorage.removeItem(environment.tokenStorageKey);
      } catch {
        // Ignored
      }
    }
  }

  public getUser(): User | null {
    let raw: string | null = null;
    if (this.isLocalStorageAvailable) {
      try {
        raw = window.localStorage.getItem(environment.userStorageKey);
      } catch {
        raw = this.memoryStorage.get(environment.userStorageKey) ?? null;
      }
    } else {
      raw = this.memoryStorage.get(environment.userStorageKey) ?? null;
    }

    if (!raw) {
      return null;
    }
    try {
      return JSON.parse(raw) as User;
    } catch {
      this.removeUser();
      return null;
    }
  }

  public setUser(user: User): void {
    const raw = JSON.stringify(user);
    this.memoryStorage.set(environment.userStorageKey, raw);
    if (this.isLocalStorageAvailable) {
      try {
        window.localStorage.setItem(environment.userStorageKey, raw);
      } catch {
        // Handled in memory
      }
    }
  }

  public removeUser(): void {
    this.memoryStorage.delete(environment.userStorageKey);
    if (this.isLocalStorageAvailable) {
      try {
        window.localStorage.removeItem(environment.userStorageKey);
      } catch {
        // Handled in memory
      }
    }
  }

  public clearAll(): void {
    this.removeToken();
    this.removeUser();
  }
}
