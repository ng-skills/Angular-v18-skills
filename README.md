# Angular v18 Skills

Agent skills for building Angular v18 applications following official best practices and patterns.

## What are Skills?

Skills are structured instructions that help AI agents generate correct, idiomatic Angular v18 code. Each skill covers a specific area of Angular development.

## Installation

### Option 1: Install to `.claude/skills/` (via CLI)

Install all skills:

```bash
npx skills add ng-skills/Angular-v18-skills
```

Install a specific skill:

```bash
npx skills add ng-skills/Angular-v18-skills/skills/angular-component
npx skills add ng-skills/Angular-v18-skills/skills/angular-signals
npx skills add ng-skills/Angular-v18-skills/skills/angular-routing
```

### Option 2: Install to `.github/skills/` (manual)

If you prefer storing skills under `.github/` (e.g. for GitHub-centric workflows):

```bash
git clone https://github.com/ng-skills/Angular-v18-skills.git /tmp/angular-skills
mkdir -p .github/skills
cp -r /tmp/angular-skills/skills/* .github/skills/
rm -rf /tmp/angular-skills
```

Or add as a git submodule:

```bash
git submodule add https://github.com/ng-skills/Angular-v18-skills.git .github/skills/angular-v18
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [angular-component](skills/angular-component/) | Standalone components with signal inputs/outputs (developer preview), built-in control flow, and OnPush change detection |
| [angular-signals](skills/angular-signals/) | Reactive state management with signal(), computed(), effect(), and RxJS interop |
| [angular-di](skills/angular-di/) | Dependency injection with inject() function, hierarchical injectors, and InjectionToken |
| [angular-routing](skills/angular-routing/) | Routing with lazy loading, functional guards, resolvers, and route parameters |
| [angular-forms](skills/angular-forms/) | Reactive Forms and Template-driven Forms with typed FormGroup and validation |
| [angular-http](skills/angular-http/) | HttpClient with provideHttpClient(), functional interceptors, and error handling |
| [angular-directives](skills/angular-directives/) | Attribute and structural directives with host bindings and directive composition |
| [angular-pipes](skills/angular-pipes/) | Built-in and custom pipes for template data transformation |
| [angular-testing](skills/angular-testing/) | TestBed, component testing, service testing, and HttpClient testing |
| [angular-ssr](skills/angular-ssr/) | Server-side rendering with hydration, event replay, and prerendering |
| [angular-tooling](skills/angular-tooling/) | Angular CLI commands, workspace configuration, and build optimization |

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
