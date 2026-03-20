---
name: angular-v18
description: Build Angular v18 applications following official best practices. Covers standalone components, signal-based reactivity, dependency injection, routing, forms, HTTP, directives, pipes, testing, SSR, and tooling. Use for any Angular v18 development task. Do not use APIs from Angular 19+ (linkedSignal, resource, httpResource, Signal Forms, Vitest). Always use signal-based input()/output() instead of decorator-based @Input/@Output. Always use Reactive Forms instead of template-driven forms with ngModel.
---

# Angular v18 Developer Guidelines

1. Always analyze the project's Angular version before providing guidance, as best practices and available features vary between versions. These skills target **Angular v18** specifically.

2. When generating code, follow Angular's style guide and best practices. Use the Angular CLI for scaffolding components, services, directives, pipes, and routes.

3. All components, directives, and pipes are **standalone by default** — do NOT use NgModules for new code.

4. Always use signal-based `input()` / `output()` — do NOT use `@Input()` / `@Output()` decorators.

5. Always use built-in control flow (`@if`, `@for`, `@switch`) — do NOT use `*ngIf`, `*ngFor`, `*ngSwitch`.

6. Always use Reactive Forms — do NOT use template-driven forms (`FormsModule`, `ngModel`).

7. Use `inject()` function for dependency injection — avoid constructor-based injection.

8. Use `provideHttpClient()` — `HttpClientModule` is deprecated.

9. Use `host` metadata for host bindings — do NOT use `@HostBinding` / `@HostListener` decorators.

## Components

When working with Angular components, consult the following references based on the task:

- **Fundamentals**: Standalone components, inputs, outputs, host bindings, template control flow, deferrable views, content projection, view queries, lifecycle hooks, accessibility. Read [components.md](references/components.md)

## Reactivity and Data Management

When managing state and data reactivity, use Angular Signals:

- **Signals**: `signal()`, `computed()`, `effect()`, `untracked()`, read-only signals, RxJS interop (`toSignal`, `toObservable`), state management patterns. Read [signals.md](references/signals.md)

**Important:** `linkedSignal()` and `resource()` / `httpResource()` are NOT available in Angular v18 (Angular 19+). Use `toSignal()` with `HttpClient` observables for async data.

## Dependency Injection

When implementing dependency injection:

- **DI**: `inject()` function, service registration, `InjectionToken`, provider types, application config, multi-providers, scoped services. Read [dependency-injection.md](references/dependency-injection.md)

## Routing

When configuring navigation and routes:

- **Routing**: Route setup, lazy loading, signal-based route parameters, functional guards, resolvers, view transitions, title strategy, preloading. Read [routing.md](references/routing.md)

## Forms

Signal Forms are NOT available in v18. Always use Reactive Forms:

- **Forms**: Reactive Forms, typed forms, custom validators, form events, `ControlValueAccessor`, multi-step forms, auto-save. Read [forms.md](references/forms.md)

## HTTP

When making HTTP requests:

- **HTTP**: `provideHttpClient()`, functional interceptors, HTTP context tokens, generic CRUD services, caching, retry, polling. Read [http.md](references/http.md)

## Directives

When creating custom directives:

- **Directives**: Attribute directives, structural directives, directive composition API, intersection observer, debounce input. Read [directives.md](references/directives.md)

## Pipes

When transforming data in templates:

- **Pipes**: Built-in pipes, custom pipes, pipes vs computed signals, safe URL, highlight, relative time. Read [pipes.md](references/pipes.md)

## Testing

When writing tests:

- **Testing**: Component testing with `TestBed`, service testing with HTTP mocking, guard testing, component harnesses, provider overrides. Read [testing.md](references/testing.md)

## Server-Side Rendering

When implementing SSR:

- **SSR**: Setup, client hydration with event replay, SSR-safe DOM access, skip hydration, transfer state, meta tags/SEO. Read [ssr.md](references/ssr.md)

## Tooling

When scaffolding or configuring projects:

- **Tooling**: Angular CLI, application builder (esbuild + Vite), project structure, ESLint, bundle optimization, path aliases, migration commands. Read [tooling.md](references/tooling.md)

## APIs NOT Available in Angular v18

These APIs were introduced in later versions and must NOT be used:

- `linkedSignal()` (Angular 19+)
- `resource()` / `httpResource()` (Angular 19+)
- Signal Forms (Angular 20+)
- Vitest support (Angular 20+)
