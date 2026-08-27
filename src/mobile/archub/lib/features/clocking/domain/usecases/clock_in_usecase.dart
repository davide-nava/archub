import 'package:archub/core/error/failures.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/repositories/attendance_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class ClockInParams extends Equatable {
  final AttendanceType type;
  final String? userId;
  final String? note;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  const ClockInParams({
    required this.type,
    this.userId,
    this.note,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  @override
  List<Object?> get props => [type, userId, note, latitude, longitude, accuracy];
}

class ClockInUseCase {
  final AttendanceRepository repository;

  ClockInUseCase(this.repository);

  Future<Either<Failure, AttendanceEntity>> call(ClockInParams params) async {
    return await repository.recordPunch(
      type: params.type,
      userId: params.userId,
      note: params.note,
      latitude: params.latitude,
      longitude: params.longitude,
      accuracy: params.accuracy,
    );
  }
}
