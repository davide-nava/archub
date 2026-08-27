# AGENTS.md — AI Agent Guidelines & Engineering Standards

> **Workspace:** `archub` (Flutter Mobile & Multiplatform Application)  
> **Architecture Pattern:** Feature-First Clean Architecture + Offline-First Strategy  
> **Primary State Management:** BLoC / Cubit (`flutter_bloc`)  
> **Service Locator:** GetIt (`get_it`)

---

## 1. Project Overview & Tech Stack

### SDK & Runtime Constraints
- **Flutter SDK:** `^3.47.0` (Dart SDK: `^3.13.1`)
- **Null-Safety:** Strict Sound Null-Safety enabled across the entire codebase.
- **Target Platforms:** Android, iOS, macOS, Windows, Linux, Web.

### Key Dependencies & Libraries
| Purpose | Package | Role in Architecture |
|---|---|---|
| **State Management** | `flutter_bloc: ^9.1.1` | Predictable event-driven presentation state management. |
| **Functional Error Handling**| `dartz: ^0.10.1` | `Either<Failure, T>` return types for Repositories and UseCases. |
| **Value Equality** | `equatable: ^2.1.0` | Value-based equality for Entities, Models, States, and Events. |
| **HTTP Client** | `dio: ^5.11.0` | Configured in `ApiClient` with timeouts and error interceptors. |
| **Local Database** | `sqflite: ^2.4.1` / `path` | Local SQLite database for offline-first data caching (`offline_punches`). |
| **Hardware & Location** | `geolocator: ^13.0.2` | GPS geolocation capture and accuracy evaluation. |
| **Dependency Injection** | `get_it: ^9.2.1` | Service locator registry (`lib/core/di/injection.dart`). |
| **Identification & Dates** | `uuid: ^4.5.1`, `intl: ^0.20.2` | UUID generation for offline entities, date/time formatting. |
| **Testing Suite** | `mocktail`, `bloc_test`, `sqflite_common_ffi` | Unit, BLoC, and in-memory SQLite integration testing. |

---

## 2. Dart & Flutter Coding Conventions

### 2.1 Typing & Null Safety
- **Always declare explicit return types** for functions, methods, and getters (e.g., `Future<Either<Failure, AttendanceEntity>> recordPunch(...)`).
- **Never use `dynamic`** unless strictly required for third-party raw JSON deserialization (always validate and parse into strongly-typed models immediately).
- **Avoid bang operator (`!`) force-unwraps**; prefer pattern matching, `if-let` null checks, null-coalescing (`??`), or default fallbacks.

### 2.2 Functional Error Handling with `Either`
All Use Cases and Repositories MUST return `Future<Either<Failure, T>>`:
```dart
// DO: Use Either<Failure, T>
Future<Either<Failure, AttendanceEntity>> recordPunch({
  required AttendanceType type,
  String? userId,
  double? latitude,
  double? longitude,
});

// DO: Consume using fold() or getOrElse()
final result = await clockInUseCase(params);
result.fold(
  (failure) => emit(state.copyWith(status: ClockingStatus.error, errorMessage: failure.message)),
  (entity) => emit(state.copyWith(status: ClockingStatus.synced, lastPunch: entity)),
);
```

### 2.3 Widget Tree Best Practices
- **Extract sub-widgets into dedicated files** (e.g., `ActionPunchButton`, `GpsBadge`, `LiveShiftTimer`).
- **Prioritize `const` constructors** wherever possible to optimize Flutter's widget rebuild pipeline.
- **Never put business logic or database queries inside `Widget.build()`**. Dispatch events to BLoC.
- **Avoid asynchronous gaps with `BuildContext`**: Always verify `if (!context.mounted) return;` after `await` before using `context` or `ScaffoldMessenger.of(context)`.

```dart
// DO: Check mounted before using context
final note = await showDialog<String>(context: context, builder: ...);
if (!context.mounted) return;
if (note != null) {
  context.read<ClockingBloc>().add(ClockingPunchSubmitted(type: type, note: note));
}
```

### 2.4 File & Symbol Naming Conventions
- **Files & Folders:** lowercase `snake_case` (e.g., `attendance_repository_impl.dart`, `action_punch_button.dart`).
- **Classes & Enums:** `PascalCase` (e.g., `AttendanceEntity`, `AttendanceType`, `SqliteAttendanceLocalDataSource`).
- **Variables & Methods:** `camelCase` (e.g., `syncOfflinePunches()`, `lastPunchTimestamp`).
- **Constants:** `lowerCamelCase` or `SCREAMING_SNAKE_CASE` for API/DB column constants (e.g., `ApiConstants.clockInEndpoint`, `AppDatabase.tableOfflinePunches`).

### Standard Suffix Rules:
- `*_entity.dart` -> Domain entities (e.g., `attendance_entity.dart`)
- `*_model.dart` -> Data transfer models extending entities (e.g., `attendance_model.dart`)
- `*_data_source.dart` -> Local or remote data source classes
- `*_repository.dart` -> Domain repository interfaces
- `*_repository_impl.dart` -> Concrete data layer implementations
- `*_usecase.dart` -> Single-responsibility domain use cases
- `*_bloc.dart`, `*_event.dart`, `*_state.dart` -> BLoC state management files
- `*_screen.dart` / `*_page.dart` -> Top-level screen widgets
- `*_test.dart` -> Test files mirroring `lib/` structure

---

## 3. Essential Commands & Workflows

### Dependency Management
```bash
# Fetch dependencies
flutter pub get

# Check for outdated packages
flutter pub outdated
```

### Code Generation (when using build_runner / Freezed / JsonSerializable)
```bash
# Run one-off build
dart run build_runner build --delete-conflicting-outputs

# Run active watcher
dart run build_runner watch --delete-conflicting-outputs
```

### Static Analysis & Formatting
```bash
# Run static analyzer
flutter analyze

# Format entire codebase
dart format .
```

### Testing
```bash
# Run all unit and widget tests
flutter test

# Run a specific test file
flutter test test/features/clocking/data/repositories/attendance_repository_impl_test.dart
```

### Building & Running
```bash
# Run in debug mode
flutter run

# Build release artifacts
flutter build apk --release
flutter build appbundle --release
flutter build ipa --release
flutter build web --release
flutter build windows --release
```

---

## 4. Constraints & Guardrails for AI Agents

### DO NOT:
- ❌ **DO NOT** edit generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) manually.
- ❌ **DO NOT** introduce global state or singletons without registering them in `lib/core/di/injection.dart`.
- ❌ **DO NOT** bypass the SQLite local database for mutations when implementing offline-first features.
- ❌ **DO NOT** use raw `print()` statements in production code. Use a proper logging utility or debugger.
- ❌ **DO NOT** hardcode API URLs or database names directly in UI or data sources. Use `ApiConstants` or `AppDatabase`.
- ❌ **DO NOT** throw unhandled exceptions across architectural boundaries; map them to `Failure` types in repository implementations.

### DO:
- ✅ **DO** follow the Feature-First directory structure (`lib/features/<feature>/domain`, `data`, `presentation`).
- ✅ **DO** ensure all new classes and methods have corresponding unit tests in `test/`.
- ✅ **DO** use in-memory SQLite FFI (`sqflite_common_ffi`) when testing SQLite data sources.
- ✅ **DO** use `mocktail` for mocking abstractions and contracts.
- ✅ **DO** maintain zero analyzer warnings (`flutter analyze` must exit with 0).
