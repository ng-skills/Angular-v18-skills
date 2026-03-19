---
name: angular-pipes
description: Use built-in and create custom pipes in Angular v18 for template data transformation. Covers DatePipe, CurrencyPipe, AsyncPipe, and creating custom pure/impure pipes. Use when formatting data in templates, creating reusable transformations, or displaying localized values. Do not use for component logic or service-level transformations.
---

# Angular v18 Pipes

Pipes transform data in templates. All custom pipes are standalone by default.

## Built-in Pipes

### DatePipe

```typescript
import { DatePipe } from '@angular/common';

@Component({
  imports: [DatePipe],
  template: `
    <p>{{ createdAt | date }}</p>
    <p>{{ createdAt | date:'short' }}</p>
    <p>{{ createdAt | date:'yyyy-MM-dd' }}</p>
    <p>{{ createdAt | date:'fullDate' }}</p>
    <p>{{ createdAt | date:'h:mm a' }}</p>
    <p>{{ createdAt | date:'medium':'UTC' }}</p>
  `,
})
export class EventComponent {
  createdAt = new Date();
}
```

### CurrencyPipe

```typescript
import { CurrencyPipe } from '@angular/common';

@Component({
  imports: [CurrencyPipe],
  template: `
    <p>{{ price | currency }}</p>
    <p>{{ price | currency:'EUR' }}</p>
    <p>{{ price | currency:'GBP':'symbol':'1.0-0' }}</p>
  `,
})
export class PriceComponent {
  price = 42.5;
}
```

### DecimalPipe and PercentPipe

```typescript
import { DecimalPipe, PercentPipe } from '@angular/common';

@Component({
  imports: [DecimalPipe, PercentPipe],
  template: `
    <p>{{ value | number:'1.2-2' }}</p>
    <p>{{ ratio | percent:'1.0-1' }}</p>
  `,
})
export class StatsComponent {
  value = 1234.5678;
  ratio = 0.856;
}
```

### Other Common Pipes

```typescript
import { UpperCasePipe, LowerCasePipe, TitleCasePipe, SlicePipe, JsonPipe, KeyValuePipe } from '@angular/common';

@Component({
  imports: [UpperCasePipe, LowerCasePipe, TitleCasePipe, SlicePipe, JsonPipe, KeyValuePipe],
  template: `
    <p>{{ name | uppercase }}</p>
    <p>{{ name | lowercase }}</p>
    <p>{{ name | titlecase }}</p>

    <!-- Slice array or string -->
    <p>{{ longText | slice:0:100 }}...</p>
    @for (item of items | slice:0:5; track item.id) {
      <span>{{ item.name }}</span>
    }

    <!-- Debug: show JSON -->
    <pre>{{ data | json }}</pre>

    <!-- Iterate over object -->
    @for (entry of config | keyvalue; track entry.key) {
      <p>{{ entry.key }}: {{ entry.value }}</p>
    }
  `,
})
export class DemoComponent {
  name = 'angular pipes';
  longText = 'Lorem ipsum dolor sit amet...';
  items: Item[] = [];
  data = { key: 'value' };
  config = { theme: 'dark', language: 'en' };
}
```

### AsyncPipe

```typescript
import { AsyncPipe } from '@angular/common';

@Component({
  imports: [AsyncPipe],
  template: `
    @if (users$ | async; as users) {
      @for (user of users; track user.id) {
        <p>{{ user.name }}</p>
      }
    } @else {
      <app-spinner />
    }
  `,
})
export class UserListComponent {
  private http = inject(HttpClient);
  users$ = this.http.get<User[]>('/api/users');
}
```

**Tip:** Prefer `toSignal()` over `AsyncPipe` when working with signals. AsyncPipe remains useful for template-only observable consumption.

## Custom Pipes

### Pure Pipe (Default)

Pure pipes only re-evaluate when their input reference changes.

```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'truncate',
})
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit = 50, trail = '...'): string {
    if (!value) return '';
    if (value.length <= limit) return value;
    return value.substring(0, limit).trim() + trail;
  }
}

// Usage: {{ description | truncate:100:'...' }}
```

### Pipe with Multiple Parameters

```typescript
@Pipe({
  name: 'fileSize',
})
export class FileSizePipe implements PipeTransform {
  transform(bytes: number, decimals = 1): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
  }
}

// Usage: {{ fileSize | fileSize:2 }}
```

### Filter Pipe

```typescript
@Pipe({
  name: 'filterBy',
})
export class FilterByPipe implements PipeTransform {
  transform<T>(items: T[], field: keyof T, value: unknown): T[] {
    if (!items || !field) return items;
    return items.filter(item => item[field] === value);
  }
}

// Usage: @for (user of users | filterBy:'role':'admin'; track user.id)
```

### Time Ago Pipe

```typescript
@Pipe({
  name: 'timeAgo',
})
export class TimeAgoPipe implements PipeTransform {
  transform(date: Date | string): string {
    const now = new Date();
    const past = new Date(date);
    const diffMs = now.getTime() - past.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);

    if (diffSec < 60) return 'just now';
    if (diffMin < 60) return `${diffMin}m ago`;
    if (diffHour < 24) return `${diffHour}h ago`;
    if (diffDay < 30) return `${diffDay}d ago`;
    return past.toLocaleDateString();
  }
}

// Usage: {{ post.createdAt | timeAgo }}
```

## Chaining Pipes

```typescript
// Pipes can be chained left to right
template: `
  <p>{{ user.name | uppercase | slice:0:10 }}</p>
  <p>{{ price | currency:'USD':'symbol':'1.0-0' }}</p>
  <p>{{ createdAt | date:'medium' | uppercase }}</p>
`
```

## Pipes vs Computed Signals

For derived data that depends on component state, prefer `computed()` signals over pipes:

```typescript
// Prefer computed for component-specific transformations
filteredItems = computed(() => {
  const query = this.searchQuery().toLowerCase();
  return this.items().filter(item => item.name.toLowerCase().includes(query));
});

// Use pipes for generic, reusable template formatting
// {{ value | currency }} {{ date | date:'short' }} {{ text | truncate:50 }}
```

For advanced pipe patterns, see [references/pipe-patterns.md](references/pipe-patterns.md).
