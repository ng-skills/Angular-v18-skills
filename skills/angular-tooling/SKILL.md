---
name: angular-tooling
description: Configure and use Angular v18 CLI, workspace settings, build optimization, and development tools. Covers ng generate, angular.json configuration, environment files, build budgets, and the application builder. Use when setting up projects, generating code, configuring builds, or optimizing bundle size. Do not use for runtime Angular APIs.
---

# Angular v18 Tooling

Angular v18 uses the application builder (`@angular-devkit/build-angular:application`) by default for new projects.

## Project Generation

```bash
# New project (standalone by default)
ng new my-app
ng new my-app --ssr           # With SSR
ng new my-app --style=scss    # With SCSS
ng new my-app --prefix=acme   # Custom selector prefix

# Generate components
ng generate component features/user-card
ng generate component shared/button --inline-style --inline-template

# Generate services
ng generate service core/auth
ng generate service data/user

# Generate other artifacts
ng generate pipe shared/truncate
ng generate directive shared/highlight
ng generate guard core/auth
ng generate interceptor core/auth
ng generate interface models/user
ng generate enum models/status
```

### Shorthand

```bash
ng g c features/user-card
ng g s core/auth
ng g p shared/truncate
ng g d shared/highlight
```

## Development Server

```bash
# Start dev server
ng serve
ng dev                      # Alias added in v18

# Options
ng serve --port 4200
ng serve --open             # Open browser
ng serve --ssl              # Enable HTTPS
ng serve --proxy-config proxy.conf.json
```

### Proxy Configuration

```json
// proxy.conf.json
{
  "/api": {
    "target": "http://localhost:3000",
    "secure": false,
    "changeOrigin": true
  }
}
```

## Application Builder (Default in v18)

The application builder uses esbuild + Vite for faster builds.

```json
// angular.json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:application",
          "options": {
            "outputPath": "dist/my-app",
            "index": "src/index.html",
            "browser": "src/main.ts",
            "polyfills": ["zone.js"],
            "tsConfig": "tsconfig.app.json",
            "assets": [
              { "glob": "**/*", "input": "public" }
            ],
            "styles": ["src/styles.scss"],
            "scripts": []
          },
          "configurations": {
            "production": {
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kB",
                  "maximumError": "1MB"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "4kB",
                  "maximumError": "8kB"
                }
              ],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular-devkit/build-angular:dev-server",
          "configurations": {
            "production": {
              "buildTarget": "my-app:build:production"
            },
            "development": {
              "buildTarget": "my-app:build:development"
            }
          },
          "defaultConfiguration": "development"
        }
      }
    }
  }
}
```

## Environment Files

```typescript
// src/environments/environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3000/api',
};

// src/environments/environment.prod.ts (production)
export const environment = {
  production: true,
  apiUrl: 'https://api.example.com',
};
```

Configure file replacement in `angular.json`:

```json
"configurations": {
  "production": {
    "fileReplacements": [
      {
        "replace": "src/environments/environment.ts",
        "with": "src/environments/environment.prod.ts"
      }
    ]
  }
}
```

## Build Commands

```bash
# Production build
ng build

# Development build
ng build --configuration development

# Analyze bundle size
ng build --stats-json
npx webpack-bundle-analyzer dist/my-app/stats.json

# Build with source maps
ng build --source-map
```

## Project Structure (Recommended)

```
src/
├── app/
│   ├── core/                    # Singleton services, guards, interceptors
│   │   ├── auth.service.ts
│   │   ├── auth.guard.ts
│   │   └── auth.interceptor.ts
│   ├── shared/                  # Reusable components, directives, pipes
│   │   ├── button/
│   │   │   └── button.component.ts
│   │   ├── highlight.directive.ts
│   │   └── truncate.pipe.ts
│   ├── features/                # Feature modules / route-based sections
│   │   ├── home/
│   │   │   ├── home.component.ts
│   │   │   └── home.routes.ts
│   │   ├── admin/
│   │   │   ├── admin.component.ts
│   │   │   ├── admin.routes.ts
│   │   │   └── components/
│   │   │       └── admin-dashboard.component.ts
│   │   └── user/
│   │       ├── user.component.ts
│   │       └── user.service.ts
│   ├── models/                  # Interfaces and types
│   │   └── user.interface.ts
│   ├── app.component.ts
│   ├── app.config.ts
│   └── app.routes.ts
├── environments/
│   ├── environment.ts
│   └── environment.prod.ts
├── public/                      # Static assets (new in v18, replaces assets/)
│   ├── favicon.ico
│   └── images/
├── styles.scss
├── index.html
└── main.ts
```

## File Naming Conventions

```
user-card.component.ts         # Component
auth.service.ts                # Service
auth.guard.ts                  # Guard
auth.interceptor.ts            # Interceptor
highlight.directive.ts         # Directive
truncate.pipe.ts               # Pipe
user.interface.ts              # Interface
app.routes.ts                  # Route definitions
app.config.ts                  # Application config
app.config.server.ts           # Server config
```

## TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "strict": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "paths": {
      "@app/*": ["./src/app/*"],
      "@env/*": ["./src/environments/*"]
    }
  }
}
```

## Useful CLI Commands

```bash
# Update Angular
ng update @angular/core @angular/cli

# Run tests
ng test
ng test --watch=false --code-coverage

# Lint (requires ESLint setup)
ng lint

# Build information
ng version
ng analytics info
```

## Migration from Webpack to Application Builder

```bash
# Automatic migration schematic
ng update @angular/cli --migrate-only use-application-builder
```

Key differences:
- `main` is renamed to `browser` in angular.json
- `assets` folder is now `public`
- Uses esbuild instead of webpack for faster builds
- Vite-based dev server with HMR support

For advanced tooling patterns, see [references/tooling-patterns.md](references/tooling-patterns.md).
