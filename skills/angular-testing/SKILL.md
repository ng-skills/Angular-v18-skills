---
name: angular-testing
description: Write unit and integration tests for Angular v18 applications using TestBed, ComponentFixture, and HttpClientTestingModule. Covers component testing, service testing, signal testing, pipe testing, and HTTP mocking. Use when writing tests for components, services, guards, or interceptors. Do not use for E2E testing or Vitest setup which is not available in v18.
---

# Angular v18 Testing

Angular v18 uses Jasmine + Karma by default. All test patterns use standalone components.

## Component Testing

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';

describe('UserCardComponent', () => {
  let component: UserCardComponent;
  let fixture: ComponentFixture<UserCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserCardComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should display user name', () => {
    // Set signal input
    fixture.componentRef.setInput('name', 'Alice');
    fixture.detectChanges();

    const nameEl = fixture.nativeElement.querySelector('h2');
    expect(nameEl.textContent).toContain('Alice');
  });

  it('should emit selected event on click', () => {
    fixture.componentRef.setInput('name', 'Bob');
    fixture.detectChanges();

    let emittedValue: string | undefined;
    component.selected.subscribe(value => emittedValue = value);

    fixture.nativeElement.click();
    expect(emittedValue).toBe('Bob');
  });
});
```

## Testing Signal Inputs

```typescript
describe('CounterComponent', () => {
  it('should set input via fixture.componentRef.setInput', () => {
    const fixture = TestBed.createComponent(CounterComponent);

    // Use setInput for signal inputs
    fixture.componentRef.setInput('count', 5);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('5');
  });

  it('should update computed values when inputs change', () => {
    const fixture = TestBed.createComponent(CounterComponent);

    fixture.componentRef.setInput('count', 10);
    fixture.detectChanges();

    // computed signals update automatically
    expect(fixture.componentInstance.doubled()).toBe(20);
  });
});
```

## Testing Signals in Services

```typescript
describe('CartService', () => {
  let service: CartService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(CartService);
  });

  it('should start with empty cart', () => {
    expect(service.items()).toEqual([]);
    expect(service.itemCount()).toBe(0);
    expect(service.total()).toBe(0);
  });

  it('should add item to cart', () => {
    service.addItem({ id: '1', price: 10 } as Product);

    expect(service.items().length).toBe(1);
    expect(service.itemCount()).toBe(1);
    expect(service.total()).toBe(10);
  });

  it('should increment quantity for duplicate items', () => {
    const product = { id: '1', price: 10 } as Product;
    service.addItem(product);
    service.addItem(product);

    expect(service.items().length).toBe(1);
    expect(service.items()[0].quantity).toBe(2);
    expect(service.total()).toBe(20);
  });
});
```

## Service Testing with HTTP Mocking

```typescript
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify(); // Ensure no outstanding requests
  });

  it('should fetch users', () => {
    const mockUsers: User[] = [
      { id: '1', name: 'Alice' },
      { id: '2', name: 'Bob' },
    ];

    service.getAll().subscribe(users => {
      expect(users.length).toBe(2);
      expect(users[0].name).toBe('Alice');
    });

    const req = httpMock.expectOne('/api/users?page=1&limit=10');
    expect(req.request.method).toBe('GET');
    req.flush({ data: mockUsers, total: 2 });
  });

  it('should handle 404 error', () => {
    service.getById('999').subscribe({
      error: (err) => {
        expect(err.message).toBe('User not found');
      },
    });

    const req = httpMock.expectOne('/api/users/999');
    req.flush('Not found', { status: 404, statusText: 'Not Found' });
  });
});
```

## Testing with Dependencies

```typescript
describe('DashboardComponent', () => {
  let authServiceSpy: jasmine.SpyObj<AuthService>;

  beforeEach(async () => {
    authServiceSpy = jasmine.createSpyObj('AuthService', ['isAuthenticated'], {
      user: signal({ id: '1', name: 'Test User' }),
    });

    await TestBed.configureTestingModule({
      imports: [DashboardComponent],
      providers: [
        { provide: AuthService, useValue: authServiceSpy },
      ],
    }).compileComponents();
  });

  it('should show welcome message for authenticated user', () => {
    authServiceSpy.isAuthenticated.and.returnValue(true);

    const fixture = TestBed.createComponent(DashboardComponent);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Welcome, Test User');
  });
});
```

## Testing Pipes

```typescript
describe('TruncatePipe', () => {
  let pipe: TruncatePipe;

  beforeEach(() => {
    pipe = new TruncatePipe();
  });

  it('should return empty string for falsy values', () => {
    expect(pipe.transform('')).toBe('');
  });

  it('should not truncate short strings', () => {
    expect(pipe.transform('Hello', 50)).toBe('Hello');
  });

  it('should truncate long strings with trail', () => {
    const long = 'A'.repeat(100);
    const result = pipe.transform(long, 50);
    expect(result.length).toBe(53); // 50 + '...'
    expect(result.endsWith('...')).toBeTrue();
  });

  it('should use custom trail', () => {
    const result = pipe.transform('A'.repeat(100), 50, '…');
    expect(result.endsWith('…')).toBeTrue();
  });
});
```

## Testing Guards

```typescript
import { CanActivateFn } from '@angular/router';
import { TestBed } from '@angular/core/testing';

describe('authGuard', () => {
  let authService: jasmine.SpyObj<AuthService>;
  let router: jasmine.SpyObj<Router>;

  beforeEach(() => {
    authService = jasmine.createSpyObj('AuthService', ['isAuthenticated']);
    router = jasmine.createSpyObj('Router', ['createUrlTree']);

    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: Router, useValue: router },
      ],
    });
  });

  it('should allow access for authenticated users', () => {
    authService.isAuthenticated.and.returnValue(true);

    const result = TestBed.runInInjectionContext(() =>
      authGuard({} as any, { url: '/dashboard' } as any)
    );

    expect(result).toBeTrue();
  });

  it('should redirect to login for unauthenticated users', () => {
    authService.isAuthenticated.and.returnValue(false);
    router.createUrlTree.and.returnValue({} as any);

    TestBed.runInInjectionContext(() =>
      authGuard({} as any, { url: '/dashboard' } as any)
    );

    expect(router.createUrlTree).toHaveBeenCalledWith(
      ['/login'],
      jasmine.objectContaining({ queryParams: { returnUrl: '/dashboard' } })
    );
  });
});
```

## Testing Interceptors

```typescript
describe('authInterceptor', () => {
  let httpMock: HttpTestingController;
  let httpClient: HttpClient;
  let authService: jasmine.SpyObj<AuthService>;

  beforeEach(() => {
    authService = jasmine.createSpyObj('AuthService', ['getToken']);

    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        { provide: AuthService, useValue: authService },
      ],
    });

    httpClient = TestBed.inject(HttpClient);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('should add auth header when token exists', () => {
    authService.getToken.and.returnValue('test-token');

    httpClient.get('/api/data').subscribe();

    const req = httpMock.expectOne('/api/data');
    expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');
  });

  it('should not add auth header when no token', () => {
    authService.getToken.and.returnValue(null);

    httpClient.get('/api/data').subscribe();

    const req = httpMock.expectOne('/api/data');
    expect(req.request.headers.has('Authorization')).toBeFalse();
  });
});
```

## Async Testing

```typescript
import { fakeAsync, tick, flush } from '@angular/core/testing';

it('should debounce search input', fakeAsync(() => {
  const fixture = TestBed.createComponent(SearchComponent);
  fixture.detectChanges();

  fixture.componentInstance.query.set('ang');
  tick(100); // Not enough time
  fixture.detectChanges();
  expect(fixture.nativeElement.querySelector('.results')).toBeNull();

  tick(200); // Total 300ms — debounce complete
  fixture.detectChanges();
  expect(fixture.nativeElement.querySelector('.results')).toBeTruthy();
}));

it('should load data on init', async () => {
  const fixture = TestBed.createComponent(DataComponent);
  fixture.detectChanges();
  await fixture.whenStable();

  expect(fixture.nativeElement.textContent).toContain('Loaded');
});
```

For advanced testing patterns, see [references/testing-patterns.md](references/testing-patterns.md).
