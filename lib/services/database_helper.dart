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
      version: 3,
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

    // Store per-exercise set logs for progress tracking
    await db.execute('''
      CREATE TABLE exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_name TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL DEFAULT 0,
        reps INTEGER NOT NULL DEFAULT 0,
        logged_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE saved_workouts ADD COLUMN type TEXT NOT NULL DEFAULT 'my_own'");
      await db.execute('ALTER TABLE saved_workouts ADD COLUMN category TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE exercise_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_name TEXT NOT NULL,
          set_number INTEGER NOT NULL,
          weight REAL NOT NULL DEFAULT 0,
          reps INTEGER NOT NULL DEFAULT 0,
          logged_at TEXT NOT NULL
        )
      ''');
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

  /// Update an existing saved workout by its DB ID
  Future<int> updateCustomWorkout(
    int id,
    String name,
    List<Map<String, dynamic>> exercises, {
    String type = 'my_own',
    String? category,
  }) async {
    final db = await database;
    return await db.update(
      'saved_workouts',
      {
        'name': name,
        'exercises_json': jsonEncode(exercises),
        'type': type,
        'category': category,
        'created_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all saved custom workouts
  Future<List<Map<String, dynamic>>> getSavedWorkouts() async {
    final db = await database;
    return await db.query('saved_workouts', orderBy: 'created_at DESC');
  }

  // ── Exercise Logs ──

  /// Save all sets for an exercise after completing a workout
  Future<void> saveExerciseLog(
    String exerciseName,
    List<Map<String, dynamic>> sets,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    for (final set in sets) {
      await db.insert('exercise_logs', {
        'exercise_name': exerciseName,
        'set_number': set['set_number'],
        'weight': set['weight'],
        'reps': set['reps'],
        'logged_at': now,
      });
    }
  }

  /// Get the most recent log for an exercise (returns list of sets)
  Future<List<Map<String, dynamic>>> getLastExerciseLog(
      String exerciseName) async {
    final db = await database;
    // Get the latest logged_at date
    final latest = await db.rawQuery(
      'SELECT MAX(logged_at) as max_date FROM exercise_logs WHERE exercise_name = ?',
      [exerciseName],
    );
    final maxDate = latest.isNotEmpty ? latest.first['max_date'] : null;
    if (maxDate == null) return [];
    return await db.query(
      'exercise_logs',
      where: 'exercise_name = ? AND logged_at = ?',
      whereArgs: [exerciseName, maxDate],
      orderBy: 'set_number ASC',
    );
  }

  /// Get full exercise history: all logs grouped by date
  Future<List<Map<String, dynamic>>> getExerciseHistory(
      String exerciseName) async {
    final db = await database;
    return await db.query(
      'exercise_logs',
      where: 'exercise_name = ?',
      whereArgs: [exerciseName],
      orderBy: 'logged_at DESC, set_number ASC',
    );
  }
}
