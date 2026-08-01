import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'eduverse_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Cached student table
        await db.execute('''
          CREATE TABLE cached_students (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            grade INTEGER NOT NULL,
            parent_link_required INTEGER NOT NULL,
            is_active INTEGER NOT NULL,
            created_at TEXT
          )
        ''');

        // Cached lecture sessions table for offline learning
        await db.execute('''
          CREATE TABLE cached_lecture_sessions (
            id TEXT PRIMARY KEY,
            student_id TEXT NOT NULL,
            topic TEXT NOT NULL,
            current_segment INTEGER NOT NULL,
            paused_at TEXT,
            completed INTEGER NOT NULL,
            created_at TEXT
          )
        ''');
      },
    );
  }

  /// Cache student profile locally
  Future<void> cacheStudentProfile(Map<String, dynamic> student) async {
    final db = await database;
    await db.insert(
      'cached_students',
      {
        'id': student['id'],
        'name': student['name'],
        'grade': student['grade'],
        'parent_link_required': (student['parent_link_required'] == true) ? 1 : 0,
        'is_active': (student['is_active'] == true) ? 1 : 0,
        'created_at': student['created_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve cached student profile
  Future<Map<String, dynamic>?> getCachedStudentProfile(String studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_students',
      where: 'id = ?',
      whereArgs: [studentId],
    );

    if (maps.isNotEmpty) {
      final item = maps.first;
      return {
        'id': item['id'],
        'name': item['name'],
        'grade': item['grade'],
        'parent_link_required': item['parent_link_required'] == 1,
        'is_active': item['is_active'] == 1,
        'created_at': item['created_at'],
      };
    }
    return null;
  }
}
