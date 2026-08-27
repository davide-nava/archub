import 'dart:async';
import 'package:archub/core/services/location_service.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/usecases/clock_in_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/get_attendance_history_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/get_last_punch_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/get_pending_punches_count_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/sync_offline_punches_usecase.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_event.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClockingBloc extends Bloc<ClockingEvent, ClockingState> {
  final ClockInUseCase clockInUseCase;
  final SyncOfflinePunchesUseCase syncOfflinePunchesUseCase;
  final GetLastPunchUseCase getLastPunchUseCase;
  final GetPendingPunchesCountUseCase getPendingPunchesCountUseCase;
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;
  final LocationService locationService;

  Timer? _shiftTicker;

  ClockingBloc({
    required this.clockInUseCase,
    required this.syncOfflinePunchesUseCase,
    required this.getLastPunchUseCase,
    required this.getPendingPunchesCountUseCase,
    required this.getAttendanceHistoryUseCase,
    required this.locationService,
  }) : super(ClockingState.initial()) {
    on<ClockingStarted>(_onStarted);
    on<ClockingPunchSubmitted>(_onPunchSubmitted);
    on<ClockingSyncRequested>(_onSyncRequested);
    on<ClockingLocationRefreshRequested>(_onLocationRefreshRequested);
    on<ClockingTimerTicked>(_onTimerTicked);
    on<ClockingHistoryRefreshRequested>(_onHistoryRefreshRequested);
  }

  Future<void> _onStarted(
    ClockingStarted event,
    Emitter<ClockingState> emit,
  ) async {
    // 1. Fetch last punch
    final lastPunchResult = await getLastPunchUseCase();
    AttendanceEntity? lastPunch;
    lastPunchResult.fold((_) {}, (punch) => lastPunch = punch);

    // 2. Fetch pending count
    final pendingCountResult = await getPendingPunchesCountUseCase();
    int pendingCount = 0;
    pendingCountResult.fold((_) {}, (count) => pendingCount = count);

    // 3. Fetch history
    final historyResult = await getAttendanceHistoryUseCase(limit: 20);
    List<AttendanceEntity> history = [];
    historyResult.fold((_) {}, (list) => history = list);

    final initialDuration = _calculateShiftDuration(lastPunch, history);

    emit(state.copyWith(
      status: ClockingStatus.idle,
      lastPunch: lastPunch,
      pendingCount: pendingCount,
      recentPunches: history,
      activeDuration: initialDuration,
      clearErrorMessage: true,
    ));

    _updateTicker(state);

    // Attempt fetching location in background
    add(const ClockingLocationRefreshRequested());

    // If there are pending punches, attempt background sync
    if (pendingCount > 0) {
      add(const ClockingSyncRequested());
    }
  }

  Future<void> _onPunchSubmitted(
    ClockingPunchSubmitted event,
    Emitter<ClockingState> emit,
  ) async {
    emit(state.copyWith(
      status: ClockingStatus.punching,
      clearErrorMessage: true,
    ));

    // Try to get fresh location or fallback to cached state location
    LocationData? location = state.currentLocation;
    try {
      location = await locationService.getCurrentLocation();
    } catch (_) {
      // Keep cached location if available
    }

    final result = await clockInUseCase(
      ClockInParams(
        type: event.type,
        latitude: location?.latitude,
        longitude: location?.longitude,
        accuracy: location?.accuracy,
        note: event.note,
      ),
    );

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ClockingStatus.error,
          errorMessage: failure.message,
        ));
      },
      (punchedEntity) async {
        // Refresh pending count and history
        final pendingResult = await getPendingPunchesCountUseCase();
        final pendingCount = pendingResult.getOrElse(() => state.pendingCount);

        final historyResult = await getAttendanceHistoryUseCase(limit: 20);
        final history = historyResult.getOrElse(() => [punchedEntity, ...state.recentPunches]);

        final newDuration = _calculateShiftDuration(punchedEntity, history);

        final nextStatus = punchedEntity.syncStatus.isSynced
            ? ClockingStatus.synced
            : ClockingStatus.offlineCached;

        emit(state.copyWith(
          status: nextStatus,
          lastPunch: punchedEntity,
          recentPunches: history,
          pendingCount: pendingCount,
          currentLocation: location,
          activeDuration: newDuration,
          clearErrorMessage: true,
        ));

        _updateTicker(state);
      },
    );
  }

  Future<void> _onSyncRequested(
    ClockingSyncRequested event,
    Emitter<ClockingState> emit,
  ) async {
    if (state.isSyncing) return;

    emit(state.copyWith(
      status: ClockingStatus.syncing,
      clearErrorMessage: true,
    ));

    final result = await syncOfflinePunchesUseCase();

    await result.fold(
      (failure) async {
        // Even if sync failed, app is still operational
        emit(state.copyWith(
          status: ClockingStatus.idle,
          errorMessage: 'Sincronizzazione non riuscita: ${failure.message}',
        ));
      },
      (syncedList) async {
        final pendingResult = await getPendingPunchesCountUseCase();
        final pendingCount = pendingResult.getOrElse(() => 0);

        final historyResult = await getAttendanceHistoryUseCase(limit: 20);
        final history = historyResult.getOrElse(() => state.recentPunches);

        final lastPunchResult = await getLastPunchUseCase();
        final lastPunch = lastPunchResult.getOrElse(() => state.lastPunch);

        emit(state.copyWith(
          status: ClockingStatus.synced,
          lastPunch: lastPunch,
          recentPunches: history,
          pendingCount: pendingCount,
          clearErrorMessage: true,
        ));
      },
    );
  }

  Future<void> _onLocationRefreshRequested(
    ClockingLocationRefreshRequested event,
    Emitter<ClockingState> emit,
  ) async {
    emit(state.copyWith(isLocationLoading: true, clearLocationError: true));

    try {
      final location = await locationService.getCurrentLocation();
      emit(state.copyWith(
        currentLocation: location,
        isLocationLoading: false,
        clearLocationError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLocationLoading: false,
        locationError: e.toString().replaceFirst('LocationException: ', ''),
      ));
    }
  }

  void _onTimerTicked(
    ClockingTimerTicked event,
    Emitter<ClockingState> emit,
  ) {
    if (state.lastPunch == null) return;
    if (state.isWorking) {
      final duration = _calculateShiftDuration(state.lastPunch, state.recentPunches);
      emit(state.copyWith(activeDuration: duration));
    }
  }

  Future<void> _onHistoryRefreshRequested(
    ClockingHistoryRefreshRequested event,
    Emitter<ClockingState> emit,
  ) async {
    final historyResult = await getAttendanceHistoryUseCase(limit: 20);
    historyResult.fold(
      (failure) => null,
      (history) => emit(state.copyWith(recentPunches: history)),
    );
  }

  void _updateTicker(ClockingState currentState) {
    _shiftTicker?.cancel();
    if (currentState.isWorking) {
      _shiftTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        add(ClockingTimerTicked(DateTime.now()));
      });
    }
  }

  Duration _calculateShiftDuration(
    AttendanceEntity? currentLastPunch,
    List<AttendanceEntity> history,
  ) {
    if (currentLastPunch == null || currentLastPunch.type == AttendanceType.clockOut) {
      return Duration.zero;
    }

    // Find the most recent clockIn in history
    DateTime? shiftStart;
    for (final punch in history) {
      if (punch.type == AttendanceType.clockIn) {
        shiftStart = punch.timestamp;
        break;
      }
    }

    shiftStart ??= currentLastPunch.timestamp;
    final now = DateTime.now().toUtc();
    final diff = now.difference(shiftStart);
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  Future<void> close() {
    _shiftTicker?.cancel();
    return super.close();
  }
}
