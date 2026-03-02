import 'package:flutter/material.dart';
import '../data/workout_data.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/database_helper.dart';

/// Manages workout state throughout the app
class WorkoutProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // Current selected workout
  Workout? _selectedWorkout;

  // Custom workout being built
  List<WorkoutExercise> _customExercises = [];

  // Superset pairs: each entry is a list of two indices that form a superset
  List<List<int>> _supersetPairs = [];

  // Exercise library selections (id -> count)
  final Map<String, int> _exerciseSelections = {};

  // Filter/sort state
  String _searchQuery = '';
  String? _muscleGroupFilter;

  /// Active filter: 'Upper Body', 'Lower Body', 'Push', or 'Pull'
  String? _activeFilter;

  // Cached preset workouts with lastPerformed dates
  List<Workout> _cachedPresetWorkouts = [];

  // Saved custom workouts loaded from SQLite
  List<Map<String, dynamic>> _savedWorkouts = [];

  // Getters
  Workout? get selectedWorkout => _selectedWorkout;
  List<WorkoutExercise> get customExercises =>
      List.unmodifiable(_customExercises);
  Map<String, int> get exerciseSelections =>
      Map.unmodifiable(_exerciseSelections);
  List<List<int>> get supersetPairs => List.unmodifiable(_supersetPairs);
  String get searchQuery => _searchQuery;
  String? get muscleGroupFilter => _muscleGroupFilter;
  String? get activeFilter => _activeFilter;

  List<Map<String, dynamic>> get savedWorkouts =>
      List.unmodifiable(_savedWorkouts);

  List<Workout> get presetWorkouts => _cachedPresetWorkouts.isEmpty
      ? WorkoutData.presetWorkouts
      : _cachedPresetWorkouts;

  List<Exercise> get filteredExercises {
    var exercises = ExerciseLibrary.allExercises;

    if (_searchQuery.isNotEmpty) {
      exercises = exercises
          .where(
              (e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply the active filter (Upper Body / Lower Body / Push / Pull)
    if (_activeFilter != null) {
      switch (_activeFilter) {
        case 'Upper Body':
          exercises =
              exercises.where((e) => e.category == 'Upper Body').toList();
          break;
        case 'Lower Body':
          exercises =
              exercises.where((e) => e.category == 'Lower Body').toList();
          break;
        case 'Push':
          exercises = exercises.where((e) => e.movement == 'Push').toList();
          break;
        case 'Pull':
          exercises = exercises.where((e) => e.movement == 'Pull').toList();
          break;
      }
    }

    // Additional muscle group sub-filter if set
    if (_muscleGroupFilter != null) {
      exercises =
          exercises.where((e) => e.muscleGroup == _muscleGroupFilter).toList();
    }

    return exercises;
  }

  int get totalSelectedExercises =>
      _exerciseSelections.values.where((v) => v > 0).length;

  // ── Database Initialization ──

  /// Load last-performed dates from SQLite and merge into preset workouts
  Future<void> initDatabase() async {
    final lastPerformedMap = await _db.getAllLastPerformed();
    _cachedPresetWorkouts = WorkoutData.presetWorkouts.map((workout) {
      final lastDate = lastPerformedMap[workout.id];
      if (lastDate != null) {
        return workout.copyWith(lastPerformed: lastDate);
      }
      return workout;
    }).toList();

    // Load saved custom workouts
    _savedWorkouts = await _db.getSavedWorkouts();

    notifyListeners();
  }

  // ── Workout History ──

  /// Record that a preset workout was performed and update in-memory state
  Future<void> recordWorkoutPerformed(String workoutId) async {
    await _db.insertWorkoutPerformed(workoutId);
    // Update cached list
    final now = DateTime.now();
    _cachedPresetWorkouts = _cachedPresetWorkouts.map((w) {
      if (w.id == workoutId) {
        return w.copyWith(lastPerformed: now);
      }
      return w;
    }).toList();
    notifyListeners();
  }

  // ── Save Custom Workout ──

  /// Persist the current custom workout to SQLite
  /// [type] is 'customised' (modified preset) or 'my_own' (built from scratch)
  Future<bool> saveCustomWorkoutToDB({
    String? name,
    String type = 'my_own',
    String? category,
  }) async {
    if (_customExercises.isEmpty) return false;
    final workoutName = name ?? 'Custom Workout';
    final exercisesList = _customExercises
        .map((we) => {
              'exercise_id': we.exercise.id,
              'exercise_name': we.exercise.name,
              'sets': we.sets,
              'reps': we.reps,
              'order': we.order,
              'superset_group': _getSupersetGroupForIndex(we.order),
            })
        .toList();
    await _db.saveCustomWorkout(
      workoutName,
      exercisesList,
      type: type,
      category: category,
    );

    // Refresh saved workouts list
    _savedWorkouts = await _db.getSavedWorkouts();
    notifyListeners();

    return true;
  }

  int? _getSupersetGroupForIndex(int index) {
    for (int i = 0; i < _supersetPairs.length; i++) {
      if (_supersetPairs[i].contains(index)) return i;
    }
    return null;
  }

  // Select a preset workout
  void selectWorkout(Workout workout) {
    _selectedWorkout = workout;
    notifyListeners();
  }

  void clearSelection() {
    _selectedWorkout = null;
    notifyListeners();
  }

  // ── Edit Existing Workout ──

  // Track which preset workout is being edited (null = new custom workout)
  String? _editingWorkoutId;
  String? get editingWorkoutId => _editingWorkoutId;

  /// Load a preset workout's exercises into customExercises for editing
  void loadPresetWorkoutForEditing(Workout workout) {
    _editingWorkoutId = workout.id;
    _customExercises = workout.exercises.map((we) => we.copyWith()).toList();
    notifyListeners();
  }

  /// Clear editing state (used when building a brand new custom workout)
  void clearEditingState() {
    _editingWorkoutId = null;
  }

  /// Update a preset workout's exercises in-memory (after editing)
  void updatePresetWorkoutExercises(
      String workoutId, List<WorkoutExercise> exercises) {
    _cachedPresetWorkouts = _cachedPresetWorkouts.map((w) {
      if (w.id == workoutId) {
        return w.copyWith(exercises: exercises);
      }
      return w;
    }).toList();
    notifyListeners();
  }

  // Exercise library management
  void incrementExercise(String exerciseId) {
    _exerciseSelections[exerciseId] =
        (_exerciseSelections[exerciseId] ?? 0) + 1;
    notifyListeners();
  }

  void decrementExercise(String exerciseId) {
    final current = _exerciseSelections[exerciseId] ?? 0;
    if (current > 0) {
      if (current == 1) {
        _exerciseSelections.remove(exerciseId);
      } else {
        _exerciseSelections[exerciseId] = current - 1;
      }
      notifyListeners();
    }
  }

  int getExerciseCount(String exerciseId) {
    return _exerciseSelections[exerciseId] ?? 0;
  }

  void clearExerciseSelections() {
    _exerciseSelections.clear();
    notifyListeners();
  }

  // Build custom workout from selections
  void buildCustomWorkout() {
    _customExercises = [];
    _supersetPairs = []; // clear supersets on new build
    int order = 0;

    for (final entry in _exerciseSelections.entries) {
      final exercise = ExerciseLibrary.findById(entry.key);
      if (exercise != null && entry.value > 0) {
        _customExercises.add(WorkoutExercise(
          exercise: exercise,
          sets: exercise.defaultSets,
          reps: exercise.defaultReps,
          order: order++,
        ));
      }
    }
    notifyListeners();
  }

  // Update exercise in custom workout
  void updateCustomExercise(int index, {int? sets, int? reps}) {
    if (index >= 0 && index < _customExercises.length) {
      _customExercises[index] = _customExercises[index].copyWith(
        sets: sets,
        reps: reps,
      );
      notifyListeners();
    }
  }

  // Reorder exercises in custom workout
  void reorderExercise(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Check if the dragged item is in a superset
    final partnerIdx = getSupersetPartner(oldIndex);

    if (partnerIdx != null) {
      // Move both superset exercises together as a group
      final lower = oldIndex < partnerIdx ? oldIndex : partnerIdx;
      final higher = oldIndex < partnerIdx ? partnerIdx : oldIndex;

      // Remove both items (remove higher first to preserve lower index)
      final higherItem = _customExercises.removeAt(higher);
      final lowerItem = _customExercises.removeAt(lower);

      // Calculate target insertion index after removal
      int insertAt = newIndex;
      // Adjust for the two removed items
      if (newIndex > higher) {
        insertAt -= 2;
      } else if (newIndex > lower) {
        insertAt -= 1;
      }
      if (insertAt < 0) insertAt = 0;
      if (insertAt > _customExercises.length) {
        insertAt = _customExercises.length;
      }

      // Insert both items at the target: lower item first, then higher item after
      _customExercises.insert(insertAt, lowerItem);
      _customExercises.insert(insertAt + 1, higherItem);

      // Rebuild order values
      for (int i = 0; i < _customExercises.length; i++) {
        _customExercises[i] = _customExercises[i].copyWith(order: i);
      }

      // Rebuild superset pairs with new indices
      _supersetPairs = _supersetPairs.map((pair) {
        if (pair.contains(lower) && pair.contains(higher)) {
          return [insertAt, insertAt + 1];
        }
        // Recalculate other pair indices based on the moves
        return pair.map((idx) {
          // Count how many of the removed indices were before this idx
          int shift = 0;
          if (lower < idx) shift++;
          if (higher < idx) shift++;
          int newIdx = idx - shift;

          // Count how many inserted indices are at or before the new idx
          int insertShift = 0;
          if (insertAt <= newIdx) insertShift++;
          if (insertAt + 1 <= newIdx + insertShift) insertShift++;

          return newIdx + insertShift;
        }).toList();
      }).toList();
    } else {
      // Single item reorder (no superset)
      final item = _customExercises.removeAt(oldIndex);
      _customExercises.insert(newIndex, item);

      // Update order values
      for (int i = 0; i < _customExercises.length; i++) {
        _customExercises[i] = _customExercises[i].copyWith(order: i);
      }

      // Update superset pair indices after reorder
      _supersetPairs = _supersetPairs.map((pair) {
        return pair.map((idx) {
          if (idx == oldIndex) return newIndex;
          if (oldIndex < newIndex) {
            if (idx > oldIndex && idx <= newIndex) return idx - 1;
          } else {
            if (idx >= newIndex && idx < oldIndex) return idx + 1;
          }
          return idx;
        }).toList();
      }).toList();
    }

    notifyListeners();
  }

  /// Reorder exercises based on a new index order (used by group-based reorder)
  void reorderByNewOrder(List<int> newOrder) {
    if (newOrder.length != _customExercises.length) return;

    // Build a new list based on the new order
    final newList = newOrder.map((i) => _customExercises[i]).toList();

    // Build index mapping: old index -> new index
    final indexMap = <int, int>{};
    for (int newIdx = 0; newIdx < newOrder.length; newIdx++) {
      indexMap[newOrder[newIdx]] = newIdx;
    }

    // Update superset pairs with new indices
    _supersetPairs = _supersetPairs.map((pair) {
      return pair.map((idx) => indexMap[idx] ?? idx).toList();
    }).toList();

    // Update order values
    for (int i = 0; i < newList.length; i++) {
      newList[i] = newList[i].copyWith(order: i);
    }

    _customExercises = newList;
    notifyListeners();
  }

  void removeFromCustomWorkout(int index) {
    if (index >= 0 && index < _customExercises.length) {
      // Remove from any superset pair
      _supersetPairs.removeWhere((pair) => pair.contains(index));
      // Adjust indices for remaining pairs
      _supersetPairs = _supersetPairs.map((pair) {
        return pair.map((idx) => idx > index ? idx - 1 : idx).toList();
      }).toList();
      _customExercises.removeAt(index);
      notifyListeners();
    }
  }

  // ── Superset Management ──

  /// Toggle a superset between two exercise indices
  void toggleSuperset(int indexA, int indexB) {
    // Check if this pair already exists
    final existingIdx = _supersetPairs.indexWhere(
      (pair) => (pair.contains(indexA) && pair.contains(indexB)),
    );
    if (existingIdx >= 0) {
      _supersetPairs.removeAt(existingIdx);
    } else {
      // Remove these indices from any existing pairs first
      _supersetPairs.removeWhere(
        (pair) => pair.contains(indexA) || pair.contains(indexB),
      );

      // Auto-group: move the partner so they are adjacent
      final lower = indexA < indexB ? indexA : indexB;
      final higher = indexA < indexB ? indexB : indexA;

      if (higher != lower + 1) {
        // Move the higher-index exercise to right after the lower one
        final item = _customExercises.removeAt(higher);
        final insertAt = lower + 1;
        _customExercises.insert(insertAt, item);

        // Update order values
        for (int i = 0; i < _customExercises.length; i++) {
          _customExercises[i] = _customExercises[i].copyWith(order: i);
        }

        // Update all existing superset pair indices after the move
        _supersetPairs = _supersetPairs.map((pair) {
          return pair.map((idx) {
            if (idx == higher) return insertAt;
            // Items between insertAt and higher shift up by 1
            if (idx >= insertAt && idx < higher) return idx + 1;
            return idx;
          }).toList();
        }).toList();

        // Add the pair with updated indices
        _supersetPairs.add([lower, lower + 1]);
      } else {
        // Already adjacent, just add the pair
        _supersetPairs.add([lower, higher]);
      }
    }
    notifyListeners();
  }

  /// Get the superset partner index for a given index, or null
  int? getSupersetPartner(int index) {
    for (final pair in _supersetPairs) {
      if (pair.contains(index)) {
        return pair.firstWhere((i) => i != index);
      }
    }
    return null;
  }

  /// Check if an index is part of a superset
  bool isInSuperset(int index) {
    return _supersetPairs.any((pair) => pair.contains(index));
  }

  // Filter/search
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setMuscleGroupFilter(String? group) {
    _muscleGroupFilter = group;
    notifyListeners();
  }

  void setActiveFilter(String? filter) {
    _activeFilter = filter;
    _muscleGroupFilter = null; // reset sub-filter when main filter changes
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _muscleGroupFilter = null;
    _activeFilter = null;
    notifyListeners();
  }
}
