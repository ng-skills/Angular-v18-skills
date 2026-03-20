# Angular v18 Tooling

## Project Generation

```bash
ng new my-app
ng new my-app --ssr --style=scss --prefix=acme

ng generate component features/user-card
ng generate service core/auth
ng generate pipe shared/truncate
ng generate guard core/auth
```

## Application Builder (Default in v18)

Uses esbuild + Vite for faster builds.

```json
{
  "builder": "@angular-devkit/build-angular:application",
  "options": {
    "outputPath": "dist/my-app",
    "index": "src/index.html",
    "browser": "src/main.ts",
    "polyfills": ["zone.js"]
  }
}
```

## Project Structure

```
src/app/
├── core/          # Singleton services, guards, interceptors
├── shared/        # Reusable components, directives, pipes
├── features/      # Feature modules / route-based sections
├── models/        # Interfaces and types
├── app.component.ts
├── app.config.ts
└── app.routes.ts
```

## ESLint Configuration

```bash
ng add @angular-eslint/schematics
```

## Bundle Optimization

```typescript
// GOOD: Import specific functions
import { map, filter, switchMap } from 'rxjs';
// BAD: import * as rxjs from 'rxjs';
```

## Path Aliases

```json
{
  "compilerOptions": {
    "paths": {
      "@app/*": ["./src/app/*"],
      "@core/*": ["./src/app/core/*"],
      "@shared/*": ["./src/app/shared/*"],
      "@env/*": ["./src/environments/*"]
    }
  }
}
```

## Migration Commands

```bash
ng update @angular/cli --migrate-only use-application-builder
ng generate @angular/core:standalone
ng generate @angular/core:control-flow
ng generate @angular/core:signal-input-migration
ng generate @angular/core:inject-migration
```
