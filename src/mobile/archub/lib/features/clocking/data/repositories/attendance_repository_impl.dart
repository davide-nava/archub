import 'package:archub/core/error/exceptions.dart';
import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/data/datasources/local/sqlite_attendance_local_data_source.dart';
import 'package:archub/features/clocking/data/datasources/remote/attendance_remote_data_source.dart';
import 'package:archub/features/clocking/data/models/attendance_model.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';
import 'package:archub/features/clocking/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;
  final AttendanceRemoteDataSource remoteDataSource;
  final Uuid _uuid;

  AttendanceRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, AttendanceEntity>> recordPunch({
    required AttendanceType type,
    String? userId,
    String? note,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    final now = DateTime.now().toUtc();
    final punchId = _uuid.v4();
    final effectiveUserId = userId ?? 'current_user';

    final initialModel = AttendanceModel(
      id: punchId,
      userId: effectiveUserId,
      type: type,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      syncStatus: SyncStatus.pending,
      note: note,
      createdAt: now,
    );

    // Step 1: Write to local SQLite first (Offline-First guarantee)
    try {
      await localDataSource.insertPunch(initialModel);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to write punch to local storage: $e'));
    }

    // Step 2: Attempt remote synchronization with backend
    try {
      final remoteResult = await remoteDataSource.clockIn(initialModel);
      final syncedModel = initialModel.copyWith(
        syncStatus: SyncStatus.synced,
        syncedAt: remoteResult.syncedAt ?? DateTime.now().toUtc(),
      );

      // Step 3: Update local record to SYNCED
      await localDataSource.markPunchesAsSynced(
        [punchId],
        syncedAt: syncedModel.syncedAt,
      );

      return Right(syncedModel);
    } catch (e) {
      // Offline fallback: Leave as PENDING in SQLite and return cached entity
      return Right(initialModel);
    }
  }

  @override
  Future<Either<Failure, List<AttendanceEntity>>> syncOfflinePunches() async {
    try {
      final pendingPunches = await localDataSource.getPendingPunches();
      if (pendingPunches.isEmpty) {
        return const Right([]);
      }

      final syncedRemoteModels = await remoteDataSource.syncPunches(pendingPunches);
      final syncedIds = pendingPunches.map((p) => p.id).toList();

      final now = DateTime.now().toUtc();
      await localDataSource.markPunchesAsSynced(syncedIds, syncedAt: now);

      final List<AttendanceEntity> result = syncedRemoteModels.isNotEmpty
          ? syncedRemoteModels
          : pendingPunches
              .map((p) => p.copyWith(syncStatus: SyncStatus.synced, syncedAt: now))
              .toList();

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error during sync: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceEntity>>> getPendingPunches() async {
    try {
      final punches = await localDataSource.getPendingPunches();
      return Right(punches);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Error fetching pending punches: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceEntity>>> getAttendanceHistory({
    int limit = 50,
  }) async {
    try {
      final punches = await localDataSource.getAllPunches(limit: limit);
      return Right(punches);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Error fetching history: $e'));
    }
  }

  @override
  Future<Either<Failure, AttendanceEntity?>> getLastPunch() async {
    try {
      final lastPunch = await localDataSource.getLastPunch();
      return Right(lastPunch);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Error fetching last punch: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getPendingCount() async {
    try {
      final count = await localDataSource.getPendingCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'Error fetching pending count: $e'));
    }
  }
}
