#!/bin/bash
cat > user-profile.component.ts << 'COMPONENT'
import { Component, ChangeDetectionStrategy, computed, input, output, booleanAttribute } from '@angular/core';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '(click)': 'onProfileClick()',
  },
  template: `
    <h2>{{ displayName() }}</h2>
    @if (email()) {
      <p>{{ email() }}</p>
    }
  `,
})
export class UserProfileComponent {
  name = input.required<string>();
  email = input('');
  isAdmin = input(false, { transform: booleanAttribute });

  displayName = computed(() => this.name().toUpperCase());

  profileClicked = output<string>();

  onProfileClick() {
    this.profileClicked.emit(this.name());
  }
}
COMPONENT
