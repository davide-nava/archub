# TESTING.md — Testing Standards & Quality Assurance Guide

> **Testing Frameworks:** `flutter_test`, `mocktail`, `bloc_test`, `sqflite_common_ffi`  
> **Test Coverage Areas:** Unit Tests (DataSources, Repositories, UseCases), BLoC Tests, Widget Tests  
> **Testing Pattern:** Arrange-Act-Assert (AAA)

---

## 1. Test Architecture & Directory Layout

All tests are located in `test/` and strictly mirror the folder structure of `lib/`:

```text
test/
├── features/
│   └── clocking/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── sqlite_attendance_local_data_source_test.dart
│       │   └── repositories/
│       │       └── attendance_repository_impl_test.dart
│       └── presentation/
│           └── clocking_bloc_test.dart
│
└── widget_test.dart                    # Widget testing for PunchScreen & subwidgets
```

---

## 2. Core Testing Libraries & Tools

| Library | Version | Usage |
|---|---|---|
| `flutter_test` | SDK | Base Flutter testing framework for unit and widget tests. |
| `mocktail` | `^1.0.4` | Type-safe, null-safe mocking without code generation. |
| `bloc_test` | `^10.0.0` | Declarative testing for BLoC event dispatching and state sequences. |
| `sqflite_common_ffi` | `^2.3.4+4` | In-memory SQLite C-engine execution in local VM / CI runner tests. |

---

## 3. Unit Testing Patterns & Concrete Code Examples

### 3.1 Local SQLite Data Source Testing (In-Memory FFI)
Always initialize `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi` in `setUpAll()`, using an in-memory database to ensure tests run fast and with full database isolation:

```dart
import 'package:archub/core/database/app_database.dart';
import 'package:archub/features/clocking/data/datasources/local/sqlite_attendance_local_data_source.dart';
import 'package:archub/features/clocking/data/models/attendance_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late SqliteAttendanceLocalDataSource dataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.databaseVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${AppDatabase.tableOfflinePunches} (
              ${AppDatabase.columnId} TEXT PRIMARY KEY,
              ${AppDatabase.columnUserId} TEXT NOT NULL,
              ${AppDatabase.columnType} TEXT NOT NULL,
              ${AppDatabase.columnTimestamp} TEXT NOT NULL,
              ${AppDatabase.columnLatitude} REAL,
              ${AppDatabase.columnLongitude} REAL,
              ${AppDatabase.columnAccuracy} REAL,
              ${AppDatabase.columnSyncStatus} TEXT NOT NULL DEFAULT 'PENDING',
              ${AppDatabase.columnNote} TEXT,
              ${AppDatabase.columnCreatedAt} TEXT NOT NULL,
              ${AppDatabase.columnSyncedAt} TEXT
            )
          ''');
        },
      ),
    );
    dataSource = SqliteAttendanceLocalDataSource(database: db);
  });

  tearDown(() async => await db.close());

  test('insertPunch stores model into SQLite and can be queried', () async {
    // Arrange
    final model = AttendanceModel(...);

    // Act
    await dataSource.insertPunch(model);

    // Assert
    final pending = await dataSource.getPendingPunches();
    expect(pending.length, 1);
    expect(pending.first.id, model.id);
  });
}
```

### 3.2 Repository Testing with Mocktail (Offline-First Verification)
Verify that mutations write to SQLite first and that network failures are handled without crashing:

```dart
class MockLocalDataSource extends Mock implements AttendanceLocalDataSource {}
class MockRemoteDataSource extends Mock implements AttendanceRemoteDataSource {}

void main() {
  late AttendanceRepositoryImpl repository;
  late MockLocalDataSource mockLocal;
  late MockRemoteDataSource mockRemote;

  setUp(() {
    mockLocal = MockLocalDataSource();
    mockRemote = MockRemoteDataSource();
    repository = AttendanceRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
    );
  });

  test('recordPunch stays as PENDING when network fails (Offline Guarantee)', () async {
    // Arrange
    when(() => mockLocal.insertPunch(any())).thenAnswer((_) async {});
    when(() => mockRemote.clockIn(any())).thenThrow(
      const NetworkException(message: 'No internet connection'),
    );

    // Act
    final result = await repository.recordPunch(type: AttendanceType.clockIn);

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Offline punch should not fail for the user'),
      (entity) {
        expect(entity.syncStatus, SyncStatus.pending);
      },
    );
    verify(() => mockLocal.insertPunch(any())).called(1);
    verifyNever(() => mockLocal.markPunchesAsSynced(any(), syncedAt: any(named: 'syncedAt')));
  });
}
```

### 3.3 BLoC State Sequence Testing (`bloc_test`)
Use `blocTest` to assert that events emit expected sequence of immutable states:

```dart
blocTest<ClockingBloc, ClockingState>(
  'emits [punching, synced] when punch is successfully recorded and synced online',
  build: () {
    when(() => mockClockInUseCase(any())).thenAnswer((_) async => Right(tPunchSynced));
    when(() => mockGetPendingCountUseCase()).thenAnswer((_) async => const Right(0));
    when(() => mockGetHistoryUseCase(limit: any(named: 'limit')))
        .thenAnswer((_) async => Right([tPunchSynced]));
    return bloc;
  },
  act: (bloc) => bloc.add(const ClockingPunchSubmitted(type: AttendanceType.clockIn)),
  expect: () => [
    isA<ClockingState>().having((s) => s.status, 'status', ClockingStatus.punching),
    isA<ClockingState>()
        .having((s) => s.status, 'status', ClockingStatus.synced)
        .having((s) => s.lastPunch, 'lastPunch', tPunchSynced)
        .having((s) => s.pendingCount, 'pendingCount', 0),
  ],
);
```

---

## 4. Widget Testing Guidelines

When testing Flutter widgets:
1. **Wrap widgets in `MaterialApp` and `BlocProvider.value`** with mocked BLoC instances.
2. **Stub `mockBloc.state` and `mockBloc.stream`**.
3. **Use `tester.pumpWidget()`** or `tester.pumpAndSettle()` for animations.

```dart
testWidgets('PunchScreen renders title, timer, GPS badge, and action buttons', (tester) async {
  when(() => mockClockingBloc.state).thenReturn(
    const ClockingState(
      status: ClockingStatus.idle,
      pendingCount: 2,
      currentLocation: LocationData(latitude: 45.46, longitude: 9.19, accuracy: 4.5),
    ),
  );
  when(() => mockClockingBloc.stream).thenAnswer((_) => const Stream.empty());

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ClockingBloc>.value(
        value: mockClockingBloc,
        child: const PunchScreen(),
      ),
    ),
  );

  expect(find.text('Presenze & Timbrature'), findsOneWidget);
  expect(find.byType(LiveShiftTimer), findsOneWidget);
  expect(find.byType(GpsBadge), findsOneWidget);
  expect(find.text('Entrata'), findsOneWidget);
  expect(find.text('Pausa'), findsOneWidget);
  expect(find.text('Uscita'), findsOneWidget);
  expect(find.text('2 marcature salvate offline'), findsOneWidget);
});
```

---

## 5. Test Execution Commands

```bash
# Run all tests
flutter test

# Run tests with coverage output
flutter test --coverage

# Run tests for a specific layer
flutter test test/features/clocking/data/
flutter test test/features/clocking/presentation/
```
