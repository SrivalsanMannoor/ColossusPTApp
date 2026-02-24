import 'package:flutter/material.dart';
import 'exercise.dart';

/// Workout category types matching the design
enum WorkoutCategory {
  fullBody,
  upperBody,
  lowerBody,
  push,
  pull,
}

extension WorkoutCategoryExtension on WorkoutCategory {
  String get displayName {
    switch (this) {
      case WorkoutCategory.fullBody:
        return 'FULL BODY';
      case WorkoutCategory.upperBody:
        return 'UPPER BODY';
      case WorkoutCategory.lowerBody:
        return 'LOWER BODY';
      case WorkoutCategory.push:
        return 'PUSH';
      case WorkoutCategory.pull:
        return 'PULL';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutCategory.fullBody:
        return Icons.accessibility_new;
      case WorkoutCategory.upperBody:
        return Icons.fitness_center;
      case WorkoutCategory.lowerBody:
        return Icons.directions_walk;
      case WorkoutCategory.push:
        return Icons.arrow_upward;
      case WorkoutCategory.pull:
        return Icons.arrow_downward;
    }
  }
}

/// Represents a complete workout routine
class Workout {
  final String id;
  final String name;
  final WorkoutCategory category;
  final int number; // e.g., 1, 2, 3 for "Full Body #1", "Full Body #2"
  final List<WorkoutExercise> exercises;
  final bool isLocked;
  final Color? cardColor;
  final DateTime? lastPerformed;

  const Workout({
    required this.id,
    required this.name,
    required this.category,
    required this.number,
    this.exercises = const [],
    this.isLocked = false,
    this.cardColor,
    this.lastPerformed,
  });

  String get displayName => '${category.displayName} #$number';

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  /// Returns a human-readable string for when the workout was last performed
  String get lastPerformedText {
    if (lastPerformed == null) return 'Never performed';
    final now = DateTime.now();
    final diff = now.difference(lastPerformed!);
    if (diff.inDays == 0) return 'Performed today';
    if (diff.inDays == 1) return 'Performed 1 day ago';
    return 'Performed ${diff.inDays} days ago';
  }

  Workout copyWith({
    String? id,
    String? name,
    WorkoutCategory? category,
    int? number,
    List<WorkoutExercise>? exercises,
    bool? isLocked,
    Color? cardColor,
    DateTime? lastPerformed,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      number: number ?? this.number,
      exercises: exercises ?? this.exercises,
      isLocked: isLocked ?? this.isLocked,
      cardColor: cardColor ?? this.cardColor,
      lastPerformed: lastPerformed ?? this.lastPerformed,
    );
  }
}
