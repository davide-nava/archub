import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:dartz/dartz.dart';

abstract class AttendanceRepository {
  /// Records a punch (Entrata, Uscita, Pausa) offline first, then attempts remote sync.
  Future<Either<Failure, AttendanceEntity>> recordPunch({
    required AttendanceType type,
    String? userId,
    String? note,
    double? latitude,
    double? longitude,
    double? accuracy,
  });

  /// Synchronizes all offline pending punches with Laravel backend.
  Future<Either<Failure, List<AttendanceEntity>>> syncOfflinePunches();

  /// Retrieves list of pending unsynced punches.
  Future<Either<Failure, List<AttendanceEntity>>> getPendingPunches();

  /// Retrieves attendance history from local storage.
  Future<Either<Failure, List<AttendanceEntity>>> getAttendanceHistory({int limit = 50});

  /// Retrieves the most recent punch.
  Future<Either<Failure, AttendanceEntity?>> getLastPunch();

  /// Returns the count of offline punches waiting to be synced.
  Future<Either<Failure, int>> getPendingCount();
}
