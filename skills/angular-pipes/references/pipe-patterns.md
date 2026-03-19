# Advanced Pipe Patterns — Angular v18

## Safe URL Pipe

```typescript
import { Pipe, PipeTransform, inject } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';

@Pipe({ name: 'safeUrl' })
export class SafeUrlPipe implements PipeTransform {
  private sanitizer = inject(DomSanitizer);

  transform(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }
}

// Usage: <iframe [src]="videoUrl | safeUrl"></iframe>
```

## Highlight Search Term Pipe

```typescript
@Pipe({ name: 'highlight' })
export class HighlightPipe implements PipeTransform {
  transform(text: string, search: string): string {
    if (!search || !text) return text;
    const escaped = search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(${escaped})`, 'gi');
    return text.replace(regex, '<mark>$1</mark>');
  }
}

// Usage: <span [innerHTML]="item.name | highlight:searchQuery()"></span>
```

## Relative Time Pipe with Intl

```typescript
@Pipe({ name: 'relativeTime' })
export class RelativeTimePipe implements PipeTransform {
  private rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });

  transform(date: Date | string | number): string {
    const now = Date.now();
    const then = new Date(date).getTime();
    const diffSec = Math.round((then - now) / 1000);

    const units: [Intl.RelativeTimeFormatUnit, number][] = [
      ['year', 60 * 60 * 24 * 365],
      ['month', 60 * 60 * 24 * 30],
      ['week', 60 * 60 * 24 * 7],
      ['day', 60 * 60 * 24],
      ['hour', 60 * 60],
      ['minute', 60],
      ['second', 1],
    ];

    for (const [unit, secondsInUnit] of units) {
      if (Math.abs(diffSec) >= secondsInUnit) {
        const value = Math.round(diffSec / secondsInUnit);
        return this.rtf.format(value, unit);
      }
    }

    return this.rtf.format(0, 'second');
  }
}

// Usage: {{ post.createdAt | relativeTime }}
// Output: "2 hours ago", "yesterday", "3 days ago"
```

## Pluralize Pipe

```typescript
@Pipe({ name: 'pluralize' })
export class PluralizePipe implements PipeTransform {
  transform(count: number, singular: string, plural?: string): string {
    const word = count === 1 ? singular : (plural || singular + 's');
    return `${count} ${word}`;
  }
}

// Usage: {{ items.length | pluralize:'item' }}
// Output: "1 item", "5 items"
// {{ children.length | pluralize:'child':'children' }}
```

## Sort Pipe

```typescript
@Pipe({ name: 'sortBy' })
export class SortByPipe implements PipeTransform {
  transform<T>(array: T[], field: keyof T, direction: 'asc' | 'desc' = 'asc'): T[] {
    if (!array || !field) return array;

    return [...array].sort((a, b) => {
      const aVal = a[field];
      const bVal = b[field];
      const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
      return direction === 'asc' ? cmp : -cmp;
    });
  }
}

// Usage: @for (user of users | sortBy:'name':'asc'; track user.id)
```

## Group By Pipe

```typescript
@Pipe({ name: 'groupBy' })
export class GroupByPipe implements PipeTransform {
  transform<T>(array: T[], field: keyof T): { key: string; items: T[] }[] {
    if (!array) return [];

    const groups = new Map<string, T[]>();
    for (const item of array) {
      const key = String(item[field]);
      const group = groups.get(key) || [];
      group.push(item);
      groups.set(key, group);
    }

    return Array.from(groups, ([key, items]) => ({ key, items }));
  }
}

// Usage:
// @for (group of tasks | groupBy:'status'; track group.key) {
//   <h3>{{ group.key }}</h3>
//   @for (task of group.items; track task.id) {
//     <app-task [task]="task" />
//   }
// }
```

## Pipe with Dependency Injection

```typescript
@Pipe({ name: 'translate' })
export class TranslatePipe implements PipeTransform {
  private translations = inject(TranslationService);

  transform(key: string, params?: Record<string, string>): string {
    return this.translations.translate(key, params);
  }
}

// Usage: {{ 'greeting.hello' | translate:{ name: user.name } }}
```
