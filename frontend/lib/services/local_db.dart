import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eduverse_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Example local caching tables
    await db.execute('''
      CREATE TABLE offline_lectures (
        id TEXT PRIMARY KEY,
        topic TEXT NOT NULL,
        current_segment INTEGER NOT NULL,
        paused_at TEXT
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
