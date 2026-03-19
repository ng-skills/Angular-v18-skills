---
name: angular-di
description: Implement dependency injection in Angular v18 using the inject() function, hierarchical injectors, InjectionToken, and provider configuration. Use when creating services, configuring providers, using injection tokens, or setting up hierarchical dependency injection. Do not use for component creation, routing, or forms.
---

# Angular v18 Dependency Injection

Use the `inject()` function for all dependency injection. Avoid constructor-based injection for new code.

## inject() Function

```typescript
import { Component, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute, Router } from '@angular/router';

@Component({...})
export class UserDetailComponent {
  private http = inject(HttpClient);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private userService = inject(UserService);
}
```

## Service Registration

### Root-Level (Singleton)

```typescript
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);

  login(credentials: Credentials) {
    return this.http.post<AuthResponse>('/api/login', credentials);
  }
}
```

### Component-Level (Per Instance)

```typescript
@Component({
  selector: 'app-form',
  providers: [FormValidationService],
  template: `...`,
})
export class FormComponent {
  private validator = inject(FormValidationService);
}
```

## InjectionToken

```typescript
import { InjectionToken, inject } from '@angular/core';

// Define token with factory (self-providing)
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL', {
  providedIn: 'root',
  factory: () => 'https://api.example.com',
});

// Define token without factory
export const FEATURE_FLAGS = new InjectionToken<FeatureFlags>('FEATURE_FLAGS');

// Use in service
@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = inject(API_BASE_URL);
  private http = inject(HttpClient);

  get<T>(path: string) {
    return this.http.get<T>(`${this.baseUrl}${path}`);
  }
}

// Provide value in app config
export const appConfig: ApplicationConfig = {
  providers: [
    { provide: API_BASE_URL, useValue: 'https://api.prod.example.com' },
    { provide: FEATURE_FLAGS, useValue: { darkMode: true, beta: false } },
  ],
};
```

## Provider Types

```typescript
providers: [
  // useClass — provide a class implementation
  { provide: Logger, useClass: ConsoleLogger },

  // useValue — provide a static value
  { provide: API_URL, useValue: 'https://api.example.com' },

  // useFactory — provide via factory function
  {
    provide: DataService,
    useFactory: () => {
      const http = inject(HttpClient);
      const config = inject(APP_CONFIG);
      return new DataService(http, config.apiUrl);
    },
  },

  // useExisting — alias to another provider
  { provide: AbstractLogger, useExisting: ConsoleLogger },
]
```

## Optional and Self Injection

```typescript
import { inject } from '@angular/core';

// Optional — returns null if not found
private analytics = inject(AnalyticsService, { optional: true });

// Self — only look in own injector
private config = inject(CONFIG_TOKEN, { self: true });

// SkipSelf — skip own injector, look in parent
private parentConfig = inject(CONFIG_TOKEN, { skipSelf: true });

// Host — only look up to host component
private hostRef = inject(ElementRef, { host: true });
```

## Hierarchical Injectors

```typescript
// Parent provides service
@Component({
  selector: 'app-dashboard',
  providers: [DashboardStateService],
  template: `
    <app-sidebar />
    <app-main-content />
  `,
})
export class DashboardComponent {}

// Children share the same instance
@Component({
  selector: 'app-sidebar',
  template: `...`,
})
export class SidebarComponent {
  // Gets DashboardStateService from parent
  private state = inject(DashboardStateService);
}
```

## Environment Injectors

```typescript
import { createEnvironmentInjector, EnvironmentInjector } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class PluginService {
  private parentInjector = inject(EnvironmentInjector);

  loadPlugin(pluginProviders: Provider[]) {
    const injector = createEnvironmentInjector(
      pluginProviders,
      this.parentInjector
    );
    return injector.get(PluginInterface);
  }
}
```

## Application Config Pattern

```typescript
// app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { routes } from './app.routes';
import { authInterceptor } from './interceptors/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimationsAsync(),
  ],
};

// main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

bootstrapApplication(AppComponent, appConfig);
```

## Abstract Service Pattern

```typescript
// Define abstract interface
export abstract class NotificationService {
  abstract show(message: string, type: 'success' | 'error'): void;
  abstract dismiss(): void;
}

// Concrete implementation
@Injectable()
export class ToastNotificationService extends NotificationService {
  show(message: string, type: 'success' | 'error') { /* toast logic */ }
  dismiss() { /* dismiss logic */ }
}

// Provide implementation
providers: [
  { provide: NotificationService, useClass: ToastNotificationService },
]

// Consume via abstract type
private notifications = inject(NotificationService);
```

For advanced DI patterns, see [references/di-patterns.md](references/di-patterns.md).
