import { Routes } from '@angular/router';
import { guestGuard } from '@core/guards/auth.guard';

export const AUTH_ROUTES: Routes = [
  {
    path: 'login',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./pages/login/login.component').then((m) => m.LoginComponent),
    title: 'Sign In | ArcHub'
  },
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  }
];
