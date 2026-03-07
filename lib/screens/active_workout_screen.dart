import 'dart:async';
import 'package:colossus_pt/data/workout_data.dart';
import 'package:colossus_pt/services/database_helper.dart';
import 'package:colossus_pt/theme.dart';
import 'package:colossus_pt/widgets/feedback_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data model for a single set during an active workout
class ActiveSet {
  double weight;
  int reps;
  bool completed;
  bool weightEntered;
  bool repsEntered;

  ActiveSet({
    this.weight = 0,
    this.reps = 0,
    this.completed = false,
    this.weightEntered = false,
    this.repsEntered = false,
  });
}

/// Previous log data for a single set (greyed-out reference)
class PreviousSet {
  final double weight;
  final int reps;

  const PreviousSet({required this.weight, required this.reps});
}

/// Data model for an exercise during an active workout
class ActiveExercise {
  String name;
  final String? muscleGroup;
  List<ActiveSet> sets;
  List<PreviousSet>? previousLog; // greyed-out reference from last session

  ActiveExercise({
    required this.name,
    this.muscleGroup,
    required this.sets,
    this.previousLog,
  });
}

/// Active Workout Screen — shows one exercise at a time with sets grid,
/// navigation, rest timer, and action menus
class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutName;
  final List<ActiveExercise> exercises;

  const ActiveWorkoutScreen({
    super.key,
    required this.workoutName,
    required this.exercises,
  });

  /// Create from a list of exercise maps (preset or saved workouts)
  factory ActiveWorkoutScreen.fromExerciseList({
    required String workoutName,
    required List<Map<String, dynamic>> exercises,
  }) {
    final activeExercises = exercises.map((ex) {
      final sets = (ex['sets'] as int?) ?? 3;
      return ActiveExercise(
        name: (ex['exercise_name'] ?? ex['name'] ?? 'Unknown').toString(),
        muscleGroup: ex['muscleGroup']?.toString(),
        sets: List.generate(sets, (_) => ActiveSet()),
      );
    }).toList();

    return ActiveWorkoutScreen(
      workoutName: workoutName,
      exercises: activeExercises,
    );
  }

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  final DatabaseHelper _db = DatabaseHelper();
  late final DateTime _workoutStartTime;

  // Rest timer state
  int _restTimerSeconds = 60;
  int _remainingSeconds = 0;
  bool _timerRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _loadPreviousLogs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Load previous exercise logs from SQLite for greyed-out reference
  Future<void> _loadPreviousLogs() async {
    for (final exercise in widget.exercises) {
      final logs = await _db.getLastExerciseLog(exercise.name);
      if (logs.isNotEmpty) {
        exercise.previousLog = logs
            .map((log) => PreviousSet(
                  weight: (log['weight'] as num?)?.toDouble() ?? 0,
                  reps: (log['reps'] as int?) ?? 0,
                ))
            .toList();
      }
    }
    if (mounted) setState(() {});
  }

  /// Save all exercise logs to SQLite
  Future<void> _saveAllLogs() async {
    for (final exercise in widget.exercises) {
      final setData = <Map<String, dynamic>>[];
      for (int i = 0; i < exercise.sets.length; i++) {
        setData.add({
          'set_number': i + 1,
          'weight': exercise.sets[i].weight,
          'reps': exercise.sets[i].reps,
        });
      }
      await _db.saveExerciseLog(exercise.name, setData);
    }
  }

  ActiveExercise get currentExercise => widget.exercises[_currentExerciseIndex];
  bool get isFirstExercise => _currentExerciseIndex == 0;
  bool get isLastExercise =>
      _currentExerciseIndex == widget.exercises.length - 1;

  void _goToNextExercise() {
    if (!isLastExercise) {
      setState(() {
        _currentExerciseIndex++;
        _stopTimer();
      });
    }
  }

  void _goToPreviousExercise() {
    if (!isFirstExercise) {
      setState(() {
        _currentExerciseIndex--;
        _stopTimer();
      });
    }
  }

  // ── Rest Timer ──

  void _startRestTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = _restTimerSeconds;
      _timerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _stopTimer();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _adjustTimer(int delta) {
    setState(() {
      _remainingSeconds = (_remainingSeconds + delta).clamp(0, 999);
    });
  }

  void _skipTimer() {
    _stopTimer();
    setState(() => _remainingSeconds = 0);
  }

  String get _timerDisplay {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  // ── Menus ──

  /// Check if both weight and reps are entered for a set, then start timer
  void _checkAndStartTimer(int setIdx) {
    final set = currentExercise.sets[setIdx];
    if (set.weightEntered && set.repsEntered) {
      set.completed = true;
      _startRestTimer();
    }
  }

  /// Show exercise history from DB
  void _showExerciseHistory(String exerciseName) async {
    final logs = await _db.getExerciseHistory(exerciseName);
    if (!mounted) return;

    // Group logs by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final log in logs) {
      final loggedAt = log['logged_at']?.toString() ?? '';
      final dateKey =
          loggedAt.isNotEmpty ? loggedAt.substring(0, 10) : 'Unknown';
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            if (grouped.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history,
                          color: ColossusTheme.primaryColor, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No history for ${exerciseName.toUpperCase()}',
                        style: const TextStyle(
                          color: ColossusTheme.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  exerciseName.toUpperCase(),
                  style: const TextStyle(
                    color: ColossusTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                ...grouped.entries.map((entry) {
                  // Parse and format date
                  String dateLabel;
                  try {
                    final date = DateTime.parse(entry.key);
                    final daysDiff = DateTime.now().difference(date).inDays;
                    final months = [
                      'JAN',
                      'FEB',
                      'MAR',
                      'APR',
                      'MAY',
                      'JUN',
                      'JUL',
                      'AUG',
                      'SEP',
                      'OCT',
                      'NOV',
                      'DEC'
                    ];
                    dateLabel =
                        '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
                    if (daysDiff == 0) {
                      dateLabel += ' (Today)';
                    } else if (daysDiff == 1) {
                      dateLabel += ' (Yesterday)';
                    }
                  } catch (_) {
                    dateLabel = entry.key;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColossusTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map((log) {
                          final setNum = log['set_number'] ?? 0;
                          final weight =
                              (log['weight'] as num?)?.toDouble() ?? 0;
                          final reps = log['reps'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$setNum.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${weight.toStringAsFixed(0)} KG X $reps REPS',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// Show a picker to replace the current exercise
  void _showReplaceExercisePicker() {
    final allExercises = ExerciseLibrary.allExercises;
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'REPLACE EXERCISE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                          color: ColossusTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close,
                            color: ColossusTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: allExercises.length,
                    itemBuilder: (ctx, index) {
                      final exercise = allExercises[index];
                      return ListTile(
                        title: Text(
                          exercise.name,
                          style:
                              const TextStyle(color: ColossusTheme.textPrimary),
                        ),
                        subtitle: Text(
                          exercise.muscleGroup ?? '',
                          style: const TextStyle(
                              color: ColossusTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.swap_horiz,
                            color: ColossusTheme.primaryColor),
                        onTap: () {
                          setState(() {
                            final numSets = currentExercise.sets.length;
                            currentExercise.name = exercise.name;
                            currentExercise.sets =
                                List.generate(numSets, (_) => ActiveSet());
                            currentExercise.previousLog = null;
                          });
                          // Load new previous logs for the replaced exercise
                          _db.getLastExerciseLog(exercise.name).then((logs) {
                            if (logs.isNotEmpty && mounted) {
                              setState(() {
                                currentExercise.previousLog = logs
                                    .map((log) => PreviousSet(
                                          weight: (log['weight'] as num?)
                                                  ?.toDouble() ??
                                              0,
                                          reps: (log['reps'] as int?) ?? 0,
                                        ))
                                    .toList();
                              });
                            }
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExerciseMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuButton('REPLACE THE EXERCISE', () {
                  Navigator.pop(ctx);
                  _showReplaceExercisePicker();
                }),
                const SizedBox(height: 12),
                _buildMenuButton('ADD A SET', () {
                  Navigator.pop(ctx);
                  setState(() {
                    currentExercise.sets.add(ActiveSet());
                  });
                }),
                const SizedBox(height: 12),
                _buildMenuButton('REMOVE A SET', () {
                  Navigator.pop(ctx);
                  if (currentExercise.sets.length > 1) {
                    setState(() {
                      currentExercise.sets.removeLast();
                    });
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWorkoutMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWorkoutMenuTile('Customise Rest Timer', Icons.timer, () {
                  Navigator.pop(ctx);
                  _showRestTimerDialog();
                }),
                _buildWorkoutMenuTile('Edit the Workout', Icons.edit_outlined,
                    () {
                  Navigator.pop(ctx);
                }),
                _buildWorkoutMenuTile(
                    'Complete the Workout', Icons.check_circle_outline, () {
                  Navigator.pop(ctx);
                  _completeWorkout();
                }),
                _buildWorkoutMenuTile('Abandon Workout', Icons.cancel_outlined,
                    () {
                  Navigator.pop(ctx);
                  _abandonWorkout();
                }, color: Colors.redAccent),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abandonWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColossusTheme.surfaceColor,
        title: const Text('Abandon Workout?',
            style: TextStyle(color: ColossusTheme.textPrimary)),
        content: const Text(
            'Are you sure you want to abandon this workout? All progress will be lost.',
            style: TextStyle(color: ColossusTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: ColossusTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('ABANDON',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showRestTimerDialog() {
    int tempSeconds = _restTimerSeconds;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ColossusTheme.surfaceColor,
              title: const Text('Rest Timer',
                  style: TextStyle(color: ColossusTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempSeconds}s',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: ColossusTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setDialogState(() =>
                            tempSeconds = (tempSeconds - 15).clamp(15, 300)),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: ColossusTheme.primaryColor, size: 32),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () => setDialogState(() =>
                            tempSeconds = (tempSeconds + 15).clamp(15, 300)),
                        icon: const Icon(Icons.add_circle_outline,
                            color: ColossusTheme.primaryColor, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL',
                      style: TextStyle(color: ColossusTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _restTimerSeconds = tempSeconds);
                    Navigator.pop(ctx);
                  },
                  child: const Text('SET',
                      style: TextStyle(color: ColossusTheme.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _completeWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColossusTheme.surfaceColor,
        title: const Text('Complete Workout?',
            style: TextStyle(color: ColossusTheme.textPrimary)),
        content: const Text('Are you sure you want to finish this workout?',
            style: TextStyle(color: ColossusTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: ColossusTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              // Save all exercise logs to DB
              await _saveAllLogs();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!context.mounted) return;

              // Calculate summary data
              final duration = DateTime.now().difference(_workoutStartTime);
              final personalBests = _calculatePersonalBests();
              final totalVolume = _calculateTotalVolume();

              // Navigate to summary screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutCompletionScreen(
                    workoutName: widget.workoutName,
                    personalBests: personalBests,
                    totalVolume: totalVolume,
                    duration: duration,
                  ),
                ),
              );
            },
            child: const Text('COMPLETE',
                style: TextStyle(color: ColossusTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  /// Calculate personal best (highest weight set) for each exercise
  List<Map<String, dynamic>> _calculatePersonalBests() {
    final pbs = <Map<String, dynamic>>[];
    for (final exercise in widget.exercises) {
      double bestWeight = 0;
      int bestReps = 0;
      for (final set in exercise.sets) {
        if (set.weightEntered && set.weight > bestWeight) {
          bestWeight = set.weight;
          bestReps = set.reps;
        }
      }
      if (bestWeight > 0) {
        pbs.add({
          'name': exercise.name,
          'weight': bestWeight,
          'reps': bestReps,
        });
      }
    }
    return pbs;
  }

  /// Calculate total volume: sum of (weight × reps) for all completed sets
  double _calculateTotalVolume() {
    double total = 0;
    for (final exercise in widget.exercises) {
      for (final set in exercise.sets) {
        if (set.weightEntered && set.repsEntered) {
          total += set.weight * set.reps;
        }
      }
    }
    return total;
  }

  Widget _buildMenuButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutMenuTile(String label, IconData icon, VoidCallback onTap,
      {Color? color}) {
    final tileColor = color ?? ColossusTheme.primaryColor;
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(label,
          style: TextStyle(color: color ?? ColossusTheme.textPrimary)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = currentExercise;

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.pest_control, color: ColossusTheme.primaryColor),
          onPressed: () =>
              FeedbackHelper.showFeedbackMenu(context, 'Active Workout'),
        ),
        actions: [
          IconButton(
            onPressed: _showWorkoutMenu,
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColossusTheme.primaryColor, width: 2),
              ),
              child: const Icon(Icons.more_horiz,
                  color: ColossusTheme.primaryColor, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Exercise card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: ColossusTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: ColossusTheme.primaryColor, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Exercise name header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: ColossusTheme.primaryColor,
                                    width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    exercise.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: ColossusTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // History button
                                GestureDetector(
                                  onTap: () =>
                                      _showExerciseHistory(exercise.name),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColossusTheme.primaryColor,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Exercise menu button
                                GestureDetector(
                                  onTap: _showExerciseMenu,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColossusTheme.primaryColor,
                                    ),
                                    child: const Icon(Icons.more_horiz,
                                        color: Colors.black, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sets grid
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children:
                                  List.generate(exercise.sets.length, (setIdx) {
                                return _buildSetRow(exercise, setIdx);
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Previous / Next Exercise buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap:
                                isFirstExercise ? null : _goToPreviousExercise,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isFirstExercise
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PREVIOUS EXERCISE',
                                style: TextStyle(
                                  color: isFirstExercise
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: isLastExercise
                                  ? _completeWorkout
                                  : _goToNextExercise,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLastExercise
                                      ? ColossusTheme.primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    isLastExercise
                                        ? 'COMPLETE WORKOUT'
                                        : 'NEXT EXERCISE',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Exercise counter
                    Text(
                      'Exercise ${_currentExerciseIndex + 1} of ${widget.exercises.length}',
                      style: const TextStyle(
                        color: ColossusTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Rest Timer — always pinned at bottom
            _buildRestTimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(ActiveExercise exercise, int setIdx) {
    final set = exercise.sets[setIdx];
    final hasPrevious =
        exercise.previousLog != null && setIdx < exercise.previousLog!.length;
    final prev = hasPrevious ? exercise.previousLog![setIdx] : null;

    // Determine display values — show previous log as greyed placeholder
    final String weightDisplay =
        set.weightEntered ? set.weight.toStringAsFixed(0) : '';
    final String weightHint =
        prev != null ? prev.weight.toStringAsFixed(0) : '-';
    final String repsDisplay = set.repsEntered ? '${set.reps}' : '';
    final String repsHint = prev != null ? '${prev.reps}' : '-';

    final row = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildCircleCell('${setIdx + 1}'),
          const SizedBox(width: 8),
          _buildEditableCircle(
            value: weightDisplay,
            hint: weightHint,
            onTap: () => _editWeight(setIdx),
          ),
          const SizedBox(width: 8),
          _buildCircleCell('KG'),
          const SizedBox(width: 8),
          _buildEditableCircle(
            value: repsDisplay,
            hint: repsHint,
            onTap: () => _editReps(setIdx),
          ),
          const SizedBox(width: 8),
          _buildCircleCell('REPS'),
        ],
      ),
    );

    // If no previous data, return the row as-is (no swipe)
    if (!hasPrevious) return row;

    // Wrap with Dismissible for swipe-right-to-fill
    return Dismissible(
      key: ValueKey('set_${_currentExerciseIndex}_$setIdx'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (prev != null) {
          setState(() {
            set.weight = prev.weight;
            set.weightEntered = true;
            set.reps = prev.reps;
            set.repsEntered = true;
          });
          _checkAndStartTimer(setIdx);
        }
        return false; // Don't dismiss the row
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10BB82),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'FILL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: row,
    );
  }

  Widget _buildCircleCell(String text) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: ColossusTheme.primaryColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableCircle({
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final bool hasValue = value.isNotEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: ColossusTheme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black26, width: 1),
          ),
          child: Center(
            child: Text(
              hasValue ? value : hint,
              style: TextStyle(
                color: hasValue ? Colors.black : Colors.black38,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _editWeight(int setIdx) {
    final controller = TextEditingController(
      text: currentExercise.sets[setIdx].weight > 0
          ? currentExercise.sets[setIdx].weight.toStringAsFixed(0)
          : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColossusTheme.surfaceColor,
        title: Text('Set ${setIdx + 1} — Weight (KG)',
            style: const TextStyle(color: ColossusTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          autofocus: true,
          enableSuggestions: false,
          autocorrect: false,
          style: const TextStyle(color: ColossusTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter weight',
            hintStyle: TextStyle(color: ColossusTheme.textSecondary),
            suffixText: 'KG',
            suffixStyle: TextStyle(color: ColossusTheme.primaryColor),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ColossusTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: ColossusTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                setState(() {
                  currentExercise.sets[setIdx].weight = val;
                  currentExercise.sets[setIdx].weightEntered = true;
                });
                // Auto-start rest timer only after BOTH weight and reps are entered
                _checkAndStartTimer(setIdx);
              }
              Navigator.pop(ctx);
            },
            child: const Text('SET',
                style: TextStyle(color: ColossusTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _editReps(int setIdx) {
    final currentReps = currentExercise.sets[setIdx].repsEntered
        ? currentExercise.sets[setIdx].reps
        : 10;
    int selectedReps = currentReps > 0 ? currentReps : 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL',
                          style: TextStyle(color: ColossusTheme.textSecondary)),
                    ),
                    Text(
                      'Set ${setIdx + 1} — Reps',
                      style: const TextStyle(
                        color: ColossusTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentExercise.sets[setIdx].reps = selectedReps;
                          currentExercise.sets[setIdx].repsEntered = true;
                        });
                        _checkAndStartTimer(setIdx);
                        Navigator.pop(ctx);
                      },
                      child: const Text('SET',
                          style: TextStyle(
                              color: ColossusTheme.primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Scrollable picker
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: (selectedReps - 1).clamp(0, 99),
                  ),
                  itemExtent: 50,
                  diameterRatio: 1.5,
                  backgroundColor: Colors.transparent,
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: ColossusTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  onSelectedItemChanged: (index) {
                    selectedReps = index + 1;
                  },
                  children: List.generate(100, (index) {
                    return Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: ColossusTheme.primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestTimer() {
    final bool showTimer = _timerRunning || _remainingSeconds > 0;
    final double progress =
        _restTimerSeconds > 0 ? _remainingSeconds / _restTimerSeconds : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: ColossusTheme.surfaceColor,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTimer) ...[
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    ColossusTheme.primaryColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              // -15 SEC and +15 SEC (left column)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: showTimer ? () => _adjustTimer(-15) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: showTimer
                            ? ColossusTheme.primaryColor
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '- 15 SEC',
                        style: TextStyle(
                          color:
                              showTimer ? Colors.black : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: showTimer ? () => _adjustTimer(15) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: showTimer
                            ? ColossusTheme.primaryColor
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+ 15 SEC',
                        style: TextStyle(
                          color:
                              showTimer ? Colors.black : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Timer display (center)
              Expanded(
                child: Center(
                  child: Text(
                    showTimer ? _timerDisplay : 'REST TIMER',
                    style: TextStyle(
                      color: showTimer
                          ? ColossusTheme.primaryColor
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: showTimer ? 48 : 14,
                    ),
                  ),
                ),
              ),

              // SKIP (right corner)
              if (showTimer)
                GestureDetector(
                  onTap: _skipTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: ColossusTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Workout Completion Summary Screen
class WorkoutCompletionScreen extends StatelessWidget {
  final String workoutName;
  final List<Map<String, dynamic>> personalBests;
  final double totalVolume;
  final Duration duration;

  const WorkoutCompletionScreen({
    super.key,
    required this.workoutName,
    required this.personalBests,
    required this.totalVolume,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final durationMinutes = duration.inMinutes;
    final volumeStr = totalVolume >= 1000
        ? '${(totalVolume / 1000).toStringAsFixed(1)}K'
        : totalVolume.toStringAsFixed(0);

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Personal Best Records
              if (personalBests.isNotEmpty) ...[
                const Text(
                  'PERSONAL BEST RECORDS',
                  style: TextStyle(
                    color: ColossusTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ...personalBests.map((pb) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${pb['name']} : ${(pb['weight'] as double).toStringAsFixed(0)} KG X ${pb['reps']} REPS',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )),
              ],

              const Spacer(flex: 2),

              // Total Volume
              Center(
                child: Text(
                  'TOTAL VOLUME : $volumeStr KG',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Duration
              Center(
                child: Text(
                  'DURATION : $durationMinutes MINUTES',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Workout name
              Center(
                child: Text(
                  workoutName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ColossusTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // WORKOUT COMPLETED
              const Center(
                child: Text(
                  'WORKOUT\nCOMPLETED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColossusTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 42,
                    height: 1.1,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColossusTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
