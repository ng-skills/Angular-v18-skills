# Advanced Signal Patterns — Angular v18

## State Machine with Signals

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

  readonly state = this._state.asReadonly();
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

## Signal-Based Store Pattern

```typescript
interface AppState {
  user: User | null;
  theme: 'light' | 'dark';
  notifications: Notification[];
}

@Injectable({ providedIn: 'root' })
export class AppStore {
  private _state = signal<AppState>({
    user: null,
    theme: 'light',
    notifications: [],
  });

  // Selectors
  readonly user = computed(() => this._state().user);
  readonly theme = computed(() => this._state().theme);
  readonly notifications = computed(() => this._state().notifications);
  readonly unreadCount = computed(() =>
    this._state().notifications.filter(n => !n.read).length
  );

  // Actions
  setUser(user: User | null) {
    this._state.update(s => ({ ...s, user }));
  }

  toggleTheme() {
    this._state.update(s => ({
      ...s,
      theme: s.theme === 'light' ? 'dark' : 'light',
    }));
  }

  addNotification(notification: Notification) {
    this._state.update(s => ({
      ...s,
      notifications: [notification, ...s.notifications],
    }));
  }

  markAsRead(id: string) {
    this._state.update(s => ({
      ...s,
      notifications: s.notifications.map(n =>
        n.id === id ? { ...n, read: true } : n
      ),
    }));
  }
}
```

## Debounced Signal with RxJS

```typescript
function debouncedSignal<T>(source: Signal<T>, debounceMs: number): Signal<T> {
  const debounced = toSignal(
    toObservable(source).pipe(debounceTime(debounceMs)),
    { initialValue: source() }
  );
  return debounced;
}

// Usage in component
@Component({...})
export class SearchComponent {
  query = signal('');
  debouncedQuery = debouncedSignal(this.query, 300);

  results = toSignal(
    toObservable(this.debouncedQuery).pipe(
      switchMap(q => this.http.get<Result[]>(`/api/search?q=${q}`))
    ),
    { initialValue: [] }
  );
}
```

## Signal with Local Storage Persistence

```typescript
function persistedSignal<T>(key: string, initialValue: T): WritableSignal<T> {
  const stored = localStorage.getItem(key);
  const initial = stored ? JSON.parse(stored) : initialValue;

  const sig = signal<T>(initial);

  effect(() => {
    localStorage.setItem(key, JSON.stringify(sig()));
  });

  return sig;
}

// Usage
@Injectable({ providedIn: 'root' })
export class PreferencesService {
  theme = persistedSignal<'light' | 'dark'>('theme', 'light');
  language = persistedSignal<string>('language', 'en');
}
```

## Pagination with Signals

```typescript
@Component({...})
export class PaginatedListComponent {
  private http = inject(HttpClient);

  page = signal(1);
  pageSize = signal(10);
  totalItems = signal(0);

  totalPages = computed(() =>
    Math.ceil(this.totalItems() / this.pageSize())
  );

  items = toSignal(
    toObservable(computed(() => ({
      page: this.page(),
      pageSize: this.pageSize(),
    }))).pipe(
      switchMap(({ page, pageSize }) =>
        this.http.get<PaginatedResponse<Item>>('/api/items', {
          params: { page, limit: pageSize },
        })
      ),
      tap(response => this.totalItems.set(response.total)),
      map(response => response.data),
    ),
    { initialValue: [] }
  );

  nextPage() {
    if (this.page() < this.totalPages()) {
      this.page.update(p => p + 1);
    }
  }

  prevPage() {
    if (this.page() > 1) {
      this.page.update(p => p - 1);
    }
  }
}
```

## Combining Multiple Signal Sources

```typescript
@Component({...})
export class DashboardComponent {
  private userService = inject(UserService);
  private analyticsService = inject(AnalyticsService);

  users = toSignal(this.userService.getAll(), { initialValue: [] });
  analytics = toSignal(this.analyticsService.getSummary());

  // Combine multiple signals into a view model
  dashboardData = computed(() => ({
    userCount: this.users().length,
    activeUsers: this.users().filter(u => u.active).length,
    revenue: this.analytics()?.revenue ?? 0,
    growth: this.analytics()?.growth ?? 0,
  }));
}
```

## Effect Best Practices

```typescript
// GOOD: effect for side effects only
effect(() => {
  document.title = `${this.pageName()} - My App`;
});

// GOOD: effect with cleanup
effect((onCleanup) => {
  const ws = new WebSocket(`ws://api.example.com/updates/${this.userId()}`);
  ws.onmessage = (e) => this.messages.update(m => [...m, JSON.parse(e.data)]);

  onCleanup(() => ws.close());
});

// BAD: setting signals inside effect (creates circular dependencies)
// effect(() => {
//   this.doubled.set(this.count() * 2); // Use computed() instead
// });
```
