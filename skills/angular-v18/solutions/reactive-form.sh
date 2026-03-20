#!/bin/bash
cat > registration-form.component.ts << 'COMPONENT'
import { Component, inject } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators, AbstractControl, ValidationErrors } from '@angular/forms';

function passwordMatchValidator(control: AbstractControl): ValidationErrors | null {
  const password = control.get('password');
  const confirm = control.get('confirmPassword');
  if (password && confirm && password.value !== confirm.value) {
    return { passwordMismatch: true };
  }
  return null;
}

@Component({
  selector: 'app-registration-form',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <input formControlName="firstName" placeholder="First Name" />
      @if (form.controls.firstName.hasError('required') && form.controls.firstName.touched) {
        <span class="error">First name is required</span>
      }

      <input formControlName="lastName" placeholder="Last Name" />
      @if (form.controls.lastName.hasError('required') && form.controls.lastName.touched) {
        <span class="error">Last name is required</span>
      }

      <input formControlName="email" type="email" placeholder="Email" />
      @if (form.controls.email.hasError('required') && form.controls.email.touched) {
        <span class="error">Email is required</span>
      }
      @if (form.controls.email.hasError('email') && form.controls.email.touched) {
        <span class="error">Invalid email</span>
      }

      <input formControlName="password" type="password" placeholder="Password" />
      @if (form.controls.password.hasError('minlength') && form.controls.password.touched) {
        <span class="error">Password must be at least 8 characters</span>
      }

      <input formControlName="confirmPassword" type="password" placeholder="Confirm Password" />
      @if (form.hasError('passwordMismatch')) {
        <span class="error">Passwords do not match</span>
      }

      <button type="submit" [disabled]="form.invalid">Register</button>
    </form>
  `,
})
export class RegistrationFormComponent {
  private fb = inject(FormBuilder);

  form = this.fb.nonNullable.group({
    firstName: ['', Validators.required],
    lastName: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
    confirmPassword: ['', Validators.required],
  }, { validators: passwordMatchValidator });

  onSubmit() {
    if (this.form.valid) {
      console.log(this.form.getRawValue());
    }
  }
}
COMPONENT
