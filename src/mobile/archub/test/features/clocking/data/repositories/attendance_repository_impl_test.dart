import 'package:archub/core/error/exceptions.dart';
import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/data/datasources/local/sqlite_attendance_local_data_source.dart';
import 'package:archub/features/clocking/data/datasources/remote/attendance_remote_data_source.dart';
import 'package:archub/features/clocking/data/models/attendance_model.dart';
import 'package:archub/features/clocking/data/repositories/attendance_repository_impl.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockLocalDataSource extends Mock implements AttendanceLocalDataSource {}

class MockRemoteDataSource extends Mock implements AttendanceRemoteDataSource {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late AttendanceRepositoryImpl repository;
  late MockLocalDataSource mockLocalDataSource;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(
      AttendanceModel(
        id: 'fallback-id',
        userId: 'fallback-user',
        type: AttendanceType.clockIn,
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockRemoteDataSource = MockRemoteDataSource();
    mockUuid = MockUuid();

    when(() => mockUuid.v4()).thenReturn('generated-uuid-123');

    repository = AttendanceRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      uuid: mockUuid,
    );
  });

  final tDate = DateTime.utc(2026, 8, 27, 8, 30, 0);
  final tModel = AttendanceModel(
    id: 'generated-uuid-123',
    userId: 'user-01',
    type: AttendanceType.clockIn,
    timestamp: tDate,
    latitude: 45.4642,
    longitude: 9.1900,
    accuracy: 5.0,
    syncStatus: SyncStatus.pending,
    createdAt: tDate,
  );

  group('recordPunch (Offline-First strategy)', () {
    test('writes to SQLite first, synchronizes remotely, and marks local as SYNCED', () async {
      // Arrange
      when(() => mockLocalDataSource.insertPunch(any())).thenAnswer((_) async {});
      when(() => mockRemoteDataSource.clockIn(any())).thenAnswer(
        (_) async => tModel.copyWith(syncStatus: SyncStatus.synced, syncedAt: tDate),
      );
      when(() => mockLocalDataSource.markPunchesAsSynced(any(), syncedAt: any(named: 'syncedAt')))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.recordPunch(
        type: AttendanceType.clockIn,
        userId: 'user-01',
        latitude: 45.4642,
        longitude: 9.1900,
        accuracy: 5.0,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should succeed'),
        (entity) {
          expect(entity.id, 'generated-uuid-123');
          expect(entity.syncStatus, SyncStatus.synced);
        },
      );

      // Verify sequence: Local insert first, then Remote sync, then Local mark as synced
      verify(() => mockLocalDataSource.insertPunch(any())).called(1);
      verify(() => mockRemoteDataSource.clockIn(any())).called(1);
      verify(() => mockLocalDataSource.markPunchesAsSynced(['generated-uuid-123'], syncedAt: any(named: 'syncedAt'))).called(1);
    });

    test('writes to SQLite and gracefully stays as PENDING when network fails (Offline mode)', () async {
      // Arrange
      when(() => mockLocalDataSource.insertPunch(any())).thenAnswer((_) async {});
      when(() => mockRemoteDataSource.clockIn(any())).thenThrow(
        const NetworkException(message: 'No internet connection'),
      );

      // Act
      final result = await repository.recordPunch(
        type: AttendanceType.clockIn,
        userId: 'user-01',
        latitude: 45.4642,
        longitude: 9.1900,
        accuracy: 5.0,
      );

      // Assert: The punch must still SUCCEED for user with PENDING sync status!
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Offline punch should not fail for user'),
        (entity) {
          expect(entity.id, 'generated-uuid-123');
          expect(entity.syncStatus, SyncStatus.pending);
        },
      );

      verify(() => mockLocalDataSource.insertPunch(any())).called(1);
      verify(() => mockRemoteDataSource.clockIn(any())).called(1);
      verifyNever(() => mockLocalDataSource.markPunchesAsSynced(any(), syncedAt: any(named: 'syncedAt')));
    });

    test('returns CacheFailure when local database insert fails', () async {
      // Arrange
      when(() => mockLocalDataSource.insertPunch(any())).thenThrow(
        const CacheException(message: 'Disk write error'),
      );

      // Act
      final result = await repository.recordPunch(
        type: AttendanceType.clockIn,
        userId: 'user-01',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should fail on local cache error'),
      );

      verifyNever(() => mockRemoteDataSource.clockIn(any()));
    });
  });

  group('syncOfflinePunches', () {
    test('fetches pending punches from SQLite, sends batch to remote /sync, and marks synced', () async {
      // Arrange
      final pendingPunches = [
        tModel,
        tModel.copyWith(id: 'generated-uuid-456', type: AttendanceType.clockOut),
      ];

      when(() => mockLocalDataSource.getPendingPunches()).thenAnswer((_) async => pendingPunches);
      when(() => mockRemoteDataSource.syncPunches(any())).thenAnswer(
        (_) async => pendingPunches
            .map((p) => p.copyWith(syncStatus: SyncStatus.synced, syncedAt: tDate))
            .toList(),
      );
      when(() => mockLocalDataSource.markPunchesAsSynced(any(), syncedAt: any(named: 'syncedAt')))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.syncOfflinePunches();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should succeed'),
        (syncedList) {
          expect(syncedList.length, 2);
          expect(syncedList.every((p) => p.syncStatus == SyncStatus.synced), true);
        },
      );

      verify(() => mockLocalDataSource.getPendingPunches()).called(1);
      verify(() => mockRemoteDataSource.syncPunches(pendingPunches)).called(1);
      verify(() => mockLocalDataSource.markPunchesAsSynced(['generated-uuid-123', 'generated-uuid-456'], syncedAt: any(named: 'syncedAt'))).called(1);
    });

    test('returns empty list without calling remote if no punches are pending', () async {
      // Arrange
      when(() => mockLocalDataSource.getPendingPunches()).thenAnswer((_) async => []);

      // Act
      final result = await repository.syncOfflinePunches();

      // Assert
      expect(result, const Right<Failure, List<AttendanceEntity>>([]));
      verifyNever(() => mockRemoteDataSource.syncPunches(any()));
    });

    test('returns ServerFailure when remote sync fails with ServerException', () async {
      // Arrange
      when(() => mockLocalDataSource.getPendingPunches()).thenAnswer((_) async => [tModel]);
      when(() => mockRemoteDataSource.syncPunches(any())).thenThrow(
        const ServerException(message: 'Internal server error', statusCode: 500),
      );

      // Act
      final result = await repository.syncOfflinePunches();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Internal server error');
        },
        (_) => fail('Should fail with ServerFailure'),
      );
    });
  });

  group('Local queries: getLastPunch, getPendingCount, getAttendanceHistory', () {
    test('getLastPunch delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getLastPunch()).thenAnswer((_) async => tModel);

      final result = await repository.getLastPunch();

      expect(result, Right(tModel));
      verify(() => mockLocalDataSource.getLastPunch()).called(1);
    });

    test('getPendingCount delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getPendingCount()).thenAnswer((_) async => 3);

      final result = await repository.getPendingCount();

      expect(result, const Right(3));
      verify(() => mockLocalDataSource.getPendingCount()).called(1);
    });
  });
}
