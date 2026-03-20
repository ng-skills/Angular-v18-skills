# Angular v18 Forms

Signal Forms are NOT available in v18. Always use Reactive Forms — do NOT use template-driven forms (`FormsModule`, `ngModel`).

## Reactive Forms

```typescript
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';

@Component({
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <input formControlName="email" type="email" />
      @if (form.controls.email.hasError('required') && form.controls.email.touched) {
        <span class="error">Email is required</span>
      }
      <button type="submit" [disabled]="form.invalid">Login</button>
    </form>
  `,
})
export class LoginComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  onSubmit() {
    if (this.form.valid) {
      const { email, password } = this.form.getRawValue();
    }
  }
}
```

## Typed Forms

```typescript
// Non-nullable form builder
const form = this.fb.nonNullable.group({
  name: [''],        // FormControl<string>
  age: [0],          // FormControl<number>
  active: [false],   // FormControl<boolean>
});
```

## Custom Validators

```typescript
export function passwordStrengthValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value = control.value;
    if (!value) return null;
    const valid = /[A-Z]/.test(value) && /[a-z]/.test(value) && /[0-9]/.test(value);
    return valid ? null : { passwordStrength: true };
  };
}
```

## Form Events (New in v18)

```typescript
this.form.events.subscribe(event => {
  if (event instanceof ValueChangeEvent) { /* ... */ }
  if (event instanceof StatusChangeEvent) { /* ... */ }
});
```

---

## Form Patterns

### ControlValueAccessor

```typescript
@Component({
  selector: 'app-star-rating',
  providers: [{ provide: NG_VALUE_ACCESSOR, useExisting: StarRatingComponent, multi: true }],
  template: `
    @for (star of stars(); track $index) {
      <button type="button" [class.filled]="$index < value()" (click)="selectStar($index + 1)">★</button>
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

  writeValue(value: number) { this.value.set(value || 0); }
  registerOnChange(fn: (value: number) => void) { this.onChange = fn; }
  registerOnTouched(fn: () => void) { this.onTouched = fn; }
  setDisabledState(d: boolean) { this.disabled.set(d); }
  selectStar(rating: number) { this.value.set(rating); this.onChange(rating); this.onTouched(); }
}
```

### Multi-Step Form (Wizard)

```typescript
@Component({
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      @switch (currentStep()) {
        @case (0) { <div formGroupName="personal">...</div> }
        @case (1) { <div formGroupName="address">...</div> }
        @case (2) { <div formGroupName="account">...</div> }
      }
      @if (currentStep() > 0) { <button type="button" (click)="prev()">Back</button> }
      @if (currentStep() < 2) {
        <button type="button" (click)="next()" [disabled]="!isCurrentStepValid()">Next</button>
      } @else {
        <button type="submit" [disabled]="form.invalid">Submit</button>
      }
    </form>
  `,
})
export class RegistrationWizardComponent {
  private fb = inject(FormBuilder);
  currentStep = signal(0);
  form = this.fb.nonNullable.group({
    personal: this.fb.nonNullable.group({ firstName: ['', Validators.required], lastName: ['', Validators.required], email: ['', [Validators.required, Validators.email]] }),
    address: this.fb.nonNullable.group({ street: ['', Validators.required], city: ['', Validators.required], zip: ['', Validators.required] }),
    account: this.fb.nonNullable.group({ username: ['', Validators.required], password: ['', [Validators.required, Validators.minLength(8)]] }),
  });
  private stepGroups = ['personal', 'address', 'account'] as const;
  isCurrentStepValid() { return this.form.get(this.stepGroups[this.currentStep()])!.valid; }
  next() { if (this.isCurrentStepValid()) this.currentStep.update(s => s + 1); }
  prev() { this.currentStep.update(s => s - 1); }
  submit() { if (this.form.valid) console.log(this.form.getRawValue()); }
}
```

### Form Auto-Save

```typescript
ngOnInit() {
  this.form.valueChanges.pipe(
    debounceTime(1000),
    filter(() => this.form.dirty),
    switchMap(value => this.saveService.save(value)),
    takeUntilDestroyed(this.destroyRef),
  ).subscribe(() => { this.form.markAsPristine(); });
}
```
