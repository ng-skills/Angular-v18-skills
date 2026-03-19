---
name: angular-v18
description: Build Angular v18 applications following official best practices. Covers standalone components, signal-based reactivity, dependency injection, routing, forms, HTTP, directives, pipes, testing, SSR, and tooling. Use for any Angular v18 development task. Do not use APIs from Angular 19+ (linkedSignal, resource, httpResource, Signal Forms, Vitest).
---

# Angular v18 Components

All components are standalone by default in Angular v18. Do NOT use NgModules for new code.

## Component Structure

```typescript
import { Component, ChangeDetectionStrategy, input, output, computed } from '@angular/core';

@Component({
  selector: 'app-user-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    'class': 'user-card',
    '[class.active]': 'isActive()',
    '(click)': 'handleClick()',
  },
  template: `
    <img [src]="avatarUrl()" [alt]="name() + ' avatar'" />
    <h2>{{ name() }}</h2>
    @if (showEmail()) {
      <p>{{ email() }}</p>
    }
  `,
  styles: `
    :host { display: block; }
    :host.active { border: 2px solid blue; }
  `,
})
export class UserCardComponent {
  name = input.required<string>();
  email = input<string>('');
  showEmail = input(false);
  isActive = input(false, { transform: booleanAttribute });

  avatarUrl = computed(() => `https://api.example.com/avatar/${this.name()}`);

  selected = output<string>();

  handleClick() {
    this.selected.emit(this.name());
  }
}
```

## Signal Inputs (Developer Preview)

```typescript
import { input, booleanAttribute, numberAttribute } from '@angular/core';

name = input.required<string>();
count = input(0);
label = input<string>();
size = input('medium', { alias: 'buttonSize' });
disabled = input(false, { transform: booleanAttribute });
value = input(0, { transform: numberAttribute });
```

### Decorator-Based Inputs (Stable Alternative)

```typescript
import { Input, booleanAttribute, numberAttribute } from '@angular/core';

@Input({ required: true }) name!: string;
@Input() count = 0;
@Input({ alias: 'buttonSize' }) size = 'medium';
@Input({ transform: booleanAttribute }) disabled = false;
```

## Signal Outputs (Developer Preview)

```typescript
import { output, outputFromObservable } from '@angular/core';

clicked = output<void>();
selected = output<Item>();
valueChange = output<number>({ alias: 'change' });

scroll$ = new Subject<number>();
scrolled = outputFromObservable(this.scroll$);
```

### Decorator-Based Outputs (Stable Alternative)

```typescript
import { Output, EventEmitter } from '@angular/core';

@Output() clicked = new EventEmitter<void>();
@Output('change') valueChange = new EventEmitter<number>();
```

## Two-Way Binding with model() (Developer Preview)

```typescript
import { model } from '@angular/core';

@Component({
  selector: 'app-counter',
  template: `
    <button (click)="decrement()">-</button>
    <span>{{ value() }}</span>
    <button (click)="increment()">+</button>
  `,
})
export class CounterComponent {
  value = model(0);

  increment() { this.value.update(v => v + 1); }
  decrement() { this.value.update(v => v - 1); }
}

// Parent usage: <app-counter [(value)]="count" />
```

## Host Bindings

Use the `host` metadata object — do NOT use `@HostBinding` or `@HostListener` decorators.

```typescript
@Component({
  selector: 'app-button',
  host: {
    'role': 'button',
    '[class.primary]': 'variant() === "primary"',
    '[class.disabled]': 'disabled()',
    '[attr.aria-disabled]': 'disabled()',
    '[attr.tabindex]': 'disabled() ? -1 : 0',
    '(click)': 'onClick($event)',
    '(keydown.enter)': 'onClick($event)',
  },
  template: `<ng-content />`,
})
export class ButtonComponent {
  variant = input<'primary' | 'secondary'>('primary');
  disabled = input(false, { transform: booleanAttribute });
  clicked = output<void>();

  onClick(event: Event) {
    if (!this.disabled()) {
      this.clicked.emit();
    }
  }
}
```

## Template Syntax — Built-in Control Flow

Use native control flow — do NOT use `*ngIf`, `*ngFor`, `*ngSwitch`.

```html
@if (isLoading()) {
  <app-spinner />
} @else if (error()) {
  <app-error [message]="error()" />
} @else {
  <app-content [data]="data()" />
}

@for (item of items(); track item.id) {
  <app-item [item]="item" />
} @empty {
  <p>No items found</p>
}

@switch (status()) {
  @case ('pending') { <span>Pending</span> }
  @case ('active') { <span>Active</span> }
  @default { <span>Unknown</span> }
}
```

## Deferrable Views (@defer) — Stable in v18

```html
@defer (on viewport) {
  <app-heavy-chart [data]="chartData()" />
} @placeholder {
  <div class="chart-placeholder">Chart loading area</div>
} @loading (minimum 300ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart</p>
}

@defer (on idle) { <app-analytics /> }
@defer (on interaction) { <app-comments /> }
@defer (on hover) { <app-preview /> }
@defer (on timer(5s)) { <app-ads /> }
@defer (when isVisible()) { <app-widget /> }
@defer (on viewport; prefetch on idle) { <app-footer /> }
```

## Content Projection

```typescript
@Component({
  selector: 'app-card',
  template: `
    <header>
      <ng-content select="[card-header]" />
    </header>
    <main>
      <ng-content />
    </main>
    <footer>
      <ng-content select="[card-footer]" />
    </footer>
  `,
})
export class CardComponent {}
```

### Fallback Content for ng-content (New in v18)

```html
<ng-content select="[card-header]">
  <h2>Default Title</h2>
</ng-content>
```

## View Queries (Developer Preview)

```typescript
import { viewChild, viewChildren, contentChild, contentChildren } from '@angular/core';

chart = viewChild<ElementRef>('chartCanvas');
header = viewChild.required<ElementRef>('header');
items = viewChildren(ItemComponent);
tabs = contentChildren(TabComponent);
```

## Lifecycle Hooks

```typescript
import { afterNextRender, afterRender } from '@angular/core';

export class MyComponent implements OnInit, OnDestroy {
  constructor() {
    afterNextRender(() => { /* Runs once after first render (SSR-safe) */ });
    afterRender(() => { /* Runs after every render */ });
  }

  ngOnInit() { /* Component initialized */ }
  ngOnDestroy() { /* Cleanup subscriptions, timers */ }
}
```

## Class and Style Bindings

Do NOT use `ngClass` or `ngStyle`. Use direct bindings:

```html
<div [class.active]="isActive()">Single class</div>
<div [style.color]="textColor()">Styled text</div>
<div [style.width.px]="width()">With unit</div>
```

## Images — NgOptimizedImage

```typescript
import { NgOptimizedImage } from '@angular/common';

@Component({
  imports: [NgOptimizedImage],
  template: `<img ngSrc="/assets/hero.jpg" width="800" height="600" priority />`,
})
export class HeroComponent {}
```

## Accessibility

Components MUST include proper ARIA attributes, keyboard navigation, and visible focus indicators.

```typescript
@Component({
  selector: 'app-toggle',
  host: {
    'role': 'switch',
    '[attr.aria-checked]': 'checked()',
    '[attr.aria-label]': 'label()',
    'tabindex': '0',
    '(click)': 'toggle()',
    '(keydown.enter)': 'toggle()',
    '(keydown.space)': 'toggle(); $event.preventDefault()',
  },
  template: `<span class="toggle-track"><span class="toggle-thumb"></span></span>`,
})
export class ToggleComponent {
  label = input.required<string>();
  checked = input(false, { transform: booleanAttribute });
  checkedChange = output<boolean>();

  toggle() {
    this.checkedChange.emit(!this.checked());
  }
}
```

---

# Angular v18 Signals

Signals are Angular's reactive primitive. In v18, `signal()` and `computed()` are **stable**. `effect()` is in **developer preview**.

## signal() — Writable State

```typescript
import { signal } from '@angular/core';

const count = signal(0);
count.set(5);
count.update(c => c + 1);

const user = signal<User | null>(null);
```

## computed() — Derived State

```typescript
import { signal, computed } from '@angular/core';

const firstName = signal('John');
const lastName = signal('Doe');
const fullName = computed(() => `${firstName()} ${lastName()}`);

const items = signal<Item[]>([]);
const filter = signal('');
const filteredItems = computed(() => {
  const query = filter().toLowerCase();
  return items().filter(item => item.name.toLowerCase().includes(query));
});
```

## effect() — Side Effects (Developer Preview)

```typescript
import { signal, effect } from '@angular/core';

@Component({...})
export class SearchComponent {
  query = signal('');

  constructor() {
    effect(() => {
      console.log('Search query:', this.query());
    });

    effect((onCleanup) => {
      const timer = setInterval(() => console.log(this.query()), 1000);
      onCleanup(() => clearInterval(timer));
    });
  }
}
```

**Rules:** Must run in injection context. Do not set signals inside effects unless necessary.

## Signal Equality

```typescript
const user = signal<User>(
  { id: 1, name: 'Alice' },
  { equal: (a, b) => a.id === b.id }
);
```

## untracked()

```typescript
import { untracked } from '@angular/core';

const result = computed(() => {
  const aVal = a();
  const bVal = untracked(() => b());
  return aVal + bVal;
});
```

## Read-Only Signals

```typescript
@Injectable({ providedIn: 'root' })
export class AuthService {
  private _user = signal<User | null>(null);
  readonly user = this._user.asReadonly();
  readonly isAuthenticated = computed(() => this._user() !== null);
}
```

## RxJS Interop

```typescript
import { toSignal } from '@angular/core/rxjs-interop';
import { toObservable } from '@angular/core/rxjs-interop';

// Observable to Signal
counter = toSignal(interval(1000), { initialValue: 0 });
users = toSignal(this.http.get<User[]>('/api/users'));

// Signal to Observable with operators
results = toSignal(
  toObservable(this.query).pipe(
    debounceTime(300),
    switchMap(q => this.http.get<Result[]>(`/api/search?q=${q}`))
  ),
  { initialValue: [] }
);
```

## Service State Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class CartService {
  private _items = signal<CartItem[]>([]);

  readonly items = this._items.asReadonly();
  readonly itemCount = computed(() => this._items().length);
  readonly total = computed(() =>
    this._items().reduce((sum, item) => sum + item.price * item.quantity, 0)
  );

  addItem(product: Product) {
    this._items.update(items => {
      const existing = items.find(i => i.productId === product.id);
      if (existing) {
        return items.map(i =>
          i.productId === product.id ? { ...i, quantity: i.quantity + 1 } : i
        );
      }
      return [...items, { productId: product.id, price: product.price, quantity: 1 }];
    });
  }
}
```

## APIs NOT Available in Angular v18

- `linkedSignal()` — Angular 19+
- `resource()` / `httpResource()` — Angular 19+

Use `toSignal()` with `HttpClient` observables for async data in v18.

---

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

# Angular v18 Routing

## Basic Setup

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: '**', component: NotFoundComponent },
];

// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes)],
};

// app.component.ts
@Component({
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <nav>
      <a routerLink="/home" routerLinkActive="active">Home</a>
    </nav>
    <router-outlet />
  `,
})
export class AppComponent {}
```

## Lazy Loading

```typescript
export const routes: Routes = [
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.adminRoutes),
  },
  {
    path: 'settings',
    loadComponent: () => import('./settings/settings.component').then(m => m.SettingsComponent),
  },
];
```

## Route Parameters with Signal Inputs

```typescript
// app.config.ts
provideRouter(routes, withComponentInputBinding())

// Route: { path: 'users/:id', component: UserDetailComponent }
@Component({...})
export class UserDetailComponent {
  id = input.required<string>();
  userId = computed(() => parseInt(this.id(), 10));
}
```

## Route Redirects as Functions (New in v18)

```typescript
{
  path: 'legacy-path',
  redirectTo: ({ queryParams }) => {
    const id = queryParams['id'];
    return id ? `/new-path/${id}` : '/new-path';
  },
}
```

## Functional Guards

```typescript
export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) return true;
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url },
  });
};

// Factory pattern
export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return () => {
    const auth = inject(AuthService);
    return allowedRoles.includes(auth.currentUser()?.role ?? '');
  };
};
```

## Resolvers

```typescript
export const userResolver: ResolveFn<User> = (route) => {
  return inject(UserService).getById(route.paramMap.get('id')!);
};

{ path: 'users/:id', component: UserDetailComponent, resolve: { user: userResolver } }
```

---

# Angular v18 Forms

Signal Forms are NOT available in v18.

## Reactive Forms

```typescript
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';

@Component({
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <input formControlName="email" type="email" />
      @if (form.controls.email.hasError('required') && form.controls.email.touched) {
        <span class="error">Email is required</span>
      }
      <button type="submit" [disabled]="form.invalid">Login</button>
    </form>
  `,
})
export class LoginComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  onSubmit() {
    if (this.form.valid) {
      const { email, password } = this.form.getRawValue();
    }
  }
}
```

## Typed Forms

```typescript
// Non-nullable form builder
const form = this.fb.nonNullable.group({
  name: [''],        // FormControl<string>
  age: [0],          // FormControl<number>
  active: [false],   // FormControl<boolean>
});
```

## Custom Validators

```typescript
export function passwordStrengthValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value = control.value;
    if (!value) return null;
    const valid = /[A-Z]/.test(value) && /[a-z]/.test(value) && /[0-9]/.test(value);
    return valid ? null : { passwordStrength: true };
  };
}
```

## Form Events (New in v18)

```typescript
this.form.events.subscribe(event => {
  if (event instanceof ValueChangeEvent) { /* ... */ }
  if (event instanceof StatusChangeEvent) { /* ... */ }
});
```

---

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

# Angular v18 Directives

All directives are standalone by default. Use `host` metadata for bindings.

## Attribute Directive

```typescript
@Directive({
  selector: '[appHighlight]',
  host: {
    '(mouseenter)': 'onMouseEnter()',
    '(mouseleave)': 'onMouseLeave()',
  },
})
export class HighlightDirective {
  appHighlight = input('yellow');
  private el = inject(ElementRef);

  onMouseEnter() { this.el.nativeElement.style.backgroundColor = this.appHighlight(); }
  onMouseLeave() { this.el.nativeElement.style.backgroundColor = ''; }
}
```

## Structural Directive

```typescript
@Directive({ selector: '[appPermission]' })
export class PermissionDirective {
  appPermission = input.required<string>();
  private templateRef = inject(TemplateRef);
  private viewContainer = inject(ViewContainerRef);
  private auth = inject(AuthService);

  constructor() {
    effect(() => {
      if (this.auth.hasPermission(this.appPermission())) {
        this.viewContainer.createEmbeddedView(this.templateRef);
      } else {
        this.viewContainer.clear();
      }
    });
  }
}
```

## Directive Composition API

```typescript
@Component({
  selector: 'app-chip',
  hostDirectives: [
    FocusableDirective,
    { directive: DisableableDirective, inputs: ['disabled'] },
  ],
  template: `<ng-content />`,
})
export class ChipComponent {}
```

---

# Angular v18 Pipes

Pipes transform data in templates. All custom pipes are standalone by default.

## Built-in Pipes

```typescript
import { DatePipe, CurrencyPipe, DecimalPipe, PercentPipe, AsyncPipe } from '@angular/common';

// {{ createdAt | date:'short' }}
// {{ price | currency:'EUR' }}
// {{ value | number:'1.2-2' }}
// {{ ratio | percent }}
// {{ users$ | async }}
```

**Tip:** Prefer `toSignal()` over `AsyncPipe` when working with signals.

## Custom Pipe

```typescript
@Pipe({ name: 'truncate' })
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit = 50, trail = '...'): string {
    if (!value || value.length <= limit) return value || '';
    return value.substring(0, limit).trim() + trail;
  }
}
```

## Pipes vs Computed Signals

Prefer `computed()` for component-specific transformations. Use pipes for generic, reusable template formatting.

---

# Angular v18 Testing

Jasmine + Karma by default. All test patterns use standalone components.

## Component Testing

```typescript
describe('UserCardComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
    }).compileComponents();
  });

  it('should display user name', () => {
    const fixture = TestBed.createComponent(UserCardComponent);
    fixture.componentRef.setInput('name', 'Alice');
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('h2').textContent).toContain('Alice');
  });
});
```

## Service Testing with HTTP Mocking

```typescript
describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('should fetch users', () => {
    service.getAll().subscribe(users => expect(users.length).toBe(2));
    httpMock.expectOne('/api/users?page=1&limit=10').flush({ data: [{}, {}], total: 2 });
  });
});
```

## Testing Guards

```typescript
it('should allow authenticated users', () => {
  authService.isAuthenticated.and.returnValue(true);
  const result = TestBed.runInInjectionContext(() =>
    authGuard({} as any, { url: '/dashboard' } as any)
  );
  expect(result).toBeTrue();
});
```

---

# Angular v18 Server-Side Rendering

## Setup

```bash
ng new my-app --ssr
ng add @angular/ssr
```

## App Configuration

```typescript
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()),
    provideClientHydration(withEventReplay()),
  ],
};
```

## SSR-Safe DOM Access

Never access DOM APIs directly. Use `afterNextRender` and `afterRender`.

```typescript
@Component({...})
export class MapComponent {
  private platformId = inject(PLATFORM_ID);

  constructor() {
    afterNextRender(() => { this.initializeMap(); });
  }

  doSomething() {
    if (isPlatformBrowser(this.platformId)) {
      window.scrollTo(0, 0);
    }
  }
}
```

## Skip Hydration

```typescript
@Component({
  host: { 'ngSkipHydration': '' },
})
export class ChartComponent {}
// Or: <app-chart ngSkipHydration />
```

## Transfer State

HTTP responses are automatically cached during SSR with `provideHttpClient()` + `provideClientHydration()`.

---

# Angular v18 Tooling

## Project Generation

```bash
ng new my-app
ng new my-app --ssr --style=scss --prefix=acme

ng generate component features/user-card
ng generate service core/auth
ng generate pipe shared/truncate
ng generate guard core/auth
```

## Application Builder (Default in v18)

Uses esbuild + Vite for faster builds.

```json
{
  "builder": "@angular-devkit/build-angular:application",
  "options": {
    "outputPath": "dist/my-app",
    "index": "src/index.html",
    "browser": "src/main.ts",
    "polyfills": ["zone.js"]
  }
}
```

## Project Structure

```
src/app/
├── core/          # Singleton services, guards, interceptors
├── shared/        # Reusable components, directives, pipes
├── features/      # Feature modules / route-based sections
├── models/        # Interfaces and types
├── app.component.ts
├── app.config.ts
└── app.routes.ts
```

## Migration Commands

```bash
ng update @angular/cli --migrate-only use-application-builder
ng generate @angular/core:standalone
ng generate @angular/core:control-flow
ng generate @angular/core:signal-input-migration
```

For advanced patterns, see [references/patterns.md](references/patterns.md).
