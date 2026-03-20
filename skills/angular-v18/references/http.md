# Angular v18 HTTP Client

Use `provideHttpClient()` — `HttpClientModule` is deprecated.

## Setup

```typescript
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withInterceptors([authInterceptor, loggingInterceptor]),
      withFetch(),
    ),
  ],
};
```

## Basic CRUD

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);

  getAll(page = 1, limit = 10) {
    const params = new HttpParams().set('page', page).set('limit', limit);
    return this.http.get<PaginatedResponse<User>>('/api/users', { params });
  }

  getById(id: string) { return this.http.get<User>(`/api/users/${id}`); }
  create(user: CreateUserDto) { return this.http.post<User>('/api/users', user); }
  update(id: string, user: UpdateUserDto) { return this.http.put<User>(`/api/users/${id}`, user); }
  delete(id: string) { return this.http.delete<void>(`/api/users/${id}`); }
}
```

## Functional Interceptors

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).getToken();
  if (token) {
    req = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
  }
  return next(req);
};

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) inject(Router).navigate(['/login']);
      return throwError(() => error);
    })
  );
};
```

## HTTP Context Tokens

```typescript
export const SKIP_AUTH = new HttpContextToken<boolean>(() => false);

this.http.get('/api/public', {
  context: new HttpContext().set(SKIP_AUTH, true),
});
```

---

## HTTP Patterns

### Generic CRUD Service

```typescript
@Injectable()
export abstract class CrudService<T extends { id: string }> {
  protected http = inject(HttpClient);
  protected abstract baseUrl: string;

  getAll(params?: Record<string, string>) { return this.http.get<T[]>(this.baseUrl, { params: params ? new HttpParams({ fromObject: params }) : undefined }); }
  getById(id: string) { return this.http.get<T>(`${this.baseUrl}/${id}`); }
  create(item: Omit<T, 'id'>) { return this.http.post<T>(this.baseUrl, item); }
  update(id: string, item: Partial<T>) { return this.http.put<T>(`${this.baseUrl}/${id}`, item); }
  delete(id: string) { return this.http.delete<void>(`${this.baseUrl}/${id}`); }
}
```

### Caching Interceptor

```typescript
export const CACHE_TTL = new HttpContextToken<number>(() => 0);

export const cachingInterceptor: HttpInterceptorFn = (req, next) => {
  const ttl = req.context.get(CACHE_TTL);
  if (req.method !== 'GET' || ttl === 0) return next(req);

  const cached = requestCache.get(req.urlWithParams);
  if (cached && Date.now() - cached.timestamp < ttl) return of(cached.response.clone());

  return next(req).pipe(
    tap(event => {
      if (event instanceof HttpResponse) {
        requestCache.set(req.urlWithParams, { response: event.clone(), timestamp: Date.now() });
      }
    })
  );
};
```

### Retry with Exponential Backoff

```typescript
export const retryInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    retry({
      count: 3,
      delay: (error, retryCount) => {
        if (error.status >= 400 && error.status < 500) throw error;
        return timer(Math.pow(2, retryCount) * 1000);
      },
    })
  );
};
```

### Polling Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class NotificationService {
  private http = inject(HttpClient);
  private destroyRef = inject(DestroyRef);
  notifications = signal<Notification[]>([]);

  startPolling(intervalMs = 30_000) {
    timer(0, intervalMs).pipe(
      switchMap(() => this.http.get<Notification[]>('/api/notifications')),
      takeUntilDestroyed(this.destroyRef),
    ).subscribe(n => this.notifications.set(n));
  }
}
```
