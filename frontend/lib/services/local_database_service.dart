import 'dart:convert';
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
    final path = join(documentsDirectory.path, 'eduverse_offline_v2.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // 1. Cached Student Profile
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

        // 2. Cached Doubts & Explanations
        await db.execute('''
          CREATE TABLE cached_doubts (
            id TEXT PRIMARY KEY,
            student_id TEXT NOT NULL,
            question_text TEXT NOT NULL,
            language TEXT NOT NULL,
            answer_summary TEXT NOT NULL,
            explanation_json TEXT NOT NULL,
            created_at TEXT
          )
        ''');

        // 3. Cached Quizzes
        await db.execute('''
          CREATE TABLE cached_quizzes (
            id TEXT PRIMARY KEY,
            student_id TEXT NOT NULL,
            topic TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            questions_json TEXT NOT NULL,
            created_at TEXT
          )
        ''');

        // 4. Cached Notes
        await db.execute('''
          CREATE TABLE cached_notes (
            id TEXT PRIMARY KEY,
            student_id TEXT NOT NULL,
            subject TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        // 5. Cached Timetable Schedule
        await db.execute('''
          CREATE TABLE cached_schedule (
            id TEXT PRIMARY KEY,
            student_id TEXT NOT NULL,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            subject TEXT NOT NULL,
            item_datetime TEXT NOT NULL,
            reminder_set INTEGER NOT NULL
          )
        ''');

        // 6. Cached Weak Topics
        await db.execute('''
          CREATE TABLE cached_weak_topics (
            id TEXT PRIMARY KEY,
            student_id TEXT NOT NULL,
            topic TEXT NOT NULL,
            times_wrong INTEGER NOT NULL,
            last_updated TEXT
          )
        ''');

        // 7. Offline Sync Queue
        await db.execute('''
          CREATE TABLE sync_queue (
            id TEXT PRIMARY KEY,
            action_type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Add item to offline sync queue
  Future<void> addToSyncQueue(String actionType, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action_type': actionType,
        'payload_json': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }


  /// Flush offline sync queue when connection returns
  Future<List<Map<String, dynamic>>> getSyncQueueItems() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  /// Cache Notes
  Future<void> cacheNotes(List<Map<String, dynamic>> notes) async {
    final db = await database;
    for (var n in notes) {
      await db.insert(
        'cached_notes',
        {
          'id': n['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'student_id': n['student_id'] ?? '',
          'subject': n['subject'] ?? 'General',
          'title': n['title'] ?? '',
          'content': n['content'] ?? '',
          'tags': (n['tags'] ?? []).toString(),
          'updated_at': n['updated_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get Cached Notes
  Future<List<Map<String, dynamic>>> getCachedNotes() async {
    final db = await database;
    return await db.query('cached_notes', orderBy: 'updated_at DESC');
  }
}
