---
name: angular-forms
description: Build forms in Angular v18 using Reactive Forms with typed FormGroup, FormControl, and FormArray, or Template-driven Forms with ngModel. Covers validation, dynamic forms, custom validators, and form state events. Use when creating forms, adding validation, or handling user input. Do not use for Signal Forms which are not available in v18.
---

# Angular v18 Forms

Angular v18 supports Reactive Forms and Template-driven Forms. Signal Forms are NOT available in v18.

## Reactive Forms Setup

```typescript
import { Component, inject } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <label>
        Email
        <input formControlName="email" type="email" />
        @if (form.controls.email.hasError('required') && form.controls.email.touched) {
          <span class="error">Email is required</span>
        }
        @if (form.controls.email.hasError('email') && form.controls.email.touched) {
          <span class="error">Invalid email format</span>
        }
      </label>

      <label>
        Password
        <input formControlName="password" type="password" />
        @if (form.controls.password.hasError('minlength') && form.controls.password.touched) {
          <span class="error">Password must be at least 8 characters</span>
        }
      </label>

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
      // email and password are typed as string
    }
  }
}
```

## Typed Forms (Default in v18)

```typescript
// FormBuilder produces fully typed forms
const form = this.fb.group({
  name: [''],                    // FormControl<string | null>
  age: [0],                      // FormControl<number | null>
  active: [false as boolean],    // FormControl<boolean | null>
});

// Non-nullable form builder
const form = this.fb.nonNullable.group({
  name: [''],                    // FormControl<string>
  age: [0],                      // FormControl<number>
  active: [false],               // FormControl<boolean>
});

// Access typed values
const name: string = form.controls.name.value; // Non-nullable
form.getRawValue(); // { name: string; age: number; active: boolean }
```

## FormArray

```typescript
@Component({
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form">
      <div formArrayName="items">
        @for (item of itemControls.controls; track $index) {
          <div [formGroupName]="$index">
            <input formControlName="name" placeholder="Item name" />
            <input formControlName="quantity" type="number" />
            <button type="button" (click)="removeItem($index)">Remove</button>
          </div>
        }
      </div>
      <button type="button" (click)="addItem()">Add Item</button>
    </form>
  `,
})
export class OrderFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    items: this.fb.array([this.createItem()]),
  });

  get itemControls() {
    return this.form.controls.items;
  }

  createItem() {
    return this.fb.group({
      name: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
    });
  }

  addItem() {
    this.itemControls.push(this.createItem());
  }

  removeItem(index: number) {
    this.itemControls.removeAt(index);
  }
}
```

## Custom Validators

```typescript
import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

// Synchronous validator
export function passwordStrengthValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value = control.value;
    if (!value) return null;

    const hasUpperCase = /[A-Z]/.test(value);
    const hasLowerCase = /[a-z]/.test(value);
    const hasNumeric = /[0-9]/.test(value);

    const valid = hasUpperCase && hasLowerCase && hasNumeric;
    return valid ? null : { passwordStrength: true };
  };
}

// Cross-field validator
export function passwordMatchValidator(): ValidatorFn {
  return (group: AbstractControl): ValidationErrors | null => {
    const password = group.get('password')?.value;
    const confirm = group.get('confirmPassword')?.value;
    return password === confirm ? null : { passwordMismatch: true };
  };
}

// Async validator
export function uniqueEmailValidator(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    return userService.checkEmail(control.value).pipe(
      map(exists => exists ? { emailTaken: true } : null),
      catchError(() => of(null))
    );
  };
}

// Usage
form = this.fb.group({
  password: ['', [Validators.required, passwordStrengthValidator()]],
  confirmPassword: ['', Validators.required],
}, { validators: passwordMatchValidator() });

email = new FormControl('', {
  validators: [Validators.required, Validators.email],
  asyncValidators: [uniqueEmailValidator(inject(UserService))],
});
```

## Form Events (New in v18)

FormControl, FormGroup, and FormArray expose a unified `events` observable.

```typescript
@Component({...})
export class ProfileFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.group({
    name: [''],
    email: [''],
  });

  constructor() {
    // Listen to all form events (value, status, pristine, touched)
    this.form.events.subscribe(event => {
      if (event instanceof ValueChangeEvent) {
        console.log('Value changed:', event.value);
      }
      if (event instanceof StatusChangeEvent) {
        console.log('Status changed:', event.status);
      }
      if (event instanceof PristineChangeEvent) {
        console.log('Pristine changed:', event.pristine);
      }
      if (event instanceof TouchedChangeEvent) {
        console.log('Touched changed:', event.touched);
      }
    });
  }
}
```

## Template-Driven Forms

```typescript
import { FormsModule } from '@angular/forms';

@Component({
  imports: [FormsModule],
  template: `
    <form #userForm="ngForm" (ngSubmit)="onSubmit(userForm)">
      <label>
        Name
        <input name="name" [(ngModel)]="user.name" required minlength="2" #nameCtrl="ngModel" />
        @if (nameCtrl.invalid && nameCtrl.touched) {
          <span class="error">Name is required (min 2 chars)</span>
        }
      </label>

      <label>
        Email
        <input name="email" [(ngModel)]="user.email" required email />
      </label>

      <button type="submit" [disabled]="userForm.invalid">Save</button>
    </form>
  `,
})
export class UserFormComponent {
  user = { name: '', email: '' };

  onSubmit(form: NgForm) {
    if (form.valid) {
      console.log('Submitted:', this.user);
    }
  }
}
```

## Dynamic Form Fields

```typescript
@Component({
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      @for (field of fields; track field.key) {
        <label>
          {{ field.label }}
          @switch (field.type) {
            @case ('text') {
              <input [formControlName]="field.key" type="text" />
            }
            @case ('number') {
              <input [formControlName]="field.key" type="number" />
            }
            @case ('select') {
              <select [formControlName]="field.key">
                @for (option of field.options; track option.value) {
                  <option [value]="option.value">{{ option.label }}</option>
                }
              </select>
            }
          }
        </label>
      }
      <button type="submit">Submit</button>
    </form>
  `,
})
export class DynamicFormComponent {
  private fb = inject(FormBuilder);

  fields: FormFieldConfig[] = [
    { key: 'name', label: 'Name', type: 'text' },
    { key: 'age', label: 'Age', type: 'number' },
    { key: 'role', label: 'Role', type: 'select', options: [
      { value: 'admin', label: 'Admin' },
      { value: 'user', label: 'User' },
    ]},
  ];

  form = this.fb.group(
    Object.fromEntries(this.fields.map(f => [f.key, ['']]))
  );

  onSubmit() {
    console.log(this.form.getRawValue());
  }
}
```

For advanced form patterns, see [references/form-patterns.md](references/form-patterns.md).
