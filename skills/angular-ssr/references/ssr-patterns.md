# Advanced SSR Patterns — Angular v18

## SSR-Safe Service Pattern

```typescript
import { Injectable, inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser, isPlatformServer } from '@angular/common';

@Injectable({ providedIn: 'root' })
export class WindowService {
  private platformId = inject(PLATFORM_ID);

  get isBrowser(): boolean {
    return isPlatformBrowser(this.platformId);
  }

  get isServer(): boolean {
    return isPlatformServer(this.platformId);
  }

  get windowRef(): Window | null {
    return this.isBrowser ? window : null;
  }

  getLocalStorage(key: string): string | null {
    if (!this.isBrowser) return null;
    return localStorage.getItem(key);
  }

  setLocalStorage(key: string, value: string): void {
    if (this.isBrowser) {
      localStorage.setItem(key, value);
    }
  }

  scrollTo(x: number, y: number): void {
    if (this.isBrowser) {
      window.scrollTo(x, y);
    }
  }
}
```

## Lazy Loading Third-Party Libraries (SSR-Safe)

```typescript
@Component({
  selector: 'app-map',
  template: `
    <div #mapContainer class="map-container">
      @if (!mapLoaded()) {
        <div class="placeholder">Loading map...</div>
      }
    </div>
  `,
})
export class MapComponent {
  private mapContainer = viewChild.required<ElementRef>('mapContainer');
  mapLoaded = signal(false);

  constructor() {
    afterNextRender(async () => {
      // Dynamically import browser-only library
      const L = await import('leaflet');
      const map = L.map(this.mapContainer().nativeElement).setView([51.505, -0.09], 13);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
      this.mapLoaded.set(true);
    });
  }
}
```

## Meta Tags and SEO

```typescript
import { Meta, Title } from '@angular/platform-browser';

@Component({...})
export class ProductPageComponent {
  private meta = inject(Meta);
  private title = inject(Title);

  product = input.required<Product>();

  constructor() {
    effect(() => {
      const product = this.product();
      this.title.setTitle(`${product.name} - My Store`);
      this.meta.updateTag({ name: 'description', content: product.description });
      this.meta.updateTag({ property: 'og:title', content: product.name });
      this.meta.updateTag({ property: 'og:description', content: product.description });
      this.meta.updateTag({ property: 'og:image', content: product.imageUrl });
    });
  }
}
```

## Server Request Context

```typescript
// Access the server request in SSR
import { REQUEST } from '@angular/ssr/tokens';

@Injectable({ providedIn: 'root' })
export class ServerContextService {
  private request = inject(REQUEST, { optional: true });

  getUserAgent(): string {
    return this.request?.headers?.['user-agent'] ?? '';
  }

  isMobile(): boolean {
    const ua = this.getUserAgent();
    return /mobile|android|iphone/i.test(ua);
  }

  getAcceptLanguage(): string {
    return this.request?.headers?.['accept-language'] ?? 'en';
  }
}
```

## Conditional Rendering for SSR

```typescript
@Component({
  template: `
    <!-- Always rendered on server and client -->
    <h1>{{ title() }}</h1>

    <!-- Only rendered in browser (uses afterNextRender) -->
    @if (isBrowser()) {
      <app-interactive-chart [data]="chartData()" />
    } @else {
      <img [src]="chartImageUrl()" alt="Static chart preview" />
    }

    <!-- Defer loading until browser is idle -->
    @defer (on idle) {
      <app-analytics-tracker />
    } @placeholder {
      <!-- Rendered on server and during SSR -->
      <div></div>
    }
  `,
})
export class DashboardComponent {
  private platformId = inject(PLATFORM_ID);

  title = input.required<string>();
  chartData = input.required<ChartData>();

  isBrowser = signal(false);
  chartImageUrl = computed(() => `/api/chart-image?data=${encodeURIComponent(JSON.stringify(this.chartData()))}`);

  constructor() {
    afterNextRender(() => {
      this.isBrowser.set(true);
    });
  }
}
```

## Prerendering with Dynamic Routes

```typescript
// angular.json
{
  "build": {
    "options": {
      "prerender": {
        "discoverRoutes": true,  // Auto-discover routes from router config
        "routesFile": "prerender-routes.txt"
      }
    }
  }
}

// prerender-routes.txt
/
/about
/contact
/blog/post-1
/blog/post-2
/products/widget-a
/products/widget-b
```

## Transfer State for Custom Data

```typescript
import { TransferState, makeStateKey } from '@angular/core';

const CONFIG_KEY = makeStateKey<AppConfig>('appConfig');

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private transferState = inject(TransferState);
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID);

  private _config = signal<AppConfig | null>(null);
  readonly config = this._config.asReadonly();

  async loadConfig(): Promise<void> {
    // Check if data was transferred from server
    const cached = this.transferState.get(CONFIG_KEY, null);
    if (cached) {
      this._config.set(cached);
      this.transferState.remove(CONFIG_KEY);
      return;
    }

    // Fetch from API
    const config = await firstValueFrom(
      this.http.get<AppConfig>('/api/config')
    );

    this._config.set(config);

    // Store for transfer to client
    if (isPlatformServer(this.platformId)) {
      this.transferState.set(CONFIG_KEY, config);
    }
  }
}
```
