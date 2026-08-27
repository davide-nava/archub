import 'package:get_it/get_it.dart';
import '../../features/clocking/data/datasources/local/sqlite_attendance_local_data_source.dart';
import '../../features/clocking/data/datasources/remote/attendance_remote_data_source.dart';
import '../../features/clocking/data/repositories/attendance_repository_impl.dart';
import '../../features/clocking/domain/repositories/attendance_repository.dart';
import '../../features/clocking/domain/usecases/clock_in_usecase.dart';
import '../../features/clocking/domain/usecases/get_attendance_history_usecase.dart';
import '../../features/clocking/domain/usecases/get_last_punch_usecase.dart';
import '../../features/clocking/domain/usecases/get_pending_punches_count_usecase.dart';
import '../../features/clocking/domain/usecases/sync_offline_punches_usecase.dart';
import '../../features/clocking/presentation/bloc/clocking_bloc.dart';
import '../network/api_client.dart';
import '../services/location_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ----------------------------------------------------
  // Core Services & Network
  // ----------------------------------------------------
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());

  // ----------------------------------------------------
  // Features - Clocking & Attendance
  // ----------------------------------------------------
  // Data Sources
  sl.registerLazySingleton<AttendanceLocalDataSource>(
    () => SqliteAttendanceLocalDataSource(),
  );

  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => ClockInUseCase(sl()));
  sl.registerLazySingleton(() => SyncOfflinePunchesUseCase(sl()));
  sl.registerLazySingleton(() => GetLastPunchUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingPunchesCountUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceHistoryUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => ClockingBloc(
      clockInUseCase: sl(),
      syncOfflinePunchesUseCase: sl(),
      getLastPunchUseCase: sl(),
      getPendingPunchesCountUseCase: sl(),
      getAttendanceHistoryUseCase: sl(),
      locationService: sl(),
    ),
  );
}
