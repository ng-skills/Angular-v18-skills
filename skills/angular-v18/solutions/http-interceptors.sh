#!/bin/bash
cat > auth.interceptor.ts << 'INTERCEPTOR'
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from './auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).getToken();
  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }
  return next(req);
};
INTERCEPTOR

cat > error.interceptor.ts << 'INTERCEPTOR'
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        router.navigate(['/login']);
      }
      return throwError(() => error);
    })
  );
};
INTERCEPTOR

cat > user.service.ts << 'SERVICE'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

interface User {
  id: string;
  name: string;
  email: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);

  getAll() { return this.http.get<User[]>('/api/users'); }
  getById(id: string) { return this.http.get<User>(`/api/users/${id}`); }
  create(user: Omit<User, 'id'>) { return this.http.post<User>('/api/users', user); }
  update(id: string, user: Partial<User>) { return this.http.put<User>(`/api/users/${id}`, user); }
  delete(id: string) { return this.http.delete<void>(`/api/users/${id}`); }
}
SERVICE
