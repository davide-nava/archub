import 'package:archub/core/database/app_database.dart';
import 'package:archub/features/clocking/data/datasources/local/sqlite_attendance_local_data_source.dart';
import 'package:archub/features/clocking/data/models/attendance_model.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late SqliteAttendanceLocalDataSource dataSource;

  setUpAll(() {
    // Initialize FFI for running SQLite in desktop/unit tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create an in-memory database for isolated, fast unit testing
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

  tearDown(() async {
    await db.close();
  });

  final testDate1 = DateTime.utc(2026, 8, 27, 8, 30, 0);
  final testDate2 = DateTime.utc(2026, 8, 27, 12, 30, 0);

  final testPunch1 = AttendanceModel(
    id: 'punch-uuid-1',
    userId: 'user-101',
    type: AttendanceType.clockIn,
    timestamp: testDate1,
    latitude: 45.4642,
    longitude: 9.1900,
    accuracy: 5.0,
    syncStatus: SyncStatus.pending,
    note: 'Inizio turno mattutino',
    createdAt: testDate1,
  );

  final testPunch2 = AttendanceModel(
    id: 'punch-uuid-2',
    userId: 'user-101',
    type: AttendanceType.breakStart,
    timestamp: testDate2,
    latitude: 45.4645,
    longitude: 9.1905,
    accuracy: 4.5,
    syncStatus: SyncStatus.pending,
    note: 'Pausa pranzo',
    createdAt: testDate2,
  );

  group('SqliteAttendanceLocalDataSource', () {
    test('insertPunch inserts model correctly into SQLite and can be retrieved', () async {
      // Act
      await dataSource.insertPunch(testPunch1);

      // Assert
      final pendingList = await dataSource.getPendingPunches();
      expect(pendingList.length, 1);
      expect(pendingList.first.id, testPunch1.id);
      expect(pendingList.first.userId, testPunch1.userId);
      expect(pendingList.first.type, AttendanceType.clockIn);
      expect(pendingList.first.syncStatus, SyncStatus.pending);
      expect(pendingList.first.latitude, 45.4642);
      expect(pendingList.first.longitude, 9.1900);
      expect(pendingList.first.accuracy, 5.0);
      expect(pendingList.first.note, 'Inizio turno mattutino');
    });

    test('getPendingPunches only returns records with sync_status = PENDING in chronological order', () async {
      // Arrange
      await dataSource.insertPunch(testPunch2); // 12:30
      await dataSource.insertPunch(testPunch1); // 08:30

      // Act
      final pending = await dataSource.getPendingPunches();

      // Assert
      expect(pending.length, 2);
      expect(pending[0].id, 'punch-uuid-1'); // Earlier timestamp first
      expect(pending[1].id, 'punch-uuid-2');
    });

    test('markPunchesAsSynced updates status to SYNCED and sets syncedAt', () async {
      // Arrange
      await dataSource.insertPunch(testPunch1);
      await dataSource.insertPunch(testPunch2);

      final syncTimestamp = DateTime.utc(2026, 8, 27, 13, 0, 0);

      // Act
      await dataSource.markPunchesAsSynced(['punch-uuid-1'], syncedAt: syncTimestamp);

      // Assert
      final pending = await dataSource.getPendingPunches();
      expect(pending.length, 1);
      expect(pending.first.id, 'punch-uuid-2');

      final all = await dataSource.getAllPunches();
      final syncedPunch = all.firstWhere((p) => p.id == 'punch-uuid-1');
      expect(syncedPunch.syncStatus, SyncStatus.synced);
      expect(syncedPunch.syncedAt, syncTimestamp);
    });

    test('getLastPunch returns the latest punch based on timestamp', () async {
      // Arrange
      await dataSource.insertPunch(testPunch1);
      await dataSource.insertPunch(testPunch2);

      // Act
      final lastPunch = await dataSource.getLastPunch();

      // Assert
      expect(lastPunch, isNotNull);
      expect(lastPunch!.id, 'punch-uuid-2');
      expect(lastPunch.type, AttendanceType.breakStart);
    });

    test('getLastPunch returns null when database is empty', () async {
      // Act
      final lastPunch = await dataSource.getLastPunch();

      // Assert
      expect(lastPunch, isNull);
    });

    test('getPendingCount returns correct count of unsynced records', () async {
      // Arrange
      expect(await dataSource.getPendingCount(), 0);

      await dataSource.insertPunch(testPunch1);
      await dataSource.insertPunch(testPunch2);
      expect(await dataSource.getPendingCount(), 2);

      await dataSource.markPunchesAsSynced(['punch-uuid-1']);
      expect(await dataSource.getPendingCount(), 1);
    });

    test('deletePunch removes the record matching id', () async {
      // Arrange
      await dataSource.insertPunch(testPunch1);
      expect(await dataSource.getPendingCount(), 1);

      // Act
      await dataSource.deletePunch(testPunch1.id);

      // Assert
      expect(await dataSource.getPendingCount(), 0);
    });
  });
}
