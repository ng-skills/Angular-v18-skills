# Angular v18 Testing

Jasmine + Karma by default. All test patterns use standalone components.

## Component Testing

```typescript
describe('UserCardComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
    }).compileComponents();
  });

  it('should display user name', () => {
    const fixture = TestBed.createComponent(UserCardComponent);
    fixture.componentRef.setInput('name', 'Alice');
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('h2').textContent).toContain('Alice');
  });
});
```

## Service Testing with HTTP Mocking

```typescript
describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('should fetch users', () => {
    service.getAll().subscribe(users => expect(users.length).toBe(2));
    httpMock.expectOne('/api/users?page=1&limit=10').flush({ data: [{}, {}], total: 2 });
  });
});
```

## Testing Guards

```typescript
it('should allow authenticated users', () => {
  authService.isAuthenticated.and.returnValue(true);
  const result = TestBed.runInInjectionContext(() =>
    authGuard({} as any, { url: '/dashboard' } as any)
  );
  expect(result).toBeTrue();
});
```

---

## Testing Patterns

### Component Harness

```typescript
export class ButtonHarness extends ComponentHarness {
  static hostSelector = 'app-button';
  private button = this.locatorFor('button');

  async getText() { return (await this.button()).text(); }
  async click() { return (await this.button()).click(); }
  async isDisabled() { return (await (await this.button()).getAttribute('disabled')) !== null; }
}
```

### Testing Reactive Forms

```typescript
it('should validate form fields', () => {
  const fixture = TestBed.createComponent(LoginComponent);
  fixture.detectChanges();
  expect(fixture.componentInstance.form.valid).toBeFalse();

  fixture.componentInstance.form.controls.email.setValue('test@example.com');
  fixture.componentInstance.form.controls.password.setValue('password123');
  expect(fixture.componentInstance.form.valid).toBeTrue();
});
```

### Provider Override Patterns

```typescript
TestBed.configureTestingModule({
  providers: [
    { provide: API_BASE_URL, useValue: 'http://test-api.com' },
    { provide: AuthService, useValue: { isAuthenticated: () => true, user: signal({ id: '1', name: 'Test' }) } },
  ],
});
```
