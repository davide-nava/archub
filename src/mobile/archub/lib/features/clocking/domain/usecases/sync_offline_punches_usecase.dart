import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class SyncOfflinePunchesUseCase {
  final AttendanceRepository repository;

  SyncOfflinePunchesUseCase(this.repository);

  Future<Either<Failure, List<AttendanceEntity>>> call() async {
    return await repository.syncOfflinePunches();
  }
}
