import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';

class GetPendingPunchesCountUseCase {
  final AttendanceRepository repository;

  GetPendingPunchesCountUseCase(this.repository);

  Future<Either<Failure, int>> call() async {
    return await repository.getPendingCount();
  }
}
