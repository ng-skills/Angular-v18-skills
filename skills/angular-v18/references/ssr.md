# Angular v18 Server-Side Rendering

## Setup

```bash
ng new my-app --ssr
ng add @angular/ssr
```

## App Configuration

```typescript
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()),
    provideClientHydration(withEventReplay()),
  ],
};
```

## SSR-Safe DOM Access

Never access DOM APIs directly. Use `afterNextRender` and `afterRender`.

```typescript
@Component({...})
export class MapComponent {
  private platformId = inject(PLATFORM_ID);

  constructor() {
    afterNextRender(() => { this.initializeMap(); });
  }

  doSomething() {
    if (isPlatformBrowser(this.platformId)) {
      window.scrollTo(0, 0);
    }
  }
}
```

## Skip Hydration

```typescript
@Component({
  host: { 'ngSkipHydration': '' },
})
export class ChartComponent {}
// Or: <app-chart ngSkipHydration />
```

## Transfer State

HTTP responses are automatically cached during SSR with `provideHttpClient()` + `provideClientHydration()`.

---

## SSR Patterns

### SSR-Safe Service

```typescript
@Injectable({ providedIn: 'root' })
export class WindowService {
  private platformId = inject(PLATFORM_ID);
  get isBrowser() { return isPlatformBrowser(this.platformId); }
  get windowRef() { return this.isBrowser ? window : null; }
  scrollTo(x: number, y: number) { if (this.isBrowser) window.scrollTo(x, y); }
}
```

### Meta Tags and SEO

```typescript
@Component({...})
export class ProductPageComponent {
  private meta = inject(Meta);
  private title = inject(Title);
  product = input.required<Product>();

  constructor() {
    effect(() => {
      const p = this.product();
      this.title.setTitle(`${p.name} - My Store`);
      this.meta.updateTag({ name: 'description', content: p.description });
      this.meta.updateTag({ property: 'og:title', content: p.name });
    });
  }
}
```

### Transfer State for Custom Data

```typescript
const CONFIG_KEY = makeStateKey<AppConfig>('appConfig');

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private transferState = inject(TransferState);
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID);

  async loadConfig() {
    const cached = this.transferState.get(CONFIG_KEY, null);
    if (cached) { this.transferState.remove(CONFIG_KEY); return cached; }
    const config = await firstValueFrom(this.http.get<AppConfig>('/api/config'));
    if (isPlatformServer(this.platformId)) this.transferState.set(CONFIG_KEY, config);
    return config;
  }
}
```
