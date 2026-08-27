import 'package:archub/core/services/location_service.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:equatable/equatable.dart';

enum ClockingStatus {
  idle,
  punching,
  offlineCached,
  synced,
  syncing,
  error,
}

class ClockingState extends Equatable {
  final ClockingStatus status;
  final AttendanceEntity? lastPunch;
  final List<AttendanceEntity> recentPunches;
  final int pendingCount;
  final LocationData? currentLocation;
  final bool isLocationLoading;
  final String? locationError;
  final String? errorMessage;
  final Duration activeDuration;

  const ClockingState({
    this.status = ClockingStatus.idle,
    this.lastPunch,
    this.recentPunches = const [],
    this.pendingCount = 0,
    this.currentLocation,
    this.isLocationLoading = false,
    this.locationError,
    this.errorMessage,
    this.activeDuration = Duration.zero,
  });

  /// Factory for initial state
  factory ClockingState.initial() {
    return const ClockingState(
      status: ClockingStatus.idle,
      pendingCount: 0,
      recentPunches: [],
    );
  }

  bool get isIdle => status == ClockingStatus.idle;
  bool get isPunching => status == ClockingStatus.punching;
  bool get isOfflineCached => status == ClockingStatus.offlineCached;
  bool get isSynced => status == ClockingStatus.synced;
  bool get isSyncing => status == ClockingStatus.syncing;
  bool get isError => status == ClockingStatus.error;

  /// Check if user is currently clocked in (working)
  bool get isWorking {
    if (lastPunch == null) return false;
    return lastPunch!.type == AttendanceType.clockIn ||
        lastPunch!.type == AttendanceType.breakEnd;
  }

  /// Check if user is currently on break
  bool get isOnBreak {
    if (lastPunch == null) return false;
    return lastPunch!.type == AttendanceType.breakStart;
  }

  /// Check if user is clocked out
  bool get isClockedOut {
    if (lastPunch == null) return true;
    return lastPunch!.type == AttendanceType.clockOut;
  }

  ClockingState copyWith({
    ClockingStatus? status,
    AttendanceEntity? lastPunch,
    bool clearLastPunch = false,
    List<AttendanceEntity>? recentPunches,
    int? pendingCount,
    LocationData? currentLocation,
    bool? isLocationLoading,
    String? locationError,
    bool clearLocationError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    Duration? activeDuration,
  }) {
    return ClockingState(
      status: status ?? this.status,
      lastPunch: clearLastPunch ? null : (lastPunch ?? this.lastPunch),
      recentPunches: recentPunches ?? this.recentPunches,
      pendingCount: pendingCount ?? this.pendingCount,
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      activeDuration: activeDuration ?? this.activeDuration,
    );
  }

  @override
  List<Object?> get props => [
        status,
        lastPunch,
        recentPunches,
        pendingCount,
        currentLocation,
        isLocationLoading,
        locationError,
        errorMessage,
        activeDuration,
      ];
}
