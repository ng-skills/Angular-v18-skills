# Angular v18 Routing

## Basic Setup

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: '**', component: NotFoundComponent },
];

// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [provideRouter(routes)],
};

// app.component.ts
@Component({
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <nav>
      <a routerLink="/home" routerLinkActive="active">Home</a>
    </nav>
    <router-outlet />
  `,
})
export class AppComponent {}
```

## Lazy Loading

```typescript
export const routes: Routes = [
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.adminRoutes),
  },
  {
    path: 'settings',
    loadComponent: () => import('./settings/settings.component').then(m => m.SettingsComponent),
  },
];
```

## Route Parameters with Signal Inputs

```typescript
// app.config.ts
provideRouter(routes, withComponentInputBinding())

// Route: { path: 'users/:id', component: UserDetailComponent }
@Component({...})
export class UserDetailComponent {
  id = input.required<string>();
  userId = computed(() => parseInt(this.id(), 10));
}
```

## Route Redirects as Functions (New in v18)

```typescript
{
  path: 'legacy-path',
  redirectTo: ({ queryParams }) => {
    const id = queryParams['id'];
    return id ? `/new-path/${id}` : '/new-path';
  },
}
```

## Functional Guards

```typescript
export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) return true;
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url },
  });
};

// Factory pattern
export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return () => {
    const auth = inject(AuthService);
    return allowedRoles.includes(auth.currentUser()?.role ?? '');
  };
};
```

## Resolvers

```typescript
export const userResolver: ResolveFn<User> = (route) => {
  return inject(UserService).getById(route.paramMap.get('id')!);
};

{ path: 'users/:id', component: UserDetailComponent, resolve: { user: userResolver } }
```

---

## Routing Patterns

### Feature Route Organization

```typescript
export const adminRoutes: Routes = [
  {
    path: '',
    component: AdminLayoutComponent,
    canActivate: [authGuard, roleGuard(['admin'])],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: AdminDashboardComponent },
      { path: 'users/:id', component: UserDetailComponent, resolve: { user: userResolver } },
    ],
  },
];
```

### View Transitions (New in v18)

```typescript
provideRouter(routes, withViewTransitions(), withComponentInputBinding())
```

### Title Strategy

```typescript
@Injectable()
export class AppTitleStrategy extends TitleStrategy {
  override updateTitle(routerState: RouterStateSnapshot): void {
    const title = this.buildTitle(routerState);
    document.title = title ? `${title} | My App` : 'My App';
  }
}

providers: [{ provide: TitleStrategy, useClass: AppTitleStrategy }]
```

### Preloading Strategies

```typescript
provideRouter(routes, withPreloading(PreloadAllModules))
```

### Error Handling with Router

```typescript
provideRouter(
  routes,
  withNavigationErrorHandler((error) => {
    inject(Router).navigate(['/error'], { queryParams: { message: error.message } });
  })
)
```
