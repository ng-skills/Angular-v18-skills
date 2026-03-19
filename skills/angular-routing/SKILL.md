---
name: angular-routing
description: Implement routing in Angular v18 applications with lazy loading, functional guards, resolvers, and route parameters. Use for navigation setup, protected routes, route-based data loading, nested routing, and @defer-based lazy loading. Triggers on route configuration, adding guards, implementing lazy loading, or reading route parameters. Do not use for component creation or forms.
---

# Angular v18 Routing

Configure routing with lazy loading, functional guards, and signal-based route parameters.

## Basic Setup

```typescript
// app.routes.ts
import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: 'about', component: AboutComponent },
  { path: '**', component: NotFoundComponent },
];

// app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
  ],
};

// app.component.ts
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <nav>
      <a routerLink="/home" routerLinkActive="active">Home</a>
      <a routerLink="/about" routerLinkActive="active">About</a>
    </nav>
    <router-outlet />
  `,
})
export class AppComponent {}
```

## Lazy Loading

```typescript
export const routes: Routes = [
  { path: 'home', component: HomeComponent },

  // Lazy load child routes
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.adminRoutes),
  },

  // Lazy load single component
  {
    path: 'settings',
    loadComponent: () => import('./settings/settings.component').then(m => m.SettingsComponent),
  },
];

// admin/admin.routes.ts
export const adminRoutes: Routes = [
  { path: '', component: AdminDashboardComponent },
  { path: 'users', component: AdminUsersComponent },
];
```

## Route Parameters

### With Signal Inputs (Recommended, Developer Preview)

Enable `withComponentInputBinding()` to bind route params directly to component inputs.

```typescript
// app.config.ts
import { provideRouter, withComponentInputBinding } from '@angular/router';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
  ],
};

// Route: { path: 'users/:id', component: UserDetailComponent }
@Component({...})
export class UserDetailComponent {
  id = input.required<string>();
  userId = computed(() => parseInt(this.id(), 10));
}
```

### Query Parameters as Inputs

```typescript
// Route: /search?q=angular&page=1
@Component({...})
export class SearchComponent {
  q = input<string>('');
  page = input<string>('1');
  currentPage = computed(() => parseInt(this.page(), 10));
}
```

### With ActivatedRoute (Stable Alternative)

```typescript
import { ActivatedRoute } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

@Component({...})
export class UserDetailComponent {
  private route = inject(ActivatedRoute);

  id = toSignal(
    this.route.paramMap.pipe(map(params => params.get('id'))),
    { initialValue: null }
  );
}
```

## Route Redirects as Functions (New in v18)

```typescript
export const routes: Routes = [
  {
    path: 'legacy-path',
    redirectTo: ({ queryParams }) => {
      const id = queryParams['id'];
      return id ? `/new-path/${id}` : '/new-path';
    },
  },
];
```

## Functional Guards

### Auth Guard

```typescript
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) {
    return true;
  }

  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url },
  });
};

// Usage
{ path: 'dashboard', component: DashboardComponent, canActivate: [authGuard] }
```

### Role Guard (Factory Pattern)

```typescript
export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return (route, state) => {
    const auth = inject(AuthService);
    const router = inject(Router);

    const userRole = auth.currentUser()?.role;
    if (userRole && allowedRoles.includes(userRole)) {
      return true;
    }
    return router.createUrlTree(['/unauthorized']);
  };
};

// Usage
{ path: 'admin', component: AdminComponent, canActivate: [authGuard, roleGuard(['admin'])] }
```

### Unsaved Changes Guard

```typescript
export interface HasUnsavedChanges {
  hasUnsavedChanges: () => boolean;
}

export const unsavedChangesGuard: CanDeactivateFn<HasUnsavedChanges> = (component) => {
  if (!component.hasUnsavedChanges()) {
    return true;
  }
  return confirm('You have unsaved changes. Leave anyway?');
};
```

## Resolvers

```typescript
import { ResolveFn } from '@angular/router';

export const userResolver: ResolveFn<User> = (route) => {
  const userService = inject(UserService);
  const id = route.paramMap.get('id')!;
  return userService.getById(id);
};

// Route config
{
  path: 'users/:id',
  component: UserDetailComponent,
  resolve: { user: userResolver },
}

// Access resolved data via input (with withComponentInputBinding)
@Component({...})
export class UserDetailComponent {
  user = input.required<User>();
}
```

## Nested Routes

```typescript
export const routes: Routes = [
  {
    path: 'products',
    component: ProductsLayoutComponent,
    children: [
      { path: '', component: ProductListComponent },
      { path: ':id', component: ProductDetailComponent },
      { path: ':id/edit', component: ProductEditComponent },
    ],
  },
];

@Component({
  imports: [RouterOutlet],
  template: `
    <h1>Products</h1>
    <router-outlet />
  `,
})
export class ProductsLayoutComponent {}
```

## Programmatic Navigation

```typescript
@Component({...})
export class ProductComponent {
  private router = inject(Router);

  goToProducts() {
    this.router.navigate(['/products']);
  }

  goToProduct(id: string) {
    this.router.navigate(['/products', id]);
  }

  search(query: string) {
    this.router.navigate(['/search'], {
      queryParams: { q: query, page: 1 },
    });
  }
}
```

## Static Route Data

```typescript
{
  path: 'admin',
  component: AdminComponent,
  data: { title: 'Admin Dashboard', roles: ['admin'] },
}

// Access via input (with withComponentInputBinding)
@Component({...})
export class AdminComponent {
  title = input<string>();
  roles = input<string[]>();
}
```

For advanced routing patterns, see [references/routing-patterns.md](references/routing-patterns.md).
