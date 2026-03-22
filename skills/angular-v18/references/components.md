# Angular v18 Components

In Angular v18 you must explicitly set `standalone: true` on every component, directive, and pipe. The standalone default (where you can omit it) was introduced in Angular 19. Do NOT use NgModules for new code.

## Component Structure

```typescript
import { Component, ChangeDetectionStrategy, input, output, computed } from '@angular/core';

@Component({
  selector: 'app-user-card',
  standalone: true,
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

## Signal Inputs (Developer Preview in v18, Stable in v19)

Always use signal-based `input()` — do NOT use `@Input()` decorator.

```typescript
import { input, booleanAttribute, numberAttribute } from '@angular/core';

name = input.required<string>();
count = input(0);
label = input<string>();
size = input('medium', { alias: 'buttonSize' });
disabled = input(false, { transform: booleanAttribute });
value = input(0, { transform: numberAttribute });
```

## Signal Outputs (Developer Preview in v18, Stable in v19)

Always use signal-based `output()` — do NOT use `@Output()` decorator or `EventEmitter`.

```typescript
import { output, outputFromObservable } from '@angular/core';

clicked = output<void>();
selected = output<Item>();
valueChange = output<number>({ alias: 'change' });

scroll$ = new Subject<number>();
scrolled = outputFromObservable(this.scroll$);
```

## Two-Way Binding with model() (Developer Preview in v18, Stable in v19)

```typescript
import { model } from '@angular/core';

@Component({
  selector: 'app-counter',
  standalone: true,
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
  standalone: true,
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
  standalone: true,
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

## View Queries (Developer Preview in v18, Stable in v19)

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
  standalone: true,
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
  standalone: true,
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

## Component Patterns

### Container/Presentational Pattern

```typescript
// Container — handles data and logic
@Component({
  selector: 'app-user-list-page',
  standalone: true,
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
  standalone: true,
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
  standalone: true,
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

### Component with CSS Animations

Prefer native CSS animations over `@angular/animations` — they are more performant, don't require an extra package, and Angular's animation module may be deprecated in future versions.

```typescript
@Component({
  selector: 'app-expandable',
  standalone: true,
  template: `
    <div class="expandable" [class.expanded]="expanded()">
      <ng-content />
    </div>
  `,
  styles: `
    .expandable {
      display: grid;
      grid-template-rows: 0fr;
      opacity: 0;
      transition: grid-template-rows 200ms ease-out, opacity 200ms ease-out;
    }
    .expandable > * {
      overflow: hidden;
    }
    .expandable.expanded {
      grid-template-rows: 1fr;
      opacity: 1;
    }
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
  standalone: true,
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
