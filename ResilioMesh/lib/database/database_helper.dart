import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('resilio_mesh.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Bumped to 4 to include the priority column
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reportId TEXT UNIQUE,
            senderName TEXT,
            mobileNumber TEXT,
            title TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL,
            priority REAL DEFAULT 1.0,
            mediaPaths TEXT,
            timestamp INTEGER,
            status TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE reports ADD COLUMN senderName TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE reports ADD COLUMN mobileNumber TEXT');
          await db.execute('ALTER TABLE reports ADD COLUMN mediaPaths TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE reports ADD COLUMN priority REAL DEFAULT 1.0');
        }
      },
    );
  }

  /// Inserts a report only if reportId doesn't already exist
  Future<bool> insertReportIfNew(Map<String, dynamic> reportMap) async {
    final db = await instance.database;
    try {
      // Clean copy to ensure only valid table columns are passed to SQLite
      Map<String, dynamic> cleanData = {
        'reportId': reportMap['reportId'],
        'senderName': reportMap['senderName'],
        'mobileNumber': reportMap['mobileNumber'],
        'title': reportMap['title'],
        'description': reportMap['description'],
        'latitude': reportMap['latitude'] ?? 0.0,
        'longitude': reportMap['longitude'] ?? 0.0,
        'priority': reportMap['priority'] ?? 1.0, // Ensures priority is never null
        'mediaPaths': reportMap['mediaPaths'] ?? reportMap['tempFilePath'],
        'timestamp': reportMap['timestamp'] is String
            ? int.tryParse(reportMap['timestamp'].toString()) ?? DateTime.now().millisecondsSinceEpoch
            : reportMap['timestamp'],
        'status': reportMap['status'] ?? 'PENDING_SYNC',
      };

      int result = await db.insert(
        'reports',
        cleanData,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return result > 0;
    } catch (e) {
      print("Database insertion error: $e");
      return false;
    }
  }

  /// Fetch pending reports for cloud backend upload
  Future<List<Map<String, dynamic>>> getPendingSyncReports() async {
    final db = await instance.database;
    return await db.query(
      'reports',
      where: 'status = ?',
      whereArgs: ['PENDING_SYNC'],
    );
  }

  /// Alias method for P2P sync
  Future<List<Map<String, dynamic>>> getUnsyncedReports() async {
    return await getPendingSyncReports();
  }

  /// Alias method for P2P sync
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    return await getPendingSyncReports();
  }

  /// Update specific report status by reportId
  Future<int> updateReportStatus(String reportId, String status) async {
    final db = await instance.database;
    return await db.update(
      'reports',
      {'status': status},
      where: 'reportId = ?',
      whereArgs: [reportId],
    );
  }

  /// Mark all pending reports as SYNCED
  Future<int> markAllReportsAsSynced() async {
    final db = await instance.database;
    return await db.update(
      'reports',
      {'status': 'SYNCED'},
      where: 'status = ?',
      whereArgs: ['PENDING_SYNC'],
    );
  }

  /// Get all stored reports ordered by timestamp descending
  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await instance.database;
    return await db.query('reports', orderBy: 'timestamp DESC');
  }
}