---
name: angular-directives
description: Create attribute and structural directives in Angular v18 with host bindings, dependency injection, and directive composition API. Use when building reusable DOM behaviors, custom structural directives, or composing multiple directives. Do not use for component creation or pipes.
---

# Angular v18 Directives

All directives are standalone by default. Use the `host` metadata for bindings.

## Attribute Directive

```typescript
import { Directive, input, inject, ElementRef, effect } from '@angular/core';

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
  private originalColor = '';

  onMouseEnter() {
    this.originalColor = this.el.nativeElement.style.backgroundColor;
    this.el.nativeElement.style.backgroundColor = this.appHighlight();
  }

  onMouseLeave() {
    this.el.nativeElement.style.backgroundColor = this.originalColor;
  }
}

// Usage: <p [appHighlight]="'lightblue'">Hover me</p>
```

## Directive with Host Bindings

```typescript
@Directive({
  selector: '[appTooltip]',
  host: {
    '[attr.title]': 'appTooltip()',
    '[class.has-tooltip]': 'true',
    '(focus)': 'show()',
    '(blur)': 'hide()',
    '(mouseenter)': 'show()',
    '(mouseleave)': 'hide()',
  },
})
export class TooltipDirective {
  appTooltip = input.required<string>();

  private visible = signal(false);

  show() { this.visible.set(true); }
  hide() { this.visible.set(false); }
}
```

## Structural Directive

```typescript
import { Directive, input, inject, TemplateRef, ViewContainerRef, effect } from '@angular/core';

@Directive({
  selector: '[appPermission]',
})
export class PermissionDirective {
  appPermission = input.required<string>();

  private templateRef = inject(TemplateRef);
  private viewContainer = inject(ViewContainerRef);
  private auth = inject(AuthService);

  constructor() {
    effect(() => {
      const hasPermission = this.auth.hasPermission(this.appPermission());
      if (hasPermission) {
        this.viewContainer.createEmbeddedView(this.templateRef);
      } else {
        this.viewContainer.clear();
      }
    });
  }
}

// Usage: <button *appPermission="'admin'">Delete</button>
```

**Note:** Prefer built-in control flow (`@if`, `@for`) over custom structural directives for simple conditional/loop logic.

## Directive with Exportable Reference

```typescript
@Directive({
  selector: '[appClickTracker]',
  exportAs: 'clickTracker',
})
export class ClickTrackerDirective {
  clickCount = signal(0);

  onClick() {
    this.clickCount.update(c => c + 1);
  }
}

// Usage:
// <button appClickTracker #tracker="clickTracker" (click)="tracker.onClick()">
//   Clicked {{ tracker.clickCount() }} times
// </button>
```

## Directive Composition API

Compose multiple directives onto a host component without requiring the consumer to apply them.

```typescript
@Directive({
  selector: '[appFocusable]',
  host: {
    'tabindex': '0',
    '[class.focused]': 'focused()',
    '(focus)': 'focused.set(true)',
    '(blur)': 'focused.set(false)',
  },
})
export class FocusableDirective {
  focused = signal(false);
}

@Directive({
  selector: '[appDisableable]',
  host: {
    '[class.disabled]': 'disabled()',
    '[attr.aria-disabled]': 'disabled()',
  },
})
export class DisableableDirective {
  disabled = input(false, { transform: booleanAttribute });
}

// Compose directives on a component
@Component({
  selector: 'app-chip',
  hostDirectives: [
    FocusableDirective,
    {
      directive: DisableableDirective,
      inputs: ['disabled'],
    },
  ],
  host: {
    'class': 'chip',
    '(click)': 'select()',
    '(keydown.enter)': 'select()',
  },
  template: `<ng-content />`,
})
export class ChipComponent {
  private focusable = inject(FocusableDirective);
  private disableable = inject(DisableableDirective);
  selected = output<void>();

  select() {
    if (!this.disableable.disabled()) {
      this.selected.emit();
    }
  }
}

// Consumer does not need to know about FocusableDirective or DisableableDirective
// <app-chip [disabled]="true" (selected)="onSelect()">Tag</app-chip>
```

## Inject Parent Component/Directive

```typescript
@Directive({
  selector: '[appAccordionItem]',
})
export class AccordionItemDirective {
  // Inject parent accordion
  private accordion = inject(AccordionComponent);
  expanded = signal(false);

  toggle() {
    this.accordion.toggleItem(this);
  }
}
```

## Common Utility Directives

### Auto-focus

```typescript
@Directive({
  selector: '[appAutoFocus]',
})
export class AutoFocusDirective {
  private el = inject(ElementRef);

  constructor() {
    afterNextRender(() => {
      this.el.nativeElement.focus();
    });
  }
}
```

### Click Outside

```typescript
@Directive({
  selector: '[appClickOutside]',
  host: {
    '(document:click)': 'onDocumentClick($event)',
  },
})
export class ClickOutsideDirective {
  appClickOutside = output<void>();

  private el = inject(ElementRef);

  onDocumentClick(event: Event) {
    if (!this.el.nativeElement.contains(event.target)) {
      this.appClickOutside.emit();
    }
  }
}

// Usage: <div (appClickOutside)="close()">Dropdown</div>
```

For advanced directive patterns, see [references/directive-patterns.md](references/directive-patterns.md).
