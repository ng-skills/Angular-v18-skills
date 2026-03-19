# Advanced Dependency Injection Patterns — Angular v18

## Multi-Provider Pattern

```typescript
import { InjectionToken } from '@angular/core';

export const VALIDATORS = new InjectionToken<Validator[]>('VALIDATORS');

// Register multiple validators
providers: [
  { provide: VALIDATORS, useClass: RequiredValidator, multi: true },
  { provide: VALIDATORS, useClass: EmailValidator, multi: true },
  { provide: VALIDATORS, useClass: MinLengthValidator, multi: true },
]

// Inject all
@Injectable()
export class FormValidationService {
  private validators = inject(VALIDATORS);

  validate(value: unknown): ValidationError[] {
    return this.validators.flatMap(v => v.validate(value));
  }
}
```

## Factory Provider with Dependencies

```typescript
export const APP_CONFIG = new InjectionToken<AppConfig>('APP_CONFIG', {
  providedIn: 'root',
  factory: () => {
    const platformId = inject(PLATFORM_ID);
    const isProd = inject(IS_PRODUCTION, { optional: true }) ?? false;

    return {
      apiUrl: isProd ? 'https://api.prod.com' : 'https://api.dev.com',
      isBrowser: isPlatformBrowser(platformId),
      logLevel: isProd ? 'error' : 'debug',
    };
  },
});
```

## Scoped Services with Component Providers

```typescript
// Each FormComponent instance gets its own FormStateService
@Injectable()
export class FormStateService {
  dirty = signal(false);
  submitted = signal(false);
  values = signal<Record<string, any>>({});

  markDirty() { this.dirty.set(true); }
  submit() { this.submitted.set(true); }
}

@Component({
  selector: 'app-form',
  providers: [FormStateService],
  template: `
    <form (ngSubmit)="onSubmit()">
      <ng-content />
      <button type="submit" [disabled]="state.submitted()">Submit</button>
    </form>
  `,
})
export class FormComponent {
  state = inject(FormStateService);

  onSubmit() {
    this.state.submit();
  }
}

// Child components get the same instance
@Component({
  selector: 'app-form-field',
  template: `<input (input)="onChange()" />`,
})
export class FormFieldComponent {
  private state = inject(FormStateService);

  onChange() {
    this.state.markDirty();
  }
}
```

## Abstract Class as Interface

```typescript
// Use abstract class (not interface) for DI tokens
export abstract class CacheService {
  abstract get<T>(key: string): T | null;
  abstract set<T>(key: string, value: T, ttl?: number): void;
  abstract delete(key: string): void;
  abstract clear(): void;
}

@Injectable()
export class LocalStorageCacheService extends CacheService {
  get<T>(key: string): T | null {
    const item = localStorage.getItem(key);
    if (!item) return null;
    const { value, expiry } = JSON.parse(item);
    if (expiry && Date.now() > expiry) {
      localStorage.removeItem(key);
      return null;
    }
    return value;
  }

  set<T>(key: string, value: T, ttl?: number): void {
    const expiry = ttl ? Date.now() + ttl : null;
    localStorage.setItem(key, JSON.stringify({ value, expiry }));
  }

  delete(key: string): void { localStorage.removeItem(key); }
  clear(): void { localStorage.clear(); }
}

@Injectable()
export class InMemoryCacheService extends CacheService {
  private cache = new Map<string, { value: any; expiry: number | null }>();

  get<T>(key: string): T | null {
    const item = this.cache.get(key);
    if (!item) return null;
    if (item.expiry && Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }
    return item.value;
  }

  set<T>(key: string, value: T, ttl?: number): void {
    this.cache.set(key, { value, expiry: ttl ? Date.now() + ttl : null });
  }

  delete(key: string): void { this.cache.delete(key); }
  clear(): void { this.cache.clear(); }
}

// Provide implementation
providers: [
  { provide: CacheService, useClass: LocalStorageCacheService },
]
```

## runInInjectionContext

```typescript
import { runInInjectionContext, Injector, inject } from '@angular/core';

@Component({...})
export class MyComponent {
  private injector = inject(Injector);

  loadData() {
    // Run code that needs inject() outside of constructor
    runInInjectionContext(this.injector, () => {
      const http = inject(HttpClient);
      http.get('/api/data').subscribe(console.log);
    });
  }
}
```

## Testing with Override Providers

```typescript
describe('UserComponent', () => {
  it('should use mock service', async () => {
    const mockUserService = {
      getAll: () => of([{ id: '1', name: 'Test' }]),
    };

    await TestBed.configureTestingModule({
      imports: [UserComponent],
      providers: [
        { provide: UserService, useValue: mockUserService },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(UserComponent);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Test');
  });
});
```
