# AI Agent Operational Rules & Engineering Guidelines

This document outlines mandatory engineering standards, architectural constraints, conventions, and operational commands for AI agents and developers working on the **ArcHub** frontend codebase.

---

## 1. Project Overview & Tech Stack

- **Framework:** Angular 21 (Standalone Component architecture by default).
- **Language:** TypeScript 5.9+ with strict type checking enabled (`noImplicitAny`, `strictNullChecks`, `noImplicitReturns`, `noImplicitOverride`).
- **State & Reactivity:** Angular Signals (`signal`, `computed`, `input`, `output`, `toSignal`).
- **Routing & Interception:** Functional Router configuration, Lazy Loading, Functional Route Guards (`CanActivateFn`), and Functional HTTP Interceptors (`HttpInterceptorFn`).
- **Styling:** Modular SCSS using enterprise Slate design tokens and WCAG AA accessible contrast ratios.
- **Build & Test Pipeline:**
  - Build: Angular Application Builder (`@angular/build:application`) with esbuild / Vite dev server.
  - Testing: Angular Unit Test Runner (`@angular/build:unit-test`) powered by Vitest and JSDOM.

---

## 2. Essential Commands & Workflows

| Task | Command | Description |
| :--- | :--- | :--- |
| **Development Server** | `npm start` or `ng serve` | Starts dev server on `http://localhost:4200` with hot reloading. |
| **Production Build** | `npm run build` or `ng build` | Compiles production bundle with tree shaking and chunk hashing. |
| **Unit Tests** | `npx ng test --watch=false` | Executes full Vitest unit test suite once. |
| **Test Watcher** | `npm test` or `ng test` | Runs tests in interactive watch mode during development. |
| **Code Formatting** | `npx prettier --write .` | Formats TypeScript, HTML, and SCSS files. |

---

## 3. Mandatory Angular Conventions & Coding Rules

### 3.1 Component Architecture & Decorators

- **DO** create standalone components exclusively.
- **DO NOT** specify `standalone: true` in `@Component` or `@Directive` decorators (it is the default in Angular 20+).
- **DO** declare `changeDetection: ChangeDetectionStrategy.OnPush` on every component.
- **DO NOT** use `@HostBinding()` or `@HostListener()` decorators. Instead, use the `host` configuration object within the `@Component` decorator.
- **DO** use `input()` and `output()` signal functions instead of `@Input()` and `@Output()` property decorators.
- **DO** prefer inline templates and styles for small presentational components and external files (`templateUrl`, `styleUrl`) with relative paths for container pages.

```typescript
// ✅ DO: Modern Standalone Component with Signals & OnPush
import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

@Component({
  selector: 'app-kpi-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="kpi-card" [class.tone-primary]="tone() === 'primary'">
      <span class="kpi-title">{{ title() }}</span>
      <span class="kpi-value">{{ value() }}</span>
    </div>
  `,
  styleUrl: './kpi-card.component.scss'
})
export class KpiCardComponent {
  public readonly title = input.required<string>();
  public readonly value = input.required<string | number>();
  public readonly tone = input<'default' | 'primary' | 'warning'>('default');

  protected readonly ariaLabel = computed(() => `${this.title()}: ${this.value()}`);
}
```

```typescript
// ❌ DO NOT: Legacy NgModule / decorator-based syntax
@Component({
  selector: 'app-kpi-card',
  standalone: true, // ❌ Redundant in Angular 20+
  templateUrl: 'src/app/kpi.html' // ❌ Non-relative path
})
export class LegacyKpiCardComponent {
  @Input() title!: string; // ❌ Use input() function
  @HostListener('click') onClick() {} // ❌ Use host property
}
```

---

### 3.2 State Management & Angular Signals

- **DO** use `signal()` for writable local component state.
- **DO** use `computed()` for derived state and memoized calculations.
- **DO** use `.set()` or `.update()` to change signal values.
- **DO NOT** use `.mutate()` (deprecated/removed in modern Angular).
- **DO** keep state transformations pure and side-effect free.

```typescript
// ✅ DO: Signal-driven state & computed derivations
export class MonthlyReportComponent {
  protected readonly activeFilter = signal<AttendanceFilter>({ year: 2026, month: 8, onlyAnomalies: false });
  protected readonly reportData = signal<MonthlyAttendanceReport | null>(null);

  // Derived computed state
  public readonly summary = computed(() => this.reportData()?.summary ?? null);
  public readonly displayedDays = computed(() => {
    const days = this.reportData()?.days ?? [];
    return this.activeFilter().onlyAnomalies ? days.filter(d => d.hasAnomalies) : days;
  });

  public updateYear(year: number): void {
    this.activeFilter.update(current => ({ ...current, year }));
  }
}
```

---

### 3.3 Dependency Injection

- **DO** use the `inject()` function for dependency injection.
- **DO NOT** use constructor parameter injection for services, tokens, or routers.
- **DO** provide singleton services with `providedIn: 'root'`.

```typescript
// ✅ DO: Functional injection with inject()
@Injectable({
  providedIn: 'root'
})
export class AttendanceService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/attendance`;
}
```

```typescript
// ❌ DO NOT: Constructor parameter injection
@Injectable({ providedIn: 'root' })
export class LegacyService {
  constructor(private http: HttpClient) {} // ❌ Avoid constructor injection
}
```

---

### 3.4 Templates & Control Flow

- **DO** use Angular native control flow (`@if`, `@for`, `@switch`, `@empty`).
- **DO NOT** import `CommonModule` for `*ngIf`, `*ngFor`, or `*ngSwitch`.
- **DO** provide a unique `track` expression for every `@for` loop (e.g. `@for (item of items(); track item.id)`).
- **DO NOT** use `ngClass` or `ngStyle`. Use native class/style bindings instead.
- **DO NOT** execute heavy business logic or instantiate globals (e.g. `new Date()`) directly within template interpolations.

```html
<!-- ✅ DO: Native Control Flow & Class Bindings -->
@if (summary(); as s) {
  <div class="kpi-grid">
    <app-kpi-card title="Worked Hours" [value]="s.totalWorkedHours + 'h'" />
  </div>
}

<table class="attendance-table">
  <tbody>
    @for (day of displayedDays(); track day.date) {
      <tr class="table-row" [class.row-anomaly]="day.hasAnomalies" [class.row-weekend]="day.isWeekend">
        <td>{{ day.date }}</td>
        <td>
          @switch (day.status) {
            @case ('present') { <span class="badge badge-success">Present</span> }
            @case ('absent') { <span class="badge badge-danger">Absent</span> }
            @default { <span>{{ day.status }}</span> }
          }
        </td>
      </tr>
    } @empty {
      <tr>
        <td colspan="4" class="empty-state">No attendance records found.</td>
      </tr>
    }
  </tbody>
</table>
```

```html
<!-- ❌ DO NOT: Legacy Structural Directives and ngClass -->
<div *ngIf="summary" [ngClass]="{'active': isActive}"> <!-- ❌ -->
  <div *ngFor="let day of days"></div> <!-- ❌ -->
</div>
```

---

### 3.5 TypeScript & Strict Type Safety

- **DO** enable strict null checks and provide explicit type annotations for models and API responses.
- **DO NOT** use `any`. If a type is uncertain or polymorphic, use `unknown` with type narrowing.
- **DO** define models as immutable data structures using `readonly` properties.
- **DO** use Typed Reactive Forms (`FormGroup`, `FormControl`).

```typescript
// ✅ DO: Immutable contracts & Typed Reactive Forms
export interface AttendancePunch {
  readonly id: string | number;
  readonly time: string;
  readonly type: 'in' | 'out' | 'break_start' | 'break_end';
  readonly isManual?: boolean;
}

protected readonly filterForm = new FormGroup({
  year: new FormControl<number>(2026, { nonNullable: true }),
  month: new FormControl<number>(8, { nonNullable: true }),
  onlyAnomalies: new FormControl<boolean>(false, { nonNullable: true })
});
```

---

## 4. Architectural Constraints & Guardrails

1. **Path Aliases:** Always use configured TypeScript path aliases rather than long relative paths:
   - `@core/*` &rarr; `src/app/core/*`
   - `@features/*` &rarr; `src/app/features/*`
   - `@env/*` &rarr; `src/environments/*`
2. **HTTP & Authentication:** All HTTP calls to the backend must pass through the functional `authInterceptor` to attach the Laravel Sanctum Bearer token and intercept `401 Unauthorized` / `403 Forbidden` responses.
3. **DOM Manipulation:** Never interact with `document` or `window` directly without verifying platform environment (`isPlatformBrowser`) or using `Renderer2`.
4. **Protected Artifacts:** Do not manually modify build artifacts (`dist/`, `.angular/`, `node_modules/`, `package-lock.json`).
5. **Accessibility (WCAG AA & AXE):** Ensure all interactive elements include accessible names (`aria-label`, `<label for="...">`), keyboard navigation (`:focus-visible`), and semantic table structures (`<caption>`, `<th scope="col">`).
