---
name: angular-http
description: Make HTTP requests in Angular v18 using HttpClient with provideHttpClient(), functional interceptors, error handling, and caching. Use when fetching data from APIs, configuring HTTP interceptors, handling errors, or uploading files. Do not use for httpResource() which is not available in v18.
---

# Angular v18 HTTP Client

Use `provideHttpClient()` — the `HttpClientModule` is deprecated in v18.

## Setup

```typescript
// app.config.ts
import { provideHttpClient, withInterceptors, withFetch } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withInterceptors([authInterceptor, loggingInterceptor]),
      withFetch(), // Use fetch API instead of XMLHttpRequest
    ),
  ],
};
```

## Basic CRUD Operations

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private apiUrl = '/api/users';

  getAll(page = 1, limit = 10): Observable<PaginatedResponse<User>> {
    const params = new HttpParams()
      .set('page', page)
      .set('limit', limit);
    return this.http.get<PaginatedResponse<User>>(this.apiUrl, { params });
  }

  getById(id: string): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }

  create(user: CreateUserDto): Observable<User> {
    return this.http.post<User>(this.apiUrl, user);
  }

  update(id: string, user: UpdateUserDto): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/${id}`, user);
  }

  patch(id: string, changes: Partial<User>): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}`, changes);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
```

## Using HttpClient with Signals

```typescript
import { toSignal } from '@angular/core/rxjs-interop';

@Component({
  template: `
    @if (users()) {
      @for (user of users(); track user.id) {
        <app-user-card [user]="user" />
      }
    } @else {
      <app-spinner />
    }
  `,
})
export class UserListComponent {
  private userService = inject(UserService);

  // Convert observable to signal
  users = toSignal(this.userService.getAll());
}
```

## Functional Interceptors

```typescript
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';

// Auth interceptor
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.getToken();

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }

  return next(req);
};

// Logging interceptor
export const loggingInterceptor: HttpInterceptorFn = (req, next) => {
  const startTime = Date.now();

  return next(req).pipe(
    tap({
      next: () => {
        const elapsed = Date.now() - startTime;
        console.log(`${req.method} ${req.url} — ${elapsed}ms`);
      },
    })
  );
};

// Error handling interceptor
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        router.navigate(['/login']);
      }
      if (error.status === 403) {
        router.navigate(['/forbidden']);
      }
      return throwError(() => error);
    })
  );
};

// Retry interceptor
export const retryInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    retry({ count: 2, delay: 1000 }),
  );
};
```

## Error Handling

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);

  getUser(id: string): Observable<User> {
    return this.http.get<User>(`/api/users/${id}`).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 404) {
          return throwError(() => new Error('User not found'));
        }
        if (error.status === 0) {
          return throwError(() => new Error('Network error'));
        }
        return throwError(() => new Error('Server error'));
      })
    );
  }
}

// In component
@Component({...})
export class UserDetailComponent {
  private userService = inject(UserService);

  user = signal<User | null>(null);
  error = signal<string | null>(null);
  loading = signal(false);

  loadUser(id: string) {
    this.loading.set(true);
    this.error.set(null);

    this.userService.getUser(id).subscribe({
      next: (user) => {
        this.user.set(user);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err.message);
        this.loading.set(false);
      },
    });
  }
}
```

## Request Headers and Options

```typescript
import { HttpHeaders, HttpParams, HttpContext, HttpContextToken } from '@angular/common/http';

// Custom headers
const headers = new HttpHeaders()
  .set('Content-Type', 'application/json')
  .set('X-Custom-Header', 'value');

this.http.get<Data>('/api/data', { headers });

// Query params
const params = new HttpParams()
  .set('page', '1')
  .set('sort', 'name')
  .append('filter', 'active');

this.http.get<Data>('/api/data', { params });

// HTTP context tokens (pass metadata to interceptors)
export const SKIP_AUTH = new HttpContextToken<boolean>(() => false);

// Skip auth for specific request
this.http.get('/api/public', {
  context: new HttpContext().set(SKIP_AUTH, true),
});

// Check in interceptor
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (req.context.get(SKIP_AUTH)) {
    return next(req);
  }
  // ... add auth header
};
```

## File Upload

```typescript
upload(file: File): Observable<HttpEvent<UploadResponse>> {
  const formData = new FormData();
  formData.append('file', file);

  return this.http.post<UploadResponse>('/api/upload', formData, {
    reportProgress: true,
    observe: 'events',
  });
}

// Track upload progress
this.userService.upload(file).subscribe(event => {
  if (event.type === HttpEventType.UploadProgress && event.total) {
    const progress = Math.round(100 * event.loaded / event.total);
    this.uploadProgress.set(progress);
  }
  if (event.type === HttpEventType.Response) {
    this.uploadComplete.set(true);
  }
});
```

## Transfer State (SSR Cache)

```typescript
// Automatically caches HTTP responses during SSR
// and reuses them on the client to avoid duplicate requests
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withFetch(),
      withInterceptors([authInterceptor]),
    ),
    provideClientHydration(),
  ],
};
```

For advanced HTTP patterns, see [references/http-patterns.md](references/http-patterns.md).
