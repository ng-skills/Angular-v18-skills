# Angular v18 Skills

Agent skills for building Angular v18 applications following official best practices and patterns.

## What are Skills?

Skills are structured instructions that help AI agents generate correct, idiomatic Angular v18 code. Each skill covers a specific area of Angular development.

## Installation

```bash
npx skills add ng-skills/Angular-v18-skills
```

The CLI will prompt you to choose which agents to install for. Skills are always installed to the **universal directory** (`.agents/skills/`), and you can additionally select agent-specific directories:

| Agent | Directory |
|-------|-----------|
| Universal (all agents) | `.agents/skills/` |
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/` |
| GitHub Copilot | `.github/copilot/skills/` |
| Codex | `.codex/skills/` |
| And 30+ more... | `.<agent>/skills/` |

## Skill

| Skill | Description |
|-------|-------------|
| [angular-v18](skills/angular-v18/) | Comprehensive Angular v18 development — components, signals, DI, routing, forms, HTTP, directives, pipes, testing, SSR, and tooling |

### Topics Covered

- **Components** — Standalone components with signal inputs/outputs, built-in control flow, OnPush change detection
- **Signals** — Reactive state with signal(), computed(), effect(), and RxJS interop
- **Dependency Injection** — inject() function, hierarchical injectors, InjectionToken
- **Routing** — Lazy loading, functional guards, resolvers, route parameters
- **Forms** — Reactive Forms with typed FormGroup and validation
- **HTTP** — provideHttpClient(), functional interceptors, error handling
- **Directives** — Attribute and structural directives, host bindings, directive composition
- **Pipes** — Built-in and custom pipes for template data transformation
- **Testing** — TestBed, component testing, service testing, HttpClient testing
- **SSR** — Server-side rendering with hydration, event replay, prerendering
- **Tooling** — Angular CLI, workspace configuration, build optimization

## Angular v18 Highlights

Angular v18 (released May 2024) stabilized several key APIs:

- **Built-in control flow** (`@if`, `@for`, `@switch`) — stable
- **Deferrable views** (`@defer`) — stable
- **Signals** (`signal()`, `computed()`) — stable
- **Signal inputs/outputs** (`input()`, `output()`) — developer preview
- **Standalone components** — default for new projects
- **Zoneless change detection** — experimental preview

### APIs NOT available in Angular v18

These APIs were introduced in later versions and are **not covered** by these skills:

- `linkedSignal()` (Angular 19+)
- `resource()` / `httpResource()` (Angular 19+)
- Signal Forms (Angular 20+)
- Vitest support (Angular 20+)

## License

MIT
