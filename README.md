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

### Reference Files

The skill uses a modular structure where `SKILL.md` acts as a routing guide and each reference file covers a specific topic:

| Reference | Description |
|-----------|-------------|
| [components.md](skills/angular-v18/references/components.md) | Standalone components, inputs, outputs, host bindings, control flow, deferrable views, content projection, accessibility |
| [signals.md](skills/angular-v18/references/signals.md) | signal(), computed(), effect(), RxJS interop, state management patterns |
| [dependency-injection.md](skills/angular-v18/references/dependency-injection.md) | inject() function, InjectionToken, providers, application config |
| [routing.md](skills/angular-v18/references/routing.md) | Lazy loading, functional guards, resolvers, view transitions |
| [forms.md](skills/angular-v18/references/forms.md) | Reactive Forms, typed forms, validators, ControlValueAccessor |
| [http.md](skills/angular-v18/references/http.md) | provideHttpClient(), functional interceptors, caching, retry |
| [directives.md](skills/angular-v18/references/directives.md) | Attribute/structural directives, directive composition API |
| [pipes.md](skills/angular-v18/references/pipes.md) | Built-in and custom pipes for template data transformation |
| [testing.md](skills/angular-v18/references/testing.md) | TestBed, component/service/guard testing, component harnesses |
| [ssr.md](skills/angular-v18/references/ssr.md) | Server-side rendering, hydration, event replay, transfer state |
| [tooling.md](skills/angular-v18/references/tooling.md) | Angular CLI, esbuild + Vite builder, project structure, migrations |

## Angular v18 Highlights

Angular v18 (released May 2024) stabilized several key APIs:

- **Built-in control flow** (`@if`, `@for`, `@switch`) — stable
- **Deferrable views** (`@defer`) — stable
- **Signals** (`signal()`, `computed()`) — stable
- **Signal inputs/outputs/model/queries** (`input()`, `output()`, `model()`, `viewChild()`) — stable
- **Standalone components** — requires explicit `standalone: true` (became default in v19)
- **Zoneless change detection** — experimental preview

### APIs NOT available in Angular v18

These APIs were introduced in later versions and are **not covered** by these skills:

- `linkedSignal()` (Angular 19+)
- `resource()` / `httpResource()` (Angular 19+)
- Signal Forms (Angular 20+)
- Vitest support (Angular 20+)

## License

MIT
