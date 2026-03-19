# Advanced Routing Patterns — Angular v18

## Feature Route Organization

```typescript
// features/admin/admin.routes.ts
export const adminRoutes: Routes = [
  {
    path: '',
    component: AdminLayoutComponent,
    canActivate: [authGuard, roleGuard(['admin'])],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: AdminDashboardComponent },
      {
        path: 'users',
        children: [
          { path: '', component: UserListComponent },
          { path: ':id', component: UserDetailComponent, resolve: { user: userResolver } },
          { path: ':id/edit', component: UserEditComponent, canDeactivate: [unsavedChangesGuard] },
        ],
      },
      {
        path: 'settings',
        loadComponent: () => import('./settings/admin-settings.component')
          .then(m => m.AdminSettingsComponent),
      },
    ],
  },
];

// app.routes.ts
export const routes: Routes = [
  { path: '', component: HomeComponent },
  {
    path: 'admin',
    loadChildren: () => import('./features/admin/admin.routes').then(m => m.adminRoutes),
  },
];
```

## Route Transition Animations

```typescript
import { provideRouter, withViewTransitions } from '@angular/router';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(
      routes,
      withViewTransitions(),         // Enable View Transitions API
      withComponentInputBinding(),
    ),
  ],
};
```

## Title Strategy

```typescript
import { TitleStrategy, RouterStateSnapshot } from '@angular/router';

@Injectable()
export class AppTitleStrategy extends TitleStrategy {
  override updateTitle(routerState: RouterStateSnapshot): void {
    const title = this.buildTitle(routerState);
    document.title = title ? `${title} | My App` : 'My App';
  }
}

// Provide
providers: [
  { provide: TitleStrategy, useClass: AppTitleStrategy },
]

// Route config
{ path: 'about', component: AboutComponent, title: 'About Us' }
{ path: 'users/:id', component: UserComponent, title: userTitleResolver }

// Dynamic title resolver
export const userTitleResolver: ResolveFn<string> = (route) => {
  const userService = inject(UserService);
  return userService.getById(route.paramMap.get('id')!).pipe(
    map(user => user.name)
  );
};
```

## Router Preloading Strategies

```typescript
import { provideRouter, withPreloading, PreloadAllModules } from '@angular/router';

// Preload all lazy routes
provideRouter(routes, withPreloading(PreloadAllModules))

// Custom preloading — only preload routes with data.preload: true
@Injectable({ providedIn: 'root' })
export class SelectivePreloadingStrategy implements PreloadingStrategy {
  preload(route: Route, load: () => Observable<any>): Observable<any> {
    return route.data?.['preload'] ? load() : of(null);
  }
}

provideRouter(routes, withPreloading(SelectivePreloadingStrategy))

// Route config
{
  path: 'dashboard',
  loadComponent: () => import('./dashboard.component'),
  data: { preload: true }, // This route will be preloaded
}
```

## Breadcrumb Pattern

```typescript
// Routes with breadcrumb data
export const routes: Routes = [
  {
    path: 'products',
    data: { breadcrumb: 'Products' },
    children: [
      { path: '', component: ProductListComponent },
      {
        path: ':id',
        component: ProductDetailComponent,
        data: { breadcrumb: 'Product Detail' },
      },
    ],
  },
];

// Breadcrumb component
@Component({
  selector: 'app-breadcrumbs',
  imports: [RouterLink],
  template: `
    <nav aria-label="breadcrumb">
      @for (crumb of breadcrumbs(); track crumb.url; let last = $last) {
        @if (!last) {
          <a [routerLink]="crumb.url">{{ crumb.label }}</a>
          <span>/</span>
        } @else {
          <span aria-current="page">{{ crumb.label }}</span>
        }
      }
    </nav>
  `,
})
export class BreadcrumbsComponent {
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  breadcrumbs = toSignal(
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd),
      map(() => this.buildBreadcrumbs(this.route.root))
    ),
    { initialValue: [] }
  );

  private buildBreadcrumbs(route: ActivatedRoute, url = '', crumbs: Breadcrumb[] = []): Breadcrumb[] {
    const children = route.children;
    for (const child of children) {
      const routeURL = child.snapshot.url.map(s => s.path).join('/');
      if (routeURL) url += `/${routeURL}`;

      const label = child.snapshot.data['breadcrumb'];
      if (label) crumbs.push({ label, url });

      this.buildBreadcrumbs(child, url, crumbs);
    }
    return crumbs;
  }
}
```

## Auth Redirect After Login

```typescript
@Component({...})
export class LoginComponent {
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private auth = inject(AuthService);

  async onLogin(credentials: Credentials) {
    await this.auth.login(credentials);

    // Redirect to the originally requested URL
    const returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';
    this.router.navigateByUrl(returnUrl);
  }
}
```

## Error Handling with Router

```typescript
export const routes: Routes = [
  // ... routes
  { path: 'not-found', component: NotFoundComponent },
  { path: 'forbidden', component: ForbiddenComponent },
  { path: 'error', component: ErrorComponent },
  { path: '**', redirectTo: '/not-found' },
];

// Global error handler
provideRouter(
  routes,
  withNavigationErrorHandler((error) => {
    const router = inject(Router);
    router.navigate(['/error'], {
      queryParams: { message: error.message },
    });
  })
)
```
