import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton database helper for persisting workout data
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'colossus_workouts.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Track when each preset workout was last performed
    await db.execute('''
      CREATE TABLE workout_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id TEXT NOT NULL,
        performed_at TEXT NOT NULL
      )
    ''');

    // Store user-built custom workouts
    await db.execute('''
      CREATE TABLE saved_workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        exercises_json TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'my_own',
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add type and category columns for v2
      await db.execute(
          "ALTER TABLE saved_workouts ADD COLUMN type TEXT NOT NULL DEFAULT 'my_own'");
      await db.execute('ALTER TABLE saved_workouts ADD COLUMN category TEXT');
    }
  }

  // ── Workout History ──

  /// Record that a workout was performed right now
  Future<void> insertWorkoutPerformed(String workoutId) async {
    final db = await database;
    await db.insert('workout_history', {
      'workout_id': workoutId,
      'performed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get the most recent performed date for a specific workout
  Future<DateTime?> getLastPerformed(String workoutId) async {
    final db = await database;
    final results = await db.query(
      'workout_history',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'performed_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DateTime.parse(results.first['performed_at'] as String);
  }

  /// Get the most recent performed date for every workout that has been done
  Future<Map<String, DateTime>> getAllLastPerformed() async {
    final db = await database;
    // Use a subquery to get the max performed_at per workout_id
    final results = await db.rawQuery('''
      SELECT workout_id, MAX(performed_at) as last_performed
      FROM workout_history
      GROUP BY workout_id
    ''');

    final map = <String, DateTime>{};
    for (final row in results) {
      map[row['workout_id'] as String] =
          DateTime.parse(row['last_performed'] as String);
    }
    return map;
  }

  // ── Saved Custom Workouts ──

  /// Save a custom workout with its exercises as JSON
  /// [type] is either 'customised' (modified preset) or 'my_own' (built from scratch)
  /// [category] is the workout category (e.g., 'Full Body', 'Upper Body')
  Future<int> saveCustomWorkout(
    String name,
    List<Map<String, dynamic>> exercises, {
    String type = 'my_own',
    String? category,
  }) async {
    final db = await database;
    return await db.insert('saved_workouts', {
      'name': name,
      'exercises_json': jsonEncode(exercises),
      'type': type,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all saved custom workouts
  Future<List<Map<String, dynamic>>> getSavedWorkouts() async {
    final db = await database;
    return await db.query('saved_workouts', orderBy: 'created_at DESC');
  }
}
