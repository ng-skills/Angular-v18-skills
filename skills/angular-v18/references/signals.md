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

## APIs NOT Available in Angular v18

- `linkedSignal()` — Angular 19+
- `resource()` / `httpResource()` — Angular 19+

Use `toSignal()` with `HttpClient` observables for async data in v18.

---

## Signal Patterns

### Service State Pattern

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

`toSignal()` and `toObservable()` require an injection context. Either call from a constructor/field initializer, or pass an explicit injector:

```typescript
// Option A: Use directly in a component/service field initializer (has injection context)
@Component({...})
export class SearchComponent {
  query = signal('');
  debouncedQuery = toSignal(
    toObservable(this.query).pipe(debounceTime(300)),
    { initialValue: '' }
  );
}

// Option B: Factory function with explicit injector
function debouncedSignal<T>(source: Signal<T>, debounceMs: number, injector: Injector): Signal<T> {
  return toSignal(
    toObservable(source, { injector }).pipe(debounceTime(debounceMs)),
    { initialValue: source(), injector }
  );
}
```

### Persisted Signal

`effect()` requires an injection context. Either call from a constructor, or pass an explicit injector:

```typescript
// Option A: Use directly in a constructor
@Component({...})
export class SettingsComponent {
  theme = signal(localStorage.getItem('theme') ?? 'light');

  constructor() {
    effect(() => { localStorage.setItem('theme', this.theme()); });
  }
}

// Option B: Factory function with explicit injector
function persistedSignal<T>(key: string, initialValue: T, injector: Injector): WritableSignal<T> {
  const stored = localStorage.getItem(key);
  const sig = signal<T>(stored ? JSON.parse(stored) : initialValue);
  effect(() => { localStorage.setItem(key, JSON.stringify(sig())); }, { injector });
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
