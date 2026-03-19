# Advanced HTTP Patterns — Angular v18

## Generic CRUD Service

```typescript
@Injectable()
export abstract class CrudService<T extends { id: string }> {
  protected http = inject(HttpClient);
  protected abstract baseUrl: string;

  getAll(params?: Record<string, string>): Observable<T[]> {
    return this.http.get<T[]>(this.baseUrl, {
      params: params ? new HttpParams({ fromObject: params }) : undefined,
    });
  }

  getById(id: string): Observable<T> {
    return this.http.get<T>(`${this.baseUrl}/${id}`);
  }

  create(item: Omit<T, 'id'>): Observable<T> {
    return this.http.post<T>(this.baseUrl, item);
  }

  update(id: string, item: Partial<T>): Observable<T> {
    return this.http.put<T>(`${this.baseUrl}/${id}`, item);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}

// Concrete service
@Injectable({ providedIn: 'root' })
export class ProductService extends CrudService<Product> {
  protected baseUrl = '/api/products';

  getByCategory(category: string): Observable<Product[]> {
    return this.getAll({ category });
  }
}
```

## Caching Interceptor

```typescript
export const CACHE_TTL = new HttpContextToken<number>(() => 0);

export const cachingInterceptor: HttpInterceptorFn = (req, next) => {
  const ttl = req.context.get(CACHE_TTL);

  if (req.method !== 'GET' || ttl === 0) {
    return next(req);
  }

  const cached = requestCache.get(req.urlWithParams);
  if (cached && Date.now() - cached.timestamp < ttl) {
    return of(cached.response.clone());
  }

  return next(req).pipe(
    tap(event => {
      if (event instanceof HttpResponse) {
        requestCache.set(req.urlWithParams, {
          response: event.clone(),
          timestamp: Date.now(),
        });
      }
    })
  );
};

const requestCache = new Map<string, { response: HttpResponse<any>; timestamp: number }>();

// Usage
this.http.get('/api/config', {
  context: new HttpContext().set(CACHE_TTL, 60_000), // Cache for 1 minute
});
```

## Retry with Exponential Backoff

```typescript
import { retry, timer } from 'rxjs';

export const retryInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    retry({
      count: 3,
      delay: (error, retryCount) => {
        // Only retry on server errors or network errors
        if (error.status >= 400 && error.status < 500) {
          throw error; // Don't retry client errors
        }
        const delayMs = Math.pow(2, retryCount) * 1000;
        return timer(delayMs);
      },
    })
  );
};
```

## Request Deduplication

```typescript
@Injectable({ providedIn: 'root' })
export class DeduplicatedHttpService {
  private http = inject(HttpClient);
  private inFlight = new Map<string, Observable<any>>();

  get<T>(url: string): Observable<T> {
    const existing = this.inFlight.get(url);
    if (existing) {
      return existing as Observable<T>;
    }

    const request = this.http.get<T>(url).pipe(
      shareReplay(1),
      finalize(() => this.inFlight.delete(url))
    );

    this.inFlight.set(url, request);
    return request;
  }
}
```

## Loading State Pattern with Signals

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);

  private _users = signal<User[]>([]);
  private _loading = signal(false);
  private _error = signal<string | null>(null);

  readonly users = this._users.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  loadUsers(): void {
    this._loading.set(true);
    this._error.set(null);

    this.http.get<User[]>('/api/users').subscribe({
      next: (users) => {
        this._users.set(users);
        this._loading.set(false);
      },
      error: (err) => {
        this._error.set(err.message);
        this._loading.set(false);
      },
    });
  }
}
```

## Polling Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class NotificationService {
  private http = inject(HttpClient);
  private destroyRef = inject(DestroyRef);

  notifications = signal<Notification[]>([]);

  startPolling(intervalMs = 30_000): void {
    timer(0, intervalMs).pipe(
      switchMap(() => this.http.get<Notification[]>('/api/notifications')),
      takeUntilDestroyed(this.destroyRef),
    ).subscribe(notifications => {
      this.notifications.set(notifications);
    });
  }
}
```

## Typed Response Handling

```typescript
// Handle different response types
@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);

  // Get full response (headers, status)
  getWithHeaders<T>(url: string): Observable<{ data: T; etag: string | null }> {
    return this.http.get<T>(url, { observe: 'response' }).pipe(
      map(response => ({
        data: response.body!,
        etag: response.headers.get('ETag'),
      }))
    );
  }

  // Download file
  downloadFile(url: string): Observable<Blob> {
    return this.http.get(url, { responseType: 'blob' });
  }

  // Get text response
  getText(url: string): Observable<string> {
    return this.http.get(url, { responseType: 'text' });
  }
}
```
