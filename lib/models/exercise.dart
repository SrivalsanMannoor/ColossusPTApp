/// Represents an exercise in the workout library
class Exercise {
  final String id;
  final String name;
  final String? description;
  final bool isTimeBased;
  final int defaultSets;
  final int defaultReps;
  final String? muscleGroup;

  /// 'Upper Body' or 'Lower Body' (or 'Cardio')
  final String? category;

  /// 'Push' or 'Pull' (upper body only, null for lower body / cardio)
  final String? movement;

  /// Primary muscle engaged
  final String? primaryMuscle;

  /// Equipment required
  final String? equipment;

  const Exercise({
    required this.id,
    required this.name,
    this.description,
    this.isTimeBased = false,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.muscleGroup,
    this.category,
    this.movement,
    this.primaryMuscle,
    this.equipment,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    bool? isTimeBased,
    int? defaultSets,
    int? defaultReps,
    String? muscleGroup,
    String? category,
    String? movement,
    String? primaryMuscle,
    String? equipment,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isTimeBased: isTimeBased ?? this.isTimeBased,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      category: category ?? this.category,
      movement: movement ?? this.movement,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      equipment: equipment ?? this.equipment,
    );
  }
}

/// Represents an exercise added to a workout with quantity
class WorkoutExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final int order;

  const WorkoutExercise({
    required this.exercise,
    this.sets = 3,
    required this.reps,
    this.order = 0,
  });

  WorkoutExercise copyWith({
    Exercise? exercise,
    int? sets,
    int? reps,
    int? order,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      order: order ?? this.order,
    );
  }
}
