import 'package:archub/core/constants/api_constants.dart';
import 'package:archub/core/error/exceptions.dart';
import 'package:archub/core/network/api_client.dart';
import 'package:archub/features/clocking/data/models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  /// Sends a single punch to Laravel `/clock-in` endpoint
  Future<AttendanceModel> clockIn(AttendanceModel punch);

  /// Synchronizes a batch of offline punches to Laravel `/sync` endpoint
  Future<List<AttendanceModel>> syncPunches(List<AttendanceModel> punches);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AttendanceModel> clockIn(AttendanceModel punch) async {
    try {
      final response = await apiClient.post(
        ApiConstants.clockInEndpoint,
        data: punch.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = response.data;
        if (data is Map<String, dynamic>) {
          final payload = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data;
          return AttendanceModel.fromJson(payload);
        }
        return punch.copyWith(
          syncStatus: punch.syncStatus,
          syncedAt: DateTime.now().toUtc(),
        );
      } else {
        throw ServerException(
          message: 'Server returned status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to record punch on remote server: $e');
    }
  }

  @override
  Future<List<AttendanceModel>> syncPunches(List<AttendanceModel> punches) async {
    if (punches.isEmpty) return [];

    try {
      final response = await apiClient.post(
        ApiConstants.syncEndpoint,
        data: {
          'punches': punches.map((p) => p.toJson()).toList(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final list = data['data'] as List;
          return list
              .whereType<Map<String, dynamic>>()
              .map((json) => AttendanceModel.fromJson(json))
              .toList();
        } else if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => AttendanceModel.fromJson(json))
              .toList();
        }

        // Fallback: Return locally updated punches if server responded 200 without detailed array
        return punches.map((p) => p.copyWith(syncedAt: DateTime.now().toUtc())).toList();
      } else {
        throw ServerException(
          message: 'Failed to sync punches: Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to sync punches with server: $e');
    }
  }
}
