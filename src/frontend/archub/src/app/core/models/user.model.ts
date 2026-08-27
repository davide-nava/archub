export interface User {
  readonly id: number | string;
  readonly name: string;
  readonly email: string;
  readonly role: 'admin' | 'manager' | 'employee';
  readonly avatarUrl?: string;
  readonly department?: string;
  readonly jobTitle?: string;
  readonly createdAt?: string;
}

export interface LoginCredentials {
  readonly email: string;
  readonly password: string;
  readonly remember?: boolean;
}

export interface AuthResponse {
  readonly token: string;
  readonly user: User;
  readonly tokenType: 'Bearer';
  readonly expiresIn?: number;
}
