---
name: angular-ssr
description: Implement server-side rendering in Angular v18 with hydration, event replay, prerendering, and SSR-safe DOM access. Use when setting up SSR, configuring hydration, prerendering routes, or handling platform-specific code. Do not use for client-only applications or incremental hydration which is not stable in v18.
---

# Angular v18 Server-Side Rendering

Angular v18 SSR uses the application builder with hydration support and event replay.

## Setup

```bash
# New project with SSR
ng new my-app --ssr

# Add SSR to existing project
ng add @angular/ssr
```

This generates:
- `src/app/app.config.server.ts` — server-specific providers
- `src/main.server.ts` — server entry point
- `server.ts` — Express server

## App Configuration

```typescript
// app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()),
    provideClientHydration(withEventReplay()),
  ],
};

// app.config.server.ts
import { mergeApplicationConfig, ApplicationConfig } from '@angular/core';
import { provideServerRendering } from '@angular/platform-server';
import { appConfig } from './app.config';

const serverConfig: ApplicationConfig = {
  providers: [
    provideServerRendering(),
  ],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
```

## Hydration

Hydration reuses server-rendered DOM instead of re-creating it. Enabled via `provideClientHydration()`.

### Event Replay (New in v18)

Events that occur before hydration completes are captured and replayed after the app becomes interactive.

```typescript
provideClientHydration(
  withEventReplay(), // Replay user events during hydration
)
```

### Skip Hydration

For components that cannot be hydrated (e.g., third-party libraries that manipulate the DOM):

```typescript
@Component({
  selector: 'app-chart',
  host: { 'ngSkipHydration': '' },
  template: `<div #chartContainer></div>`,
})
export class ChartComponent {
  constructor() {
    afterNextRender(() => {
      // Initialize third-party chart library
    });
  }
}

// Or in parent template:
// <app-chart ngSkipHydration />
```

## SSR-Safe DOM Access

Never access DOM APIs directly. Use `afterNextRender` and `afterRender` for browser-only code.

```typescript
import { afterNextRender, afterRender, PLATFORM_ID, isPlatformBrowser } from '@angular/core';

@Component({...})
export class MapComponent {
  private platformId = inject(PLATFORM_ID);

  constructor() {
    // Runs once after first browser render (SSR-safe)
    afterNextRender(() => {
      this.initializeMap();
    });

    // Runs after every render (SSR-safe)
    afterRender(() => {
      this.updateMapMarkers();
    });
  }

  // Alternative: platform check
  doSomething() {
    if (isPlatformBrowser(this.platformId)) {
      window.scrollTo(0, 0);
    }
  }
}
```

## Prerendering (SSG)

Prerender static routes at build time.

```typescript
// angular.json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:application",
          "options": {
            "prerender": {
              "routesFile": "routes.txt"
            }
          }
        }
      }
    }
  }
}

// routes.txt — one route per line
/
/about
/contact
/products/1
/products/2
```

### Dynamic Prerender Routes

```typescript
// prerender-routes.ts
// This script generates routes for prerendering
async function getRoutes(): Promise<string[]> {
  const response = await fetch('https://api.example.com/products');
  const products = await response.json();
  return products.map((p: any) => `/products/${p.id}`);
}
```

## Transfer State

HTTP responses are automatically cached during SSR and reused on the client to avoid duplicate requests. This works automatically with `provideHttpClient()` and `provideClientHydration()`.

```typescript
// No additional setup needed — automatic with hydration
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withFetch()),
    provideClientHydration(),
  ],
};
```

For requests that should NOT be cached:

```typescript
import { HttpContextToken, HttpContext } from '@angular/common/http';

export const SKIP_TRANSFER_STATE = new HttpContextToken<boolean>(() => false);

// In service
this.http.get('/api/realtime-data', {
  context: new HttpContext().set(SKIP_TRANSFER_STATE, true),
});
```

## Platform-Specific Services

```typescript
import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser, isPlatformServer } from '@angular/common';

@Injectable({ providedIn: 'root' })
export class StorageService {
  private platformId = inject(PLATFORM_ID);

  get(key: string): string | null {
    if (isPlatformBrowser(this.platformId)) {
      return localStorage.getItem(key);
    }
    return null;
  }

  set(key: string, value: string): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.setItem(key, value);
    }
  }
}
```

## Server Configuration (Express)

```typescript
// server.ts
import { CommonEngine } from '@angular/ssr';
import express from 'express';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import bootstrap from './src/main.server';

export function app(): express.Express {
  const server = express();
  const serverDistFolder = dirname(fileURLToPath(import.meta.url));
  const browserDistFolder = resolve(serverDistFolder, '../browser');
  const indexHtml = join(serverDistFolder, 'index.server.html');

  const commonEngine = new CommonEngine();

  server.set('view engine', 'html');
  server.set('views', browserDistFolder);

  // Serve static files
  server.get('*.*', express.static(browserDistFolder, { maxAge: '1y' }));

  // All regular routes use the Angular engine
  server.get('*', (req, res, next) => {
    commonEngine
      .render({
        bootstrap,
        documentFilePath: indexHtml,
        url: `${req.protocol}://${req.headers.host}${req.originalUrl}`,
        publicPath: browserDistFolder,
        providers: [{ provide: 'REQUEST', useValue: req }],
      })
      .then((html) => res.send(html))
      .catch((err) => next(err));
  });

  return server;
}
```

## i18n with SSR (Improved in v18)

Angular v18 improved i18n hydration support, ensuring translated content hydrates correctly.

```typescript
// angular.json
{
  "i18n": {
    "sourceLocale": "en",
    "locales": {
      "fr": "src/locale/messages.fr.xlf",
      "de": "src/locale/messages.de.xlf"
    }
  }
}
```

For advanced SSR patterns, see [references/ssr-patterns.md](references/ssr-patterns.md).
