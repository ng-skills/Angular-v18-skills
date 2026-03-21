# Angular v18 Pipes

Pipes transform data in templates. All custom pipes must have `standalone: true` explicitly set (default only in Angular 19+).

## Built-in Pipes

```typescript
import { DatePipe, CurrencyPipe, DecimalPipe, PercentPipe, AsyncPipe } from '@angular/common';

// {{ createdAt | date:'short' }}
// {{ price | currency:'EUR' }}
// {{ value | number:'1.2-2' }}
// {{ ratio | percent }}
// {{ users$ | async }}
```

**Tip:** Prefer `toSignal()` over `AsyncPipe` when working with signals.

## Custom Pipe

```typescript
@Pipe({ standalone: true, name: 'truncate' })
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit = 50, trail = '...'): string {
    if (!value || value.length <= limit) return value || '';
    return value.substring(0, limit).trim() + trail;
  }
}
```

## Pipes vs Computed Signals

Prefer `computed()` for component-specific transformations. Use pipes for generic, reusable template formatting.

---

## Pipe Patterns

### Safe URL Pipe

```typescript
@Pipe({ standalone: true, name: 'safeUrl' })
export class SafeUrlPipe implements PipeTransform {
  private sanitizer = inject(DomSanitizer);
  transform(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }
}
```

### Highlight Search Term

```typescript
@Pipe({ standalone: true, name: 'highlight' })
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
@Pipe({ standalone: true, name: 'relativeTime' })
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
