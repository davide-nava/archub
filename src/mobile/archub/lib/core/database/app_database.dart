import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String databaseName = 'archub_attendance.db';
  static const int databaseVersion = 1;

  static const String tableOfflinePunches = 'offline_punches';

  // Column definitions
  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnType = 'type';
  static const String columnTimestamp = 'timestamp';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnAccuracy = 'accuracy';
  static const String columnSyncStatus = 'sync_status';
  static const String columnNote = 'note';
  static const String columnCreatedAt = 'created_at';
  static const String columnSyncedAt = 'synced_at';

  static Database? _database;

  /// Allows passing an existing or mock database (useful for testing or custom setup)
  static void setDatabase(Database database) {
    _database = database;
  }

  static Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableOfflinePunches (
        $columnId TEXT PRIMARY KEY,
        $columnUserId TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnLatitude REAL,
        $columnLongitude REAL,
        $columnAccuracy REAL,
        $columnSyncStatus TEXT NOT NULL DEFAULT 'PENDING',
        $columnNote TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnSyncedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_offline_punches_sync_status 
      ON $tableOfflinePunches ($columnSyncStatus)
    ''');

    await db.execute('''
      CREATE INDEX idx_offline_punches_timestamp 
      ON $tableOfflinePunches ($columnTimestamp DESC)
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migration strategies for future versions
  }

  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
