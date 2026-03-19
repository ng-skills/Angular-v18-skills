# Advanced Angular v18 Patterns

## Component Patterns

### Container/Presentational Pattern

```typescript
// Container — handles data and logic
@Component({
  selector: 'app-user-list-page',
  imports: [UserListComponent],
  template: `
    @if (loading()) {
      <app-spinner />
    } @else {
      <app-user-list [users]="users()" (userSelected)="onUserSelected($event)" />
    }
  `,
})
export class UserListPageComponent {
  private userService = inject(UserService);
  private router = inject(Router);
  users = toSignal(this.userService.getAll(), { initialValue: [] });
  loading = signal(true);

  constructor() {
    effect(() => { if (this.users().length >= 0) this.loading.set(false); });
  }

  onUserSelected(user: User) { this.router.navigate(['/users', user.id]); }
}

// Presentational — pure display
@Component({
  selector: 'app-user-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @for (user of users(); track user.id) {
      <div (click)="userSelected.emit(user)">{{ user.name }}</div>
    } @empty { <p>No users found</p> }
  `,
})
export class UserListComponent {
  users = input.required<User[]>();
  userSelected = output<User>();
}
```

### Dialog/Modal Component

```typescript
@Component({
  selector: 'app-confirm-dialog',
  host: {
    'role': 'dialog',
    '[attr.aria-modal]': 'true',
    '(keydown.escape)': 'onCancel()',
  },
  template: `
    <div class="overlay" (click)="onCancel()"></div>
    <div class="dialog">
      <h2>{{ title() }}</h2>
      <p>{{ message() }}</p>
      <button (click)="onCancel()">Cancel</button>
      <button (click)="onConfirm()">{{ confirmText() }}</button>
    </div>
  `,
})
export class ConfirmDialogComponent {
  title = input('Confirm');
  message = input.required<string>();
  confirmText = input('Confirm');
  confirmed = output<void>();
  cancelled = output<void>();

  onConfirm() { this.confirmed.emit(); }
  onCancel() { this.cancelled.emit(); }
}
```

### Component with Animations

```typescript
import { trigger, transition, style, animate } from '@angular/animations';

@Component({
  animations: [
    trigger('expand', [
      transition(':enter', [
        style({ height: '0', opacity: 0 }),
        animate('200ms ease-out', style({ height: '*', opacity: 1 })),
      ]),
      transition(':leave', [
        animate('200ms ease-in', style({ height: '0', opacity: 0 })),
      ]),
    ]),
  ],
  template: `
    @if (expanded()) { <div @expand><ng-content /></div> }
  `,
})
export class ExpandableComponent {
  expanded = signal(false);
}
```

### Generic Data Table

```typescript
@Component({
  selector: 'app-data-table',
  template: `
    <table>
      <thead><tr>
        @for (col of columns(); track col.key) {
          <th (click)="sortBy(col.key)">{{ col.label }}</th>
        }
      </tr></thead>
      <tbody>
        @for (row of sortedData(); track trackBy()(row)) {
          <tr (click)="rowClicked.emit(row)">
            @for (col of columns(); track col.key) { <td>{{ row[col.key] }}</td> }
          </tr>
        } @empty { <tr><td [attr.colspan]="columns().length">No data</td></tr> }
      </tbody>
    </table>
  `,
})
export class DataTableComponent<T extends Record<string, any>> {
  data = input.required<T[]>();
  columns = input.required<{ key: string; label: string }[]>();
  trackBy = input<(item: T) => any>(() => (item: T) => item);
  rowClicked = output<T>();

  sortColumn = signal<string | null>(null);
  sortDirection = signal<'asc' | 'desc'>('asc');

  sortedData = computed(() => {
    const col = this.sortColumn();
    if (!col) return this.data();
    const dir = this.sortDirection();
    return [...this.data()].sort((a, b) => {
      const cmp = a[col] < b[col] ? -1 : a[col] > b[col] ? 1 : 0;
      return dir === 'asc' ? cmp : -cmp;
    });
  });

  sortBy(column: string) {
    if (this.sortColumn() === column) {
      this.sortDirection.update(d => d === 'asc' ? 'desc' : 'asc');
    } else {
      this.sortColumn.set(column);
      this.sortDirection.set('asc');
    }
  }
}
```

---

## Signal Patterns

### State Machine with Signals

```typescript
type LoadingState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };

@Injectable({ providedIn: 'root' })
export class UserStore {
  private _state = signal<LoadingState<User[]>>({ status: 'idle' });
  private http = inject(HttpClient);

  readonly users = computed(() => {
    const s = this._state();
    return s.status === 'success' ? s.data : [];
  });
  readonly isLoading = computed(() => this._state().status === 'loading');
  readonly error = computed(() => {
    const s = this._state();
    return s.status === 'error' ? s.error : null;
  });

  load() {
    this._state.set({ status: 'loading' });
    this.http.get<User[]>('/api/users').subscribe({
      next: (data) => this._state.set({ status: 'success', data }),
      error: (err) => this._state.set({ status: 'error', error: err.message }),
    });
  }
}
```

### Signal-Based Store

```typescript
@Injectable({ providedIn: 'root' })
export class AppStore {
  private _state = signal<AppState>({ user: null, theme: 'light', notifications: [] });

  readonly user = computed(() => this._state().user);
  readonly theme = computed(() => this._state().theme);
  readonly unreadCount = computed(() =>
    this._state().notifications.filter(n => !n.read).length
  );

  setUser(user: User | null) { this._state.update(s => ({ ...s, user })); }
  toggleTheme() {
    this._state.update(s => ({ ...s, theme: s.theme === 'light' ? 'dark' : 'light' }));
  }
}
```

### Debounced Signal

```typescript
function debouncedSignal<T>(source: Signal<T>, debounceMs: number): Signal<T> {
  return toSignal(
    toObservable(source).pipe(debounceTime(debounceMs)),
    { initialValue: source() }
  );
}
```

### Persisted Signal

```typescript
function persistedSignal<T>(key: string, initialValue: T): WritableSignal<T> {
  const stored = localStorage.getItem(key);
  const sig = signal<T>(stored ? JSON.parse(stored) : initialValue);
  effect(() => { localStorage.setItem(key, JSON.stringify(sig())); });
  return sig;
}
```

### Pagination with Signals

```typescript
@Component({...})
export class PaginatedListComponent {
  private http = inject(HttpClient);
  page = signal(1);
  pageSize = signal(10);
  totalItems = signal(0);
  totalPages = computed(() => Math.ceil(this.totalItems() / this.pageSize()));

  items = toSignal(
    toObservable(computed(() => ({ page: this.page(), pageSize: this.pageSize() }))).pipe(
      switchMap(({ page, pageSize }) =>
        this.http.get<PaginatedResponse<Item>>('/api/items', { params: { page, limit: pageSize } })
      ),
      tap(response => this.totalItems.set(response.total)),
      map(response => response.data),
    ),
    { initialValue: [] }
  );
}
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

---

## Routing Patterns

### Feature Route Organization

```typescript
export const adminRoutes: Routes = [
  {
    path: '',
    component: AdminLayoutComponent,
    canActivate: [authGuard, roleGuard(['admin'])],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: AdminDashboardComponent },
      { path: 'users/:id', component: UserDetailComponent, resolve: { user: userResolver } },
    ],
  },
];
```

### View Transitions (New in v18)

```typescript
provideRouter(routes, withViewTransitions(), withComponentInputBinding())
```

### Title Strategy

```typescript
@Injectable()
export class AppTitleStrategy extends TitleStrategy {
  override updateTitle(routerState: RouterStateSnapshot): void {
    const title = this.buildTitle(routerState);
    document.title = title ? `${title} | My App` : 'My App';
  }
}

providers: [{ provide: TitleStrategy, useClass: AppTitleStrategy }]
```

### Preloading Strategies

```typescript
provideRouter(routes, withPreloading(PreloadAllModules))
```

### Error Handling with Router

```typescript
provideRouter(
  routes,
  withNavigationErrorHandler((error) => {
    inject(Router).navigate(['/error'], { queryParams: { message: error.message } });
  })
)
```

---

## Form Patterns

### ControlValueAccessor

```typescript
@Component({
  selector: 'app-star-rating',
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: StarRatingComponent, multi: true }],
  template: `
    @for (star of stars(); track $index) {
      <button type="button" [class.filled]="$index < value()" (click)="selectStar($index + 1)">★</button>
    }
  `,
})
export class StarRatingComponent implements ControlValueAccessor {
  max = input(5);
  value = signal(0);
  disabled = signal(false);
  stars = computed(() => Array.from({ length: this.max() }));
  private onChange: (value: number) => void = () => {};
  private onTouched: () => void = () => {};

  writeValue(value: number) { this.value.set(value || 0); }
  registerOnChange(fn: (value: number) => void) { this.onChange = fn; }
  registerOnTouched(fn: () => void) { this.onTouched = fn; }
  setDisabledState(d: boolean) { this.disabled.set(d); }
  selectStar(rating: number) { this.value.set(rating); this.onChange(rating); this.onTouched(); }
}
```

### Multi-Step Form (Wizard)

```typescript
@Component({
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      @switch (currentStep()) {
        @case (0) { <div formGroupName="personal">...</div> }
        @case (1) { <div formGroupName="address">...</div> }
        @case (2) { <div formGroupName="account">...</div> }
      }
      @if (currentStep() > 0) { <button type="button" (click)="prev()">Back</button> }
      @if (currentStep() < 2) {
        <button type="button" (click)="next()" [disabled]="!isCurrentStepValid()">Next</button>
      } @else {
        <button type="submit" [disabled]="form.invalid">Submit</button>
      }
    </form>
  `,
})
export class RegistrationWizardComponent {
  private fb = inject(FormBuilder);
  currentStep = signal(0);
  form = this.fb.nonNullable.group({
    personal: this.fb.nonNullable.group({ firstName: ['', Validators.required], lastName: ['', Validators.required], email: ['', [Validators.required, Validators.email]] }),
    address: this.fb.nonNullable.group({ street: ['', Validators.required], city: ['', Validators.required], zip: ['', Validators.required] }),
    account: this.fb.nonNullable.group({ username: ['', Validators.required], password: ['', [Validators.required, Validators.minLength(8)]] }),
  });
  private stepGroups = ['personal', 'address', 'account'] as const;
  isCurrentStepValid() { return this.form.get(this.stepGroups[this.currentStep()])!.valid; }
  next() { if (this.isCurrentStepValid()) this.currentStep.update(s => s + 1); }
  prev() { this.currentStep.update(s => s - 1); }
  submit() { if (this.form.valid) console.log(this.form.getRawValue()); }
}
```

### Form Auto-Save

```typescript
ngOnInit() {
  this.form.valueChanges.pipe(
    debounceTime(1000),
    filter(() => this.form.dirty),
    switchMap(value => this.saveService.save(value)),
    takeUntilDestroyed(this.destroyRef),
  ).subscribe(() => { this.form.markAsPristine(); });
}
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

---

## Directive Patterns

### Intersection Observer

```typescript
@Directive({ selector: '[appInView]' })
export class InViewDirective {
  appInView = output<boolean>();
  private el = inject(ElementRef);

  constructor() {
    afterNextRender(() => {
      const observer = new IntersectionObserver(
        ([entry]) => this.appInView.emit(entry.isIntersecting),
        { threshold: 0.1 }
      );
      observer.observe(this.el.nativeElement);
      inject(DestroyRef).onDestroy(() => observer.disconnect());
    });
  }
}
```

### Debounce Input

```typescript
@Directive({
  selector: 'input[appDebounce]',
  host: { '(input)': 'onInput($event)' },
})
export class DebounceDirective {
  appDebounce = input(300);
  debounced = output<string>();
  private timeout: ReturnType<typeof setTimeout> | null = null;

  onInput(event: Event) {
    if (this.timeout) clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.debounced.emit((event.target as HTMLInputElement).value);
    }, this.appDebounce());
  }
}
```

### Directive Composition with Multiple Behaviors

```typescript
@Component({
  selector: 'app-interactive-card',
  hostDirectives: [
    { directive: FocusableDirective },
    { directive: RippleDirective, inputs: ['appRipple'] },
    { directive: ClickOutsideDirective, outputs: ['appClickOutside'] },
  ],
  template: `<ng-content />`,
})
export class InteractiveCardComponent {}
```

---

## Pipe Patterns

### Safe URL Pipe

```typescript
@Pipe({ name: 'safeUrl' })
export class SafeUrlPipe implements PipeTransform {
  private sanitizer = inject(DomSanitizer);
  transform(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }
}
```

### Highlight Search Term

```typescript
@Pipe({ name: 'highlight' })
export class HighlightPipe implements PipeTransform {
  transform(text: string, search: string): string {
    if (!search || !text) return text;
    const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return text.replace(new RegExp(`(${escaped})`, 'gi'), '<mark>$1</mark>');
  }
}
```

### Relative Time with Intl

```typescript
@Pipe({ name: 'relativeTime' })
export class RelativeTimePipe implements PipeTransform {
  private rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });

  transform(date: Date | string | number): string {
    const diffSec = Math.round((new Date(date).getTime() - Date.now()) / 1000);
    const units: [Intl.RelativeTimeFormatUnit, number][] = [
      ['year', 31536000], ['month', 2592000], ['week', 604800],
      ['day', 86400], ['hour', 3600], ['minute', 60], ['second', 1],
    ];
    for (const [unit, secs] of units) {
      if (Math.abs(diffSec) >= secs) return this.rtf.format(Math.round(diffSec / secs), unit);
    }
    return this.rtf.format(0, 'second');
  }
}
```

---

## Testing Patterns

### Component Harness

```typescript
export class ButtonHarness extends ComponentHarness {
  static hostSelector = 'app-button';
  private button = this.locatorFor('button');

  async getText() { return (await this.button()).text(); }
  async click() { return (await this.button()).click(); }
  async isDisabled() { return (await (await this.button()).getAttribute('disabled')) !== null; }
}
```

### Testing Reactive Forms

```typescript
it('should validate form fields', () => {
  const fixture = TestBed.createComponent(LoginComponent);
  fixture.detectChanges();
  expect(fixture.componentInstance.form.valid).toBeFalse();

  fixture.componentInstance.form.controls.email.setValue('test@example.com');
  fixture.componentInstance.form.controls.password.setValue('password123');
  expect(fixture.componentInstance.form.valid).toBeTrue();
});
```

### Provider Override Patterns

```typescript
TestBed.configureTestingModule({
  providers: [
    { provide: API_BASE_URL, useValue: 'http://test-api.com' },
    { provide: AuthService, useValue: { isAuthenticated: () => true, user: signal({ id: '1', name: 'Test' }) } },
  ],
});
```

---

## SSR Patterns

### SSR-Safe Service

```typescript
@Injectable({ providedIn: 'root' })
export class WindowService {
  private platformId = inject(PLATFORM_ID);
  get isBrowser() { return isPlatformBrowser(this.platformId); }
  get windowRef() { return this.isBrowser ? window : null; }
  scrollTo(x: number, y: number) { if (this.isBrowser) window.scrollTo(x, y); }
}
```

### Meta Tags and SEO

```typescript
@Component({...})
export class ProductPageComponent {
  private meta = inject(Meta);
  private title = inject(Title);
  product = input.required<Product>();

  constructor() {
    effect(() => {
      const p = this.product();
      this.title.setTitle(`${p.name} - My Store`);
      this.meta.updateTag({ name: 'description', content: p.description });
      this.meta.updateTag({ property: 'og:title', content: p.name });
    });
  }
}
```

### Transfer State for Custom Data

```typescript
const CONFIG_KEY = makeStateKey<AppConfig>('appConfig');

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private transferState = inject(TransferState);
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID);

  async loadConfig() {
    const cached = this.transferState.get(CONFIG_KEY, null);
    if (cached) { this.transferState.remove(CONFIG_KEY); return cached; }
    const config = await firstValueFrom(this.http.get<AppConfig>('/api/config'));
    if (isPlatformServer(this.platformId)) this.transferState.set(CONFIG_KEY, config);
    return config;
  }
}
```

---

## Tooling Patterns

### ESLint Configuration

```bash
ng add @angular-eslint/schematics
```

### Bundle Optimization

```typescript
// GOOD: Import specific functions
import { map, filter, switchMap } from 'rxjs';
// BAD: import * as rxjs from 'rxjs';
```

### Path Aliases

```json
{
  "compilerOptions": {
    "paths": {
      "@app/*": ["./src/app/*"],
      "@core/*": ["./src/app/core/*"],
      "@shared/*": ["./src/app/shared/*"],
      "@env/*": ["./src/environments/*"]
    }
  }
}
```

### Migration Commands

```bash
ng update @angular/cli --migrate-only use-application-builder
ng generate @angular/core:standalone
ng generate @angular/core:control-flow
ng generate @angular/core:signal-input-migration
ng generate @angular/core:inject-migration
```
