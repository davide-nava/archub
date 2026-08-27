import 'package:archub/core/database/app_database.dart';
import 'package:archub/core/error/exceptions.dart';
import 'package:archub/features/clocking/data/models/attendance_model.dart';
import 'package:archub/features/clocking/domain/entities/sync_status.dart';
import 'package:sqflite/sqflite.dart';

abstract class AttendanceLocalDataSource {
  Future<void> insertPunch(AttendanceModel model);
  Future<List<AttendanceModel>> getPendingPunches();
  Future<void> markPunchesAsSynced(List<String> ids, {DateTime? syncedAt});
  Future<List<AttendanceModel>> getAllPunches({int limit = 50});
  Future<AttendanceModel?> getLastPunch();
  Future<int> getPendingCount();
  Future<void> deletePunch(String id);
  Future<void> clearAll();
}

class SqliteAttendanceLocalDataSource implements AttendanceLocalDataSource {
  final Database? database;

  SqliteAttendanceLocalDataSource({this.database});

  Future<Database> get _db async => database ?? await AppDatabase.getDatabase();

  @override
  Future<void> insertPunch(AttendanceModel model) async {
    try {
      final db = await _db;
      await db.insert(
        AppDatabase.tableOfflinePunches,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save punch locally: $e');
    }
  }

  @override
  Future<List<AttendanceModel>> getPendingPunches() async {
    try {
      final db = await _db;
      final maps = await db.query(
        AppDatabase.tableOfflinePunches,
        where: '${AppDatabase.columnSyncStatus} = ?',
        whereArgs: [SyncStatus.pending.value],
        orderBy: '${AppDatabase.columnTimestamp} ASC',
      );

      return maps.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve pending punches: $e');
    }
  }

  @override
  Future<void> markPunchesAsSynced(List<String> ids, {DateTime? syncedAt}) async {
    if (ids.isEmpty) return;
    try {
      final db = await _db;
      final syncTime = (syncedAt ?? DateTime.now().toUtc()).toIso8601String();

      final batch = db.batch();
      for (final id in ids) {
        batch.update(
          AppDatabase.tableOfflinePunches,
          {
            AppDatabase.columnSyncStatus: SyncStatus.synced.value,
            AppDatabase.columnSyncedAt: syncTime,
          },
          where: '${AppDatabase.columnId} = ?',
          whereArgs: [id],
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(message: 'Failed to mark punches as synced: $e');
    }
  }

  @override
  Future<List<AttendanceModel>> getAllPunches({int limit = 50}) async {
    try {
      final db = await _db;
      final maps = await db.query(
        AppDatabase.tableOfflinePunches,
        orderBy: '${AppDatabase.columnTimestamp} DESC',
        limit: limit,
      );

      return maps.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve attendance history: $e');
    }
  }

  @override
  Future<AttendanceModel?> getLastPunch() async {
    try {
      final db = await _db;
      final maps = await db.query(
        AppDatabase.tableOfflinePunches,
        orderBy: '${AppDatabase.columnTimestamp} DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }
      return AttendanceModel.fromMap(maps.first);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve last punch: $e');
    }
  }

  @override
  Future<int> getPendingCount() async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppDatabase.tableOfflinePunches} WHERE ${AppDatabase.columnSyncStatus} = ?',
        [SyncStatus.pending.value],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheException(message: 'Failed to count pending punches: $e');
    }
  }

  @override
  Future<void> deletePunch(String id) async {
    try {
      final db = await _db;
      await db.delete(
        AppDatabase.tableOfflinePunches,
        where: '${AppDatabase.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException(message: 'Failed to delete punch: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final db = await _db;
      await db.delete(AppDatabase.tableOfflinePunches);
    } catch (e) {
      throw CacheException(message: 'Failed to clear punches: $e');
    }
  }
}
