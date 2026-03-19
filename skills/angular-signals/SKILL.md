---
name: angular-signals
description: Implement signal-based reactive state management in Angular v18. Use for creating reactive state with signal(), derived state with computed(), and side effects with effect(). Covers RxJS interop with toSignal() and toObservable(). Triggers on state management questions, converting from BehaviorSubject/Observable patterns to signals, or implementing reactive data flows. Do not use for linkedSignal() or resource() which are not available in v18.
---

# Angular v18 Signals

Signals are Angular's reactive primitive for synchronous, fine-grained state management. In v18, `signal()` and `computed()` are **stable**. `effect()` is in **developer preview**.

## signal() — Writable State

```typescript
import { signal } from '@angular/core';

const count = signal(0);

// Read
console.log(count()); // 0

// Set new value
count.set(5);

// Update based on current value
count.update(c => c + 1);

// With explicit type
const user = signal<User | null>(null);
user.set({ id: 1, name: 'Alice' });
```

## computed() — Derived State

```typescript
import { signal, computed } from '@angular/core';

const firstName = signal('John');
const lastName = signal('Doe');
const fullName = computed(() => `${firstName()} ${lastName()}`);

console.log(fullName()); // "John Doe"
firstName.set('Jane');
console.log(fullName()); // "Jane Doe"

// Complex derived state
const items = signal<Item[]>([]);
const filter = signal('');

const filteredItems = computed(() => {
  const query = filter().toLowerCase();
  return items().filter(item =>
    item.name.toLowerCase().includes(query)
  );
});

const totalPrice = computed(() =>
  filteredItems().reduce((sum, item) => sum + item.price, 0)
);
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

    // Effect with cleanup
    effect((onCleanup) => {
      const timer = setInterval(() => {
        console.log('Current query:', this.query());
      }, 1000);

      onCleanup(() => clearInterval(timer));
    });
  }
}
```

**Effect rules:**
- Must run in injection context (constructor or `runInInjectionContext`)
- Automatically cleaned up when the enclosing context is destroyed
- Do not set signals inside effects unless absolutely necessary

## Signal Equality

```typescript
const user = signal<User>(
  { id: 1, name: 'Alice' },
  { equal: (a, b) => a.id === b.id }
);

// Only triggers updates when ID changes
user.set({ id: 1, name: 'Alice Updated' }); // No update triggered
user.set({ id: 2, name: 'Bob' }); // Update triggered
```

## untracked() — Prevent Dependency Tracking

```typescript
import { untracked } from '@angular/core';

const a = signal(1);
const b = signal(2);

// Only tracks 'a', not 'b'
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
  private _loading = signal(false);

  // Expose read-only versions
  readonly user = this._user.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly isAuthenticated = computed(() => this._user() !== null);
}
```

## RxJS Interop

### toSignal() — Observable to Signal

```typescript
import { toSignal } from '@angular/core/rxjs-interop';

@Component({...})
export class TimerComponent {
  private http = inject(HttpClient);

  // From observable with initial value
  counter = toSignal(interval(1000), { initialValue: 0 });

  // From HTTP — undefined until first value
  users = toSignal(this.http.get<User[]>('/api/users'));

  // With requireSync for BehaviorSubject
  private user$ = new BehaviorSubject<User | null>(null);
  currentUser = toSignal(this.user$, { requireSync: true });
}
```

### toObservable() — Signal to Observable

```typescript
import { toObservable } from '@angular/core/rxjs-interop';
import { switchMap, debounceTime } from 'rxjs';

@Component({...})
export class SearchComponent {
  query = signal('');
  private http = inject(HttpClient);

  results = toSignal(
    toObservable(this.query).pipe(
      debounceTime(300),
      switchMap(q => this.http.get<Result[]>(`/api/search?q=${q}`))
    ),
    { initialValue: [] }
  );
}
```

## Component State Pattern

```typescript
@Component({
  selector: 'app-todo-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <input [value]="newTodo()" (input)="newTodo.set($any($event.target).value)" />
    <button (click)="addTodo()" [disabled]="!canAdd()">Add</button>

    <ul>
      @for (todo of filteredTodos(); track todo.id) {
        <li [class.done]="todo.done">
          {{ todo.text }}
          <button (click)="toggleTodo(todo.id)">Toggle</button>
        </li>
      }
    </ul>

    <p>{{ remaining() }} remaining</p>
  `,
})
export class TodoListComponent {
  todos = signal<Todo[]>([]);
  newTodo = signal('');
  filter = signal<'all' | 'active' | 'done'>('all');

  canAdd = computed(() => this.newTodo().trim().length > 0);

  filteredTodos = computed(() => {
    const todos = this.todos();
    switch (this.filter()) {
      case 'active': return todos.filter(t => !t.done);
      case 'done': return todos.filter(t => t.done);
      default: return todos;
    }
  });

  remaining = computed(() =>
    this.todos().filter(t => !t.done).length
  );

  addTodo() {
    const text = this.newTodo().trim();
    if (text) {
      this.todos.update(todos => [
        ...todos,
        { id: crypto.randomUUID(), text, done: false }
      ]);
      this.newTodo.set('');
    }
  }

  toggleTodo(id: string) {
    this.todos.update(todos =>
      todos.map(t => t.id === id ? { ...t, done: !t.done } : t)
    );
  }
}
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
          i.productId === product.id
            ? { ...i, quantity: i.quantity + 1 }
            : i
        );
      }
      return [...items, { productId: product.id, price: product.price, quantity: 1 }];
    });
  }

  removeItem(productId: string) {
    this._items.update(items => items.filter(i => i.productId !== productId));
  }
}
```

## APIs NOT Available in Angular v18

These signal APIs were introduced in later versions:

- `linkedSignal()` — Angular 19 (developer preview)
- `resource()` — Angular 19 (experimental)
- `httpResource()` — Angular 19+ (experimental)

Use `toSignal()` with `HttpClient` observables for async data in v18.

For advanced signal patterns, see [references/signal-patterns.md](references/signal-patterns.md).
