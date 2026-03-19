# Advanced Form Patterns — Angular v18

## Reusable Form Component with ControlValueAccessor

```typescript
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

@Component({
  selector: 'app-star-rating',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: StarRatingComponent,
      multi: true,
    },
  ],
  host: {
    'role': 'slider',
    '[attr.aria-valuenow]': 'value()',
    '[attr.aria-valuemin]': '1',
    '[attr.aria-valuemax]': 'max()',
  },
  template: `
    @for (star of stars(); track $index) {
      <button
        type="button"
        [class.filled]="$index < value()"
        [disabled]="disabled()"
        (click)="selectStar($index + 1)"
      >
        ★
      </button>
    }
  `,
})
export class StarRatingComponent implements ControlValueAccessor {
  max = input(5);
  value = signal(0);
  disabled = signal(false);

  stars = computed(() => Array.from({ length: this.max() }));

  private onChange: (value: number) => void = () => {};
  private onTouched: () => void = () => {};

  writeValue(value: number): void {
    this.value.set(value || 0);
  }

  registerOnChange(fn: (value: number) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled.set(isDisabled);
  }

  selectStar(rating: number): void {
    this.value.set(rating);
    this.onChange(rating);
    this.onTouched();
  }
}

// Usage with Reactive Forms:
// <app-star-rating formControlName="rating" />
```

## Multi-Step Form (Wizard)

```typescript
@Component({
  selector: 'app-registration-wizard',
  imports: [ReactiveFormsModule],
  template: `
    <div class="steps">
      @for (step of steps; track $index; let i = $index) {
        <span [class.active]="currentStep() === i" [class.completed]="i < currentStep()">
          {{ step }}
        </span>
      }
    </div>

    <form [formGroup]="form" (ngSubmit)="submit()">
      @switch (currentStep()) {
        @case (0) {
          <div formGroupName="personal">
            <input formControlName="firstName" placeholder="First Name" />
            <input formControlName="lastName" placeholder="Last Name" />
            <input formControlName="email" type="email" placeholder="Email" />
          </div>
        }
        @case (1) {
          <div formGroupName="address">
            <input formControlName="street" placeholder="Street" />
            <input formControlName="city" placeholder="City" />
            <input formControlName="zip" placeholder="ZIP Code" />
          </div>
        }
        @case (2) {
          <div formGroupName="account">
            <input formControlName="username" placeholder="Username" />
            <input formControlName="password" type="password" placeholder="Password" />
          </div>
        }
      }

      <div class="actions">
        @if (currentStep() > 0) {
          <button type="button" (click)="prev()">Back</button>
        }
        @if (currentStep() < steps.length - 1) {
          <button type="button" (click)="next()" [disabled]="!isCurrentStepValid()">
            Next
          </button>
        } @else {
          <button type="submit" [disabled]="form.invalid">Submit</button>
        }
      </div>
    </form>
  `,
})
export class RegistrationWizardComponent {
  private fb = inject(FormBuilder);

  steps = ['Personal Info', 'Address', 'Account'];
  currentStep = signal(0);

  form = this.fb.nonNullable.group({
    personal: this.fb.nonNullable.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
    }),
    address: this.fb.nonNullable.group({
      street: ['', Validators.required],
      city: ['', Validators.required],
      zip: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]],
    }),
    account: this.fb.nonNullable.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      password: ['', [Validators.required, Validators.minLength(8)]],
    }),
  });

  private stepGroups = ['personal', 'address', 'account'] as const;

  isCurrentStepValid(): boolean {
    const groupName = this.stepGroups[this.currentStep()];
    return this.form.get(groupName)!.valid;
  }

  next() {
    if (this.isCurrentStepValid()) {
      this.currentStep.update(s => s + 1);
    }
  }

  prev() {
    this.currentStep.update(s => s - 1);
  }

  submit() {
    if (this.form.valid) {
      console.log(this.form.getRawValue());
    }
  }
}
```

## Error Message Component

```typescript
@Component({
  selector: 'app-field-error',
  template: `
    @if (control() && control()!.invalid && control()!.touched) {
      <div class="error" role="alert">
        @if (control()!.hasError('required')) {
          <span>{{ label() }} is required</span>
        } @else if (control()!.hasError('email')) {
          <span>Invalid email address</span>
        } @else if (control()!.hasError('minlength')) {
          <span>Minimum {{ control()!.getError('minlength').requiredLength }} characters</span>
        } @else if (control()!.hasError('maxlength')) {
          <span>Maximum {{ control()!.getError('maxlength').requiredLength }} characters</span>
        } @else if (control()!.hasError('pattern')) {
          <span>Invalid format</span>
        }
      </div>
    }
  `,
})
export class FieldErrorComponent {
  control = input.required<AbstractControl | null>();
  label = input('Field');
}

// Usage:
// <input formControlName="email" />
// <app-field-error [control]="form.controls.email" label="Email" />
```

## Form with Dependent Fields

```typescript
@Component({...})
export class ShippingFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    country: ['', Validators.required],
    state: [''],
    postalCode: ['', Validators.required],
  });

  constructor() {
    // When country changes, update state/zip validators
    this.form.controls.country.valueChanges.subscribe(country => {
      const stateCtrl = this.form.controls.state;
      const zipCtrl = this.form.controls.postalCode;

      if (country === 'US') {
        stateCtrl.setValidators(Validators.required);
        zipCtrl.setValidators([Validators.required, Validators.pattern(/^\d{5}$/)]);
      } else {
        stateCtrl.clearValidators();
        zipCtrl.setValidators(Validators.required);
      }

      stateCtrl.updateValueAndValidity();
      zipCtrl.updateValueAndValidity();
    });
  }
}
```

## Form Auto-Save with Debounce

```typescript
@Component({...})
export class AutoSaveFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private saveService = inject(SaveService);
  private destroyRef = inject(DestroyRef);

  form = this.fb.group({
    title: [''],
    content: [''],
  });

  saving = signal(false);
  lastSaved = signal<Date | null>(null);

  ngOnInit() {
    this.form.valueChanges.pipe(
      debounceTime(1000),
      filter(() => this.form.dirty),
      switchMap(value => {
        this.saving.set(true);
        return this.saveService.save(value);
      }),
      takeUntilDestroyed(this.destroyRef),
    ).subscribe({
      next: () => {
        this.saving.set(false);
        this.lastSaved.set(new Date());
        this.form.markAsPristine();
      },
      error: () => this.saving.set(false),
    });
  }
}
```
