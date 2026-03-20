#!/bin/bash
cat > product-list.component.ts << 'COMPONENT'
import { Component, inject, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { toSignal, toObservable } from '@angular/core/rxjs-interop';
import { debounceTime, switchMap, map } from 'rxjs';

interface Product {
  id: string;
  name: string;
  price: number;
}

@Component({
  selector: 'app-product-list',
  standalone: true,
  template: `
    <input type="text" placeholder="Search..." (input)="onSearch($event)" />

    @if (loading()) {
      <p>Loading products...</p>
    } @else {
      @for (product of filteredProducts(); track product.id) {
        <div class="product-item">
          <span>{{ product.name }}</span>
          <span>{{ product.price }}</span>
        </div>
      } @empty {
        <p>No products found</p>
      }
    }
  `,
})
export class ProductListComponent {
  private http = inject(HttpClient);

  searchQuery = signal('');
  loading = signal(true);

  private products = toSignal(
    this.http.get<Product[]>('/api/products'),
    { initialValue: [] }
  );

  private debouncedQuery = toSignal(
    toObservable(this.searchQuery).pipe(debounceTime(300)),
    { initialValue: '' }
  );

  filteredProducts = computed(() => {
    this.loading.set(false);
    const query = this.debouncedQuery().toLowerCase();
    if (!query) return this.products();
    return this.products().filter(p => p.name.toLowerCase().includes(query));
  });

  onSearch(event: Event) {
    this.searchQuery.set((event.target as HTMLInputElement).value);
  }
}
COMPONENT
