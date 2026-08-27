import 'package:archub/core/services/location_service.dart';
import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';
import 'package:archub/features/clocking/domain/usecases/clock_in_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/get_attendance_history_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/get_last_punch_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/get_pending_punches_count_usecase.dart';
import 'package:archub/features/clocking/domain/usecases/sync_offline_punches_usecase.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_bloc.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_event.dart';
import 'package:archub/features/clocking/presentation/bloc/clocking_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockClockInUseCase extends Mock implements ClockInUseCase {}

class MockSyncOfflinePunchesUseCase extends Mock implements SyncOfflinePunchesUseCase {}

class MockGetLastPunchUseCase extends Mock implements GetLastPunchUseCase {}

class MockGetPendingPunchesCountUseCase extends Mock
    implements GetPendingPunchesCountUseCase {}

class MockGetAttendanceHistoryUseCase extends Mock
    implements GetAttendanceHistoryUseCase {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late ClockingBloc bloc;
  late MockClockInUseCase mockClockInUseCase;
  late MockSyncOfflinePunchesUseCase mockSyncOfflinePunchesUseCase;
  late MockGetLastPunchUseCase mockGetLastPunchUseCase;
  late MockGetPendingPunchesCountUseCase mockGetPendingPunchesCountUseCase;
  late MockGetAttendanceHistoryUseCase mockGetAttendanceHistoryUseCase;
  late MockLocationService mockLocationService;

  setUpAll(() {
    registerFallbackValue(
      const ClockInParams(type: AttendanceType.clockIn),
    );
  });

  setUp(() {
    mockClockInUseCase = MockClockInUseCase();
    mockSyncOfflinePunchesUseCase = MockSyncOfflinePunchesUseCase();
    mockGetLastPunchUseCase = MockGetLastPunchUseCase();
    mockGetPendingPunchesCountUseCase = MockGetPendingPunchesCountUseCase();
    mockGetAttendanceHistoryUseCase = MockGetAttendanceHistoryUseCase();
    mockLocationService = MockLocationService();

    when(() => mockLocationService.getCurrentLocation()).thenAnswer(
      (_) async => const LocationData(latitude: 45.4642, longitude: 9.1900, accuracy: 5.0),
    );

    bloc = ClockingBloc(
      clockInUseCase: mockClockInUseCase,
      syncOfflinePunchesUseCase: mockSyncOfflinePunchesUseCase,
      getLastPunchUseCase: mockGetLastPunchUseCase,
      getPendingPunchesCountUseCase: mockGetPendingPunchesCountUseCase,
      getAttendanceHistoryUseCase: mockGetAttendanceHistoryUseCase,
      locationService: mockLocationService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tPunch = AttendanceEntity(
    id: 'punch-uuid-1',
    userId: 'user-01',
    type: AttendanceType.clockIn,
    timestamp: DateTime.utc(2026, 8, 27, 8, 0, 0),
    syncStatus: SyncStatus.synced,
    createdAt: DateTime.utc(2026, 8, 27, 8, 0, 0),
  );

  final tOfflinePunch = AttendanceEntity(
    id: 'punch-uuid-2',
    userId: 'user-01',
    type: AttendanceType.clockIn,
    timestamp: DateTime.utc(2026, 8, 27, 8, 0, 0),
    syncStatus: SyncStatus.pending,
    createdAt: DateTime.utc(2026, 8, 27, 8, 0, 0),
  );

  test('initial state is ClockingState.initial', () {
    expect(bloc.state, ClockingState.initial());
  });

  group('ClockingPunchSubmitted', () {
    blocTest<ClockingBloc, ClockingState>(
      'emits [punching, synced] when punch is successfully recorded and synced online',
      build: () {
        when(() => mockClockInUseCase(any())).thenAnswer((_) async => Right(tPunch));
        when(() => mockGetPendingPunchesCountUseCase()).thenAnswer((_) async => const Right(0));
        when(() => mockGetAttendanceHistoryUseCase(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right([tPunch]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ClockingPunchSubmitted(type: AttendanceType.clockIn)),
      expect: () => [
        isA<ClockingState>().having((s) => s.status, 'status', ClockingStatus.punching),
        isA<ClockingState>()
            .having((s) => s.status, 'status', ClockingStatus.synced)
            .having((s) => s.lastPunch, 'lastPunch', tPunch)
            .having((s) => s.pendingCount, 'pendingCount', 0),
      ],
    );

    blocTest<ClockingBloc, ClockingState>(
      'emits [punching, offlineCached] when punch is saved offline (PENDING status)',
      build: () {
        when(() => mockClockInUseCase(any())).thenAnswer((_) async => Right(tOfflinePunch));
        when(() => mockGetPendingPunchesCountUseCase()).thenAnswer((_) async => const Right(1));
        when(() => mockGetAttendanceHistoryUseCase(limit: any(named: 'limit')))
            .thenAnswer((_) async => Right([tOfflinePunch]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ClockingPunchSubmitted(type: AttendanceType.clockIn)),
      expect: () => [
        isA<ClockingState>().having((s) => s.status, 'status', ClockingStatus.punching),
        isA<ClockingState>()
            .having((s) => s.status, 'status', ClockingStatus.offlineCached)
            .having((s) => s.lastPunch, 'lastPunch', tOfflinePunch)
            .having((s) => s.pendingCount, 'pendingCount', 1),
      ],
    );
  });
}
