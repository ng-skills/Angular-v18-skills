# Advanced Testing Patterns — Angular v18

## Component Harness Pattern

```typescript
import { ComponentHarness, HarnessPredicate } from '@angular/cdk/testing';

export class ButtonHarness extends ComponentHarness {
  static hostSelector = 'app-button';

  private button = this.locatorFor('button');

  static with(options: { text?: string } = {}): HarnessPredicate<ButtonHarness> {
    return new HarnessPredicate(ButtonHarness, options)
      .addOption('text', options.text, async (harness, text) => {
        const buttonText = await harness.getText();
        return buttonText === text;
      });
  }

  async getText(): Promise<string> {
    return (await this.button()).text();
  }

  async click(): Promise<void> {
    return (await this.button()).click();
  }

  async isDisabled(): Promise<boolean> {
    const disabled = await (await this.button()).getAttribute('disabled');
    return disabled !== null;
  }
}

// Usage in tests
it('should click the submit button', async () => {
  const loader = TestbedHarnessEnvironment.loader(fixture);
  const button = await loader.getHarness(ButtonHarness.with({ text: 'Submit' }));

  expect(await button.isDisabled()).toBeFalse();
  await button.click();
  expect(component.submitted()).toBeTrue();
});
```

## Testing Router Navigation

```typescript
import { RouterTestingModule } from '@angular/router/testing';
import { Router } from '@angular/router';

describe('Navigation', () => {
  let router: Router;
  let location: Location;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        RouterTestingModule.withRoutes([
          { path: '', component: HomeComponent },
          { path: 'about', component: AboutComponent },
          { path: 'users/:id', component: UserDetailComponent },
        ]),
      ],
    }).compileComponents();

    router = TestBed.inject(Router);
    location = TestBed.inject(Location);
  });

  it('should navigate to about page', fakeAsync(() => {
    router.navigate(['/about']);
    tick();
    expect(location.path()).toBe('/about');
  }));
});
```

## Testing Effects

```typescript
describe('Component with effects', () => {
  it('should update document title via effect', fakeAsync(() => {
    const fixture = TestBed.createComponent(PageComponent);
    fixture.componentRef.setInput('title', 'Test Page');
    fixture.detectChanges();
    tick();

    expect(document.title).toContain('Test Page');
  }));
});
```

## Testing Observables with Marble Testing

```typescript
import { TestScheduler } from 'rxjs/testing';

describe('SearchService', () => {
  let scheduler: TestScheduler;

  beforeEach(() => {
    scheduler = new TestScheduler((actual, expected) => {
      expect(actual).toEqual(expected);
    });
  });

  it('should debounce search requests', () => {
    scheduler.run(({ cold, expectObservable }) => {
      const input    = cold('--a--b----c---|');
      const expected =      '-----b----c---|';

      const result = input.pipe(debounceTime(2, scheduler));
      expectObservable(result).toBe(expected);
    });
  });
});
```

## Snapshot Testing for Templates

```typescript
describe('CardComponent', () => {
  it('should render correctly', () => {
    const fixture = TestBed.createComponent(CardComponent);
    fixture.componentRef.setInput('title', 'Test Card');
    fixture.componentRef.setInput('description', 'A test description');
    fixture.detectChanges();

    expect(fixture.nativeElement.innerHTML).toMatchSnapshot();
  });
});
```

## Testing Reactive Forms

```typescript
describe('LoginComponent', () => {
  it('should validate form fields', () => {
    const fixture = TestBed.createComponent(LoginComponent);
    const component = fixture.componentInstance;
    fixture.detectChanges();

    // Initially invalid
    expect(component.form.valid).toBeFalse();

    // Set valid values
    component.form.controls.email.setValue('test@example.com');
    component.form.controls.password.setValue('password123');

    expect(component.form.valid).toBeTrue();
  });

  it('should show error messages', () => {
    const fixture = TestBed.createComponent(LoginComponent);
    fixture.detectChanges();

    // Touch the email field to trigger validation messages
    const emailControl = fixture.componentInstance.form.controls.email;
    emailControl.markAsTouched();
    fixture.detectChanges();

    const errorEl = fixture.nativeElement.querySelector('.error');
    expect(errorEl.textContent).toContain('required');
  });

  it('should submit valid form', () => {
    const fixture = TestBed.createComponent(LoginComponent);
    const component = fixture.componentInstance;
    fixture.detectChanges();

    spyOn(component, 'onSubmit');

    component.form.controls.email.setValue('test@example.com');
    component.form.controls.password.setValue('password123');
    fixture.detectChanges();

    const form = fixture.nativeElement.querySelector('form');
    form.dispatchEvent(new Event('submit'));

    expect(component.onSubmit).toHaveBeenCalled();
  });
});
```

## Testing with DestroyRef and Cleanup

```typescript
describe('PollingComponent', () => {
  it('should stop polling on destroy', fakeAsync(() => {
    const fixture = TestBed.createComponent(PollingComponent);
    fixture.detectChanges();

    // Advance time to trigger polling
    tick(30_000);
    fixture.detectChanges();

    // Verify polling happened
    const httpMock = TestBed.inject(HttpTestingController);
    httpMock.expectOne('/api/data').flush({ data: 'test' });

    // Destroy component
    fixture.destroy();

    // Advance time — should not make more requests
    tick(30_000);
    httpMock.verify(); // No outstanding requests
  }));
});
```

## Provider Override Patterns

```typescript
// Override environment token
TestBed.configureTestingModule({
  providers: [
    { provide: API_BASE_URL, useValue: 'http://test-api.com' },
  ],
});

// Override with spy
const spy = jasmine.createSpyObj('UserService', ['getAll', 'getById']);
spy.getAll.and.returnValue(of(mockUsers));
TestBed.configureTestingModule({
  providers: [
    { provide: UserService, useValue: spy },
  ],
});

// Override with fake implementation
TestBed.configureTestingModule({
  providers: [
    {
      provide: AuthService,
      useValue: {
        isAuthenticated: () => true,
        user: signal({ id: '1', name: 'Test User' }),
      },
    },
  ],
});
```
