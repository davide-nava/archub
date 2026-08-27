import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:equatable/equatable.dart';

abstract class ClockingEvent extends Equatable {
  const ClockingEvent();

  @override
  List<Object?> get props => [];
}

class ClockingStarted extends ClockingEvent {
  const ClockingStarted();
}

class ClockingPunchSubmitted extends ClockingEvent {
  final AttendanceType type;
  final String? note;

  const ClockingPunchSubmitted({
    required this.type,
    this.note,
  });

  @override
  List<Object?> get props => [type, note];
}

class ClockingSyncRequested extends ClockingEvent {
  const ClockingSyncRequested();
}

class ClockingLocationRefreshRequested extends ClockingEvent {
  const ClockingLocationRefreshRequested();
}

class ClockingTimerTicked extends ClockingEvent {
  final DateTime currentTime;

  const ClockingTimerTicked(this.currentTime);

  @override
  List<Object?> get props => [currentTime];
}

class ClockingHistoryRefreshRequested extends ClockingEvent {
  const ClockingHistoryRefreshRequested();
}
