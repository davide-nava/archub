import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class GetAttendanceHistoryUseCase {
  final AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Future<Either<Failure, List<AttendanceEntity>>> call({int limit = 50}) async {
    return await repository.getAttendanceHistory(limit: limit);
  }
}
