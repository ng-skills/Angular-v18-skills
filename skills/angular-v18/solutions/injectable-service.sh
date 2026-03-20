#!/bin/bash
cat > todo.service.ts << 'SERVICE'
import { Injectable, inject, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { toSignal } from '@angular/core/rxjs-interop';

interface Todo {
  id: string;
  title: string;
  completed: boolean;
}

@Injectable({ providedIn: 'root' })
export class TodoService {
  private http = inject(HttpClient);

  private _todos = signal<Todo[]>([]);
  readonly todos = this._todos.asReadonly();

  readonly incompleteCount = computed(() =>
    this._todos().filter(t => !t.completed).length
  );

  loadTodos() {
    this.http.get<Todo[]>('/api/todos').subscribe(todos => {
      this._todos.set(todos);
    });
  }

  addTodo(title: string) {
    const newTodo: Todo = { id: crypto.randomUUID(), title, completed: false };
    this._todos.update(todos => [...todos, newTodo]);
  }

  toggleTodo(id: string) {
    this._todos.update(todos =>
      todos.map(t => t.id === id ? { ...t, completed: !t.completed } : t)
    );
  }

  removeTodo(id: string) {
    this._todos.update(todos => todos.filter(t => t.id !== id));
  }
}
SERVICE
