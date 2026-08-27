import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';
import 'package:equatable/equatable.dart';

class AttendanceEntity extends Equatable {
  final String id;
  final String userId;
  final AttendanceType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final SyncStatus syncStatus;
  final String? note;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const AttendanceEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.syncStatus = SyncStatus.pending,
    this.note,
    required this.createdAt,
    this.syncedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  AttendanceEntity copyWith({
    String? id,
    String? userId,
    AttendanceType? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
    SyncStatus? syncStatus,
    String? note,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return AttendanceEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      syncStatus: syncStatus ?? this.syncStatus,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        timestamp,
        latitude,
        longitude,
        accuracy,
        syncStatus,
        note,
        createdAt,
        syncedAt,
      ];
}
