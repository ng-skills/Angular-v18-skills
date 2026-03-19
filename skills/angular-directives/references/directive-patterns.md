# Advanced Directive Patterns — Angular v18

## Intersection Observer Directive

```typescript
@Directive({
  selector: '[appInView]',
})
export class InViewDirective {
  appInView = output<boolean>();

  private el = inject(ElementRef);
  private observer: IntersectionObserver | null = null;

  constructor() {
    afterNextRender(() => {
      this.observer = new IntersectionObserver(
        ([entry]) => this.appInView.emit(entry.isIntersecting),
        { threshold: 0.1 }
      );
      this.observer.observe(this.el.nativeElement);
    });

    inject(DestroyRef).onDestroy(() => {
      this.observer?.disconnect();
    });
  }
}

// Usage: <div (appInView)="onVisible($event)">Content</div>
```

## Debounce Input Directive

```typescript
@Directive({
  selector: 'input[appDebounce]',
  host: {
    '(input)': 'onInput($event)',
  },
})
export class DebounceDirective {
  appDebounce = input(300); // Debounce time in ms
  debounced = output<string>();

  private timeout: ReturnType<typeof setTimeout> | null = null;

  onInput(event: Event) {
    if (this.timeout) clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.debounced.emit((event.target as HTMLInputElement).value);
    }, this.appDebounce());
  }
}

// Usage: <input [appDebounce]="500" (debounced)="search($event)" />
```

## Long Press Directive

```typescript
@Directive({
  selector: '[appLongPress]',
  host: {
    '(mousedown)': 'onPress()',
    '(mouseup)': 'onRelease()',
    '(mouseleave)': 'onRelease()',
    '(touchstart)': 'onPress()',
    '(touchend)': 'onRelease()',
  },
})
export class LongPressDirective {
  appLongPress = input(500); // Duration in ms
  longPressed = output<void>();

  private timeout: ReturnType<typeof setTimeout> | null = null;

  onPress() {
    this.timeout = setTimeout(() => {
      this.longPressed.emit();
    }, this.appLongPress());
  }

  onRelease() {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
  }
}

// Usage: <button [appLongPress]="1000" (longPressed)="onLongPress()">Hold</button>
```

## Typed Structural Directive

```typescript
@Directive({
  selector: '[appLet]',
})
export class LetDirective<T> {
  private templateRef = inject(TemplateRef<{ appLet: T; $implicit: T }>);
  private viewContainer = inject(ViewContainerRef);
  private viewRef: EmbeddedViewRef<any> | null = null;

  @Input()
  set appLet(value: T) {
    if (!this.viewRef) {
      this.viewRef = this.viewContainer.createEmbeddedView(this.templateRef, {
        appLet: value,
        $implicit: value,
      });
    } else {
      this.viewRef.context.appLet = value;
      this.viewRef.context.$implicit = value;
      this.viewRef.markForCheck();
    }
  }

  static ngTemplateGuard_appLet: 'binding';
  static ngTemplateContextGuard<T>(
    _dir: LetDirective<T>,
    ctx: unknown
  ): ctx is { appLet: T; $implicit: T } {
    return true;
  }
}

// Usage:
// <ng-container *appLet="computeExpensiveValue() as value">
//   {{ value }}
// </ng-container>
```

## Directive with Renderer2

```typescript
import { Renderer2 } from '@angular/core';

@Directive({
  selector: '[appRipple]',
  host: {
    '(click)': 'createRipple($event)',
    '[style.position]': '"relative"',
    '[style.overflow]': '"hidden"',
  },
})
export class RippleDirective {
  appRipple = input('#ffffff40'); // Ripple color

  private el = inject(ElementRef);
  private renderer = inject(Renderer2);

  createRipple(event: MouseEvent) {
    const rect = this.el.nativeElement.getBoundingClientRect();
    const ripple = this.renderer.createElement('span');
    const size = Math.max(rect.width, rect.height);

    this.renderer.setStyle(ripple, 'width', `${size}px`);
    this.renderer.setStyle(ripple, 'height', `${size}px`);
    this.renderer.setStyle(ripple, 'left', `${event.clientX - rect.left - size / 2}px`);
    this.renderer.setStyle(ripple, 'top', `${event.clientY - rect.top - size / 2}px`);
    this.renderer.setStyle(ripple, 'background', this.appRipple());
    this.renderer.addClass(ripple, 'ripple-effect');
    this.renderer.appendChild(this.el.nativeElement, ripple);

    setTimeout(() => this.renderer.removeChild(this.el.nativeElement, ripple), 600);
  }
}
```

## Directive Composition with Multiple Behaviors

```typescript
// Compose behavior directives via hostDirectives
@Component({
  selector: 'app-interactive-card',
  hostDirectives: [
    { directive: FocusableDirective },
    { directive: RippleDirective, inputs: ['appRipple'] },
    { directive: ClickOutsideDirective, outputs: ['appClickOutside'] },
  ],
  template: `
    <ng-content />
  `,
})
export class InteractiveCardComponent {
  // Gets all behaviors from host directives without consumer needing to apply them
}

// Consumer just uses:
// <app-interactive-card (appClickOutside)="close()">Content</app-interactive-card>
```
