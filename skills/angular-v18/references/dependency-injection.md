# Angular v18 Dependency Injection

Use the `inject()` function. Avoid constructor-based injection for new code.

## inject() Function

```typescript
import { Component, inject } from '@angular/core';

@Component({...})
export class UserDetailComponent {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
}
```

## Service Registration

```typescript
// Root-level singleton
@Injectable({ providedIn: 'root' })
export class AuthService { }

// Component-level (per instance)
@Component({
  providers: [FormValidationService],
})
export class FormComponent {
  private validator = inject(FormValidationService);
}
```

## InjectionToken

```typescript
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL', {
  providedIn: 'root',
  factory: () => 'https://api.example.com',
});

export const FEATURE_FLAGS = new InjectionToken<FeatureFlags>('FEATURE_FLAGS');

// Provide in app config
export const appConfig: ApplicationConfig = {
  providers: [
    { provide: API_BASE_URL, useValue: 'https://api.prod.example.com' },
  ],
};
```

## Provider Types

```typescript
providers: [
  { provide: Logger, useClass: ConsoleLogger },
  { provide: API_URL, useValue: 'https://api.example.com' },
  {
    provide: DataService,
    useFactory: () => {
      const http = inject(HttpClient);
      return new DataService(http);
    },
  },
  { provide: AbstractLogger, useExisting: ConsoleLogger },
]
```

## Optional and Self Injection

```typescript
private analytics = inject(AnalyticsService, { optional: true });
private config = inject(CONFIG_TOKEN, { self: true });
private parentConfig = inject(CONFIG_TOKEN, { skipSelf: true });
```

## Application Config Pattern

```typescript
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimationsAsync(),
  ],
};

// main.ts
bootstrapApplication(AppComponent, appConfig);
```

---

## DI Patterns

### Multi-Provider Pattern

```typescript
export const VALIDATORS = new InjectionToken<Validator[]>('VALIDATORS');

providers: [
  { provide: VALIDATORS, useClass: RequiredValidator, multi: true },
  { provide: VALIDATORS, useClass: EmailValidator, multi: true },
]
```

### Scoped Services

```typescript
@Injectable()
export class FormStateService {
  dirty = signal(false);
  submitted = signal(false);
}

@Component({
  providers: [FormStateService], // Each instance gets its own
})
export class FormComponent {
  state = inject(FormStateService);
}
```

### Abstract Class as DI Token

```typescript
export abstract class CacheService {
  abstract get<T>(key: string): T | null;
  abstract set<T>(key: string, value: T, ttl?: number): void;
}

providers: [{ provide: CacheService, useClass: LocalStorageCacheService }]
```

### runInInjectionContext

```typescript
@Component({...})
export class MyComponent {
  private injector = inject(Injector);

  loadData() {
    runInInjectionContext(this.injector, () => {
      const http = inject(HttpClient);
      http.get('/api/data').subscribe(console.log);
    });
  }
}
```
