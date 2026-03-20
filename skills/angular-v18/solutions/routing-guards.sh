#!/bin/bash
cat > auth.guard.ts << 'GUARD'
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) {
    return true;
  }

  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url },
  });
};
GUARD

cat > app.routes.ts << 'ROUTES'
import { Routes } from '@angular/router';
import { authGuard } from './auth.guard';
import { NotFoundComponent } from './not-found.component';

export const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  {
    path: 'login',
    loadComponent: () => import('./login.component').then(m => m.LoginComponent),
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./dashboard.component').then(m => m.DashboardComponent),
    canActivate: [authGuard],
  },
  {
    path: 'users/:id',
    loadComponent: () => import('./user-detail.component').then(m => m.UserDetailComponent),
  },
  { path: '**', component: NotFoundComponent },
];
ROUTES

cat > app.config.ts << 'CONFIG'
import { ApplicationConfig } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
  ],
};
CONFIG
