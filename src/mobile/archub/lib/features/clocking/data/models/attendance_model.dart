import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.timestamp,
    super.latitude,
    super.longitude,
    super.accuracy,
    super.syncStatus = SyncStatus.pending,
    super.note,
    required super.createdAt,
    super.syncedAt,
  });

  /// Factory constructor to create a Model from a Domain Entity
  factory AttendanceModel.fromEntity(AttendanceEntity entity) {
    return AttendanceModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      syncStatus: entity.syncStatus,
      note: entity.note,
      createdAt: entity.createdAt,
      syncedAt: entity.syncedAt,
    );
  }

  /// Deserialization from SQLite Map
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: AttendanceType.fromString(map['type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      syncStatus: SyncStatus.fromString(map['sync_status'] as String? ?? 'PENDING'),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
    );
  }

  /// Serialization to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.apiValue,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'sync_status': syncStatus.value,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  /// Deserialization from Laravel API Response
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId'])?.toString() ?? '',
      type: AttendanceType.fromString((json['type'] ?? json['attendance_type']) as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      syncStatus: json['sync_status'] != null
          ? SyncStatus.fromString(json['sync_status'] as String)
          : SyncStatus.synced,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now().toUtc(),
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at'] as String) : null,
    );
  }

  /// Serialization to Laravel API Payload
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.apiValue,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  AttendanceModel copyWith({
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
    return AttendanceModel(
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
}
