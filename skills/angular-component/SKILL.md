---
name: angular-component
description: Create and structure Angular v18 standalone components with signal-based inputs/outputs (developer preview), built-in control flow (@if, @for, @switch), OnPush change detection, content projection, and host bindings. Use when building UI components, defining component inputs/outputs, using template syntax, or setting up component styling. Do not use for routing, forms, HTTP, or state management across components.
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

Signal-based inputs are the recommended approach in v18, though still in developer preview.

```typescript
import { input, booleanAttribute, numberAttribute } from '@angular/core';

// Required input — must be provided by parent
name = input.required<string>();

// Optional with default value
count = input(0);

// Optional without default (type includes undefined)
label = input<string>();

// With alias for template binding
size = input('medium', { alias: 'buttonSize' });

// With transform function
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

// Basic output
clicked = output<void>();
selected = output<Item>();

// With alias
valueChange = output<number>({ alias: 'change' });

// From Observable (RxJS interop)
scroll$ = new Subject<number>();
scrolled = outputFromObservable(this.scroll$);

// Emit values
this.clicked.emit();
this.selected.emit(item);
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

Lazy-load parts of the template to improve initial load performance.

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

<!-- Other trigger types -->
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

// Usage:
// <app-card>
//   <h2 card-header>Title</h2>
//   <p>Main content</p>
//   <button card-footer>Action</button>
// </app-card>
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

// Single child query
chart = viewChild<ElementRef>('chartCanvas');
dialog = viewChild(DialogComponent);

// Required query (guaranteed to exist)
header = viewChild.required<ElementRef>('header');

// Multiple children
items = viewChildren(ItemComponent);
tabs = contentChildren(TabComponent);
```

### Decorator-Based Queries (Stable Alternative)

```typescript
@ViewChild('chartCanvas') chart!: ElementRef;
@ViewChildren(ItemComponent) items!: QueryList<ItemComponent>;
@ContentChild(TabComponent) tab!: TabComponent;
```

## Lifecycle Hooks

```typescript
import { afterNextRender, afterRender } from '@angular/core';

export class MyComponent implements OnInit, OnDestroy {
  constructor() {
    // SSR-safe DOM access — runs only in the browser
    afterNextRender(() => {
      // Runs once after first render
    });

    afterRender(() => {
      // Runs after every render
    });
  }

  ngOnInit() { /* Component initialized */ }
  ngOnDestroy() { /* Cleanup subscriptions, timers */ }
}
```

## Class and Style Bindings

Do NOT use `ngClass` or `ngStyle`. Use direct bindings:

```html
<div [class.active]="isActive()">Single class</div>
<div [class]="classString()">Class string</div>
<div [style.color]="textColor()">Styled text</div>
<div [style.width.px]="width()">With unit</div>
```

## Images — NgOptimizedImage

```typescript
import { NgOptimizedImage } from '@angular/common';

@Component({
  imports: [NgOptimizedImage],
  template: `
    <img ngSrc="/assets/hero.jpg" width="800" height="600" priority />
    <img [ngSrc]="imageUrl()" width="200" height="200" />
  `,
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

For advanced component patterns, see [references/component-patterns.md](references/component-patterns.md).
