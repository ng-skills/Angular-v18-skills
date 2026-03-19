# Advanced Component Patterns — Angular v18

## Container/Presentational Pattern

Separate data-fetching (container) from display (presentational) components.

```typescript
// Container — handles data and logic
@Component({
  selector: 'app-user-list-page',
  imports: [UserListComponent],
  template: `
    @if (loading()) {
      <app-spinner />
    } @else {
      <app-user-list
        [users]="users()"
        (userSelected)="onUserSelected($event)"
      />
    }
  `,
})
export class UserListPageComponent {
  private userService = inject(UserService);
  private router = inject(Router);

  users = toSignal(this.userService.getAll(), { initialValue: [] });
  loading = signal(true);

  constructor() {
    effect(() => {
      if (this.users().length >= 0) this.loading.set(false);
    });
  }

  onUserSelected(user: User) {
    this.router.navigate(['/users', user.id]);
  }
}

// Presentational — pure display
@Component({
  selector: 'app-user-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @for (user of users(); track user.id) {
      <div class="user-card" (click)="userSelected.emit(user)">
        <h3>{{ user.name }}</h3>
        <p>{{ user.email }}</p>
      </div>
    } @empty {
      <p>No users found</p>
    }
  `,
})
export class UserListComponent {
  users = input.required<User[]>();
  userSelected = output<User>();
}
```

## Component with Dialog/Modal

```typescript
@Component({
  selector: 'app-confirm-dialog',
  host: {
    'role': 'dialog',
    '[attr.aria-modal]': 'true',
    '[attr.aria-labelledby]': '"dialog-title"',
    '(keydown.escape)': 'onCancel()',
  },
  template: `
    <div class="overlay" (click)="onCancel()"></div>
    <div class="dialog">
      <h2 id="dialog-title">{{ title() }}</h2>
      <p>{{ message() }}</p>
      <div class="actions">
        <button (click)="onCancel()">Cancel</button>
        <button class="primary" (click)="onConfirm()">{{ confirmText() }}</button>
      </div>
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

## Component with Animations

```typescript
import { trigger, transition, style, animate } from '@angular/animations';

@Component({
  selector: 'app-expandable',
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
    <button (click)="expanded.set(!expanded())">
      {{ expanded() ? 'Collapse' : 'Expand' }}
    </button>
    @if (expanded()) {
      <div @expand>
        <ng-content />
      </div>
    }
  `,
})
export class ExpandableComponent {
  expanded = signal(false);
}
```

## Generic List Component

```typescript
@Component({
  selector: 'app-data-table',
  template: `
    <table>
      <thead>
        <tr>
          @for (col of columns(); track col.key) {
            <th (click)="sortBy(col.key)">
              {{ col.label }}
              @if (sortColumn() === col.key) {
                <span>{{ sortDirection() === 'asc' ? '▲' : '▼' }}</span>
              }
            </th>
          }
        </tr>
      </thead>
      <tbody>
        @for (row of sortedData(); track trackBy()(row)) {
          <tr (click)="rowClicked.emit(row)">
            @for (col of columns(); track col.key) {
              <td>{{ row[col.key] }}</td>
            }
          </tr>
        } @empty {
          <tr><td [attr.colspan]="columns().length">No data</td></tr>
        }
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
      const aVal = a[col];
      const bVal = b[col];
      const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
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

## OnPush Change Detection Strategy

Always use `OnPush` for new components. This works naturally with signals.

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  // ...
})
export class MyComponent {
  // Signals automatically trigger change detection in OnPush components
  count = signal(0);
  doubled = computed(() => this.count() * 2);
}
```

## Multi-Slot Content Projection with Fallbacks

```typescript
@Component({
  selector: 'app-page-layout',
  template: `
    <aside class="sidebar">
      <ng-content select="[sidebar]">
        <nav>Default sidebar</nav>
      </ng-content>
    </aside>
    <main>
      <header>
        <ng-content select="[page-header]">
          <h1>Default Header</h1>
        </ng-content>
      </header>
      <section class="content">
        <ng-content />
      </section>
      <footer>
        <ng-content select="[page-footer]" />
      </footer>
    </main>
  `,
})
export class PageLayoutComponent {}
```
