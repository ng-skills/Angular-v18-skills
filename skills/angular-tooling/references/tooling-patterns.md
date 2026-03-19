# Advanced Tooling Patterns — Angular v18

## Custom Schematic for Code Generation

```bash
# Create a schematic library
npm init @angular-devkit/schematics my-schematics
```

## ESLint Configuration

```bash
# Add ESLint to project
ng add @angular-eslint/schematics
```

```json
// .eslintrc.json
{
  "root": true,
  "overrides": [
    {
      "files": ["*.ts"],
      "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended",
        "plugin:@angular-eslint/recommended",
        "plugin:@angular-eslint/template/process-inline-templates"
      ],
      "rules": {
        "@angular-eslint/directive-selector": [
          "error",
          { "type": "attribute", "prefix": "app", "style": "camelCase" }
        ],
        "@angular-eslint/component-selector": [
          "error",
          { "type": "element", "prefix": "app", "style": "kebab-case" }
        ]
      }
    },
    {
      "files": ["*.html"],
      "extends": [
        "plugin:@angular-eslint/template/recommended",
        "plugin:@angular-eslint/template/accessibility"
      ]
    }
  ]
}
```

## Bundle Optimization

### Analyze Bundle Size

```bash
ng build --stats-json
npx webpack-bundle-analyzer dist/my-app/stats.json
```

### Tree-Shaking Tips

```typescript
// GOOD: Import specific functions
import { map, filter, switchMap } from 'rxjs';

// BAD: Barrel imports pull in everything
// import * as rxjs from 'rxjs';
```

### Lazy Loading Routes

```typescript
// Split code by route for smaller initial bundles
export const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.adminRoutes),
  },
  {
    path: 'reports',
    loadComponent: () => import('./reports/reports.component').then(m => m.ReportsComponent),
  },
];
```

### @defer for Component-Level Lazy Loading

```html
<!-- Lazy load heavy components at the template level -->
@defer (on viewport) {
  <app-heavy-dashboard />
} @placeholder {
  <div class="skeleton"></div>
}
```

## Build Budgets

```json
// angular.json
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
  },
  {
    "type": "anyScript",
    "maximumWarning": "100kB",
    "maximumError": "200kB"
  }
]
```

## Path Aliases

```json
// tsconfig.json
{
  "compilerOptions": {
    "paths": {
      "@app/*": ["./src/app/*"],
      "@core/*": ["./src/app/core/*"],
      "@shared/*": ["./src/app/shared/*"],
      "@features/*": ["./src/app/features/*"],
      "@models/*": ["./src/app/models/*"],
      "@env/*": ["./src/environments/*"]
    }
  }
}
```

Usage:

```typescript
import { AuthService } from '@core/auth.service';
import { ButtonComponent } from '@shared/button/button.component';
import { User } from '@models/user.interface';
import { environment } from '@env/environment';
```

## Workspace Libraries

```bash
# Generate a shared library
ng generate library shared-ui

# Generate a library component
ng generate component button --project=shared-ui
```

```json
// tsconfig.json paths for library
{
  "paths": {
    "shared-ui": ["dist/shared-ui"],
    "shared-ui/*": ["dist/shared-ui/*"]
  }
}
```

## Migration Commands

```bash
# Migrate to application builder
ng update @angular/cli --migrate-only use-application-builder

# Migrate to standalone components
ng generate @angular/core:standalone

# Migrate to built-in control flow
ng generate @angular/core:control-flow

# Migrate to signal inputs
ng generate @angular/core:signal-input-migration

# Migrate from HttpClientModule to provideHttpClient
ng generate @angular/core:inject-migration
```

## Testing Configuration

```json
// angular.json test configuration
"test": {
  "builder": "@angular-devkit/build-angular:karma",
  "options": {
    "polyfills": ["zone.js", "zone.js/testing"],
    "tsConfig": "tsconfig.spec.json",
    "assets": [
      { "glob": "**/*", "input": "public" }
    ],
    "styles": ["src/styles.scss"],
    "codeCoverage": true,
    "codeCoverageExclude": [
      "src/test-setup.ts",
      "**/*.spec.ts"
    ]
  }
}

// karma.conf.js
module.exports = function (config) {
  config.set({
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    reporters: ['progress', 'coverage'],
    coverageReporter: {
      dir: require('path').join(__dirname, './coverage'),
      reporters: [
        { type: 'html' },
        { type: 'text-summary' },
        { type: 'lcov' },
      ],
    },
    browsers: ['ChromeHeadless'],
    singleRun: true,
  });
};
```
