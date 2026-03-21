# Angular v18 Directives

All directives must have `standalone: true` explicitly set (default only in Angular 19+). Use `host` metadata for bindings.

## Attribute Directive

```typescript
@Directive({
  selector: '[appHighlight]',
  standalone: true,
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
@Directive({ selector: '[appPermission]', standalone: true })
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
  standalone: true,
  hostDirectives: [
    FocusableDirective,
    { directive: DisableableDirective, inputs: ['disabled'] },
  ],
  template: `<ng-content />`,
})
export class ChipComponent {}
```

---

## Directive Patterns

### Intersection Observer

```typescript
@Directive({ selector: '[appInView]', standalone: true })
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
  standalone: true,
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
  standalone: true,
  hostDirectives: [
    { directive: FocusableDirective },
    { directive: RippleDirective, inputs: ['appRipple'] },
    { directive: ClickOutsideDirective, outputs: ['appClickOutside'] },
  ],
  template: `<ng-content />`,
})
export class InteractiveCardComponent {}
```
