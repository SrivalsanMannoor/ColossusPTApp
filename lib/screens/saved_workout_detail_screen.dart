import 'dart:convert';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';

/// Screen to show exercises from a saved custom workout
class SavedWorkoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> workout;

  const SavedWorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final name = workout['name'] ?? 'Custom Workout';
    final exercisesJson = workout['exercises_json'] ?? '[]';
    List<dynamic> exercises = [];
    try {
      exercises = jsonDecode(exercisesJson) as List<dynamic>;
    } catch (_) {}

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          name.toString().toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: exercises.isEmpty
          ? const Center(
              child: Text(
                'No exercises in this workout.',
                style: TextStyle(color: ColossusTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                // Header summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColossusTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('${exercises.length}', 'Exercises',
                          Icons.fitness_center),
                      _buildStat(
                        '${_totalSets(exercises)}',
                        'Total Sets',
                        Icons.repeat,
                      ),
                    ],
                  ),
                ),

                // Exercise list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final ex = exercises[index] as Map<String, dynamic>;
                      return _buildExerciseCard(ex, index + 1);
                    },
                  ),
                ),

                // Start button at bottom
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Workout started! 💪'),
                              backgroundColor: ColossusTheme.primaryColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text(
                          'BEGIN WORKOUT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ColossusTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: ColossusTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex, int number) {
    final name = ex['exercise_name'] ?? 'Unknown';
    final sets = ex['sets'] ?? 0;
    final reps = ex['reps'] ?? 0;
    final supersetGroup = ex['superset_group'];
    final isSuperset = supersetGroup != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColossusTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuperset ? Colors.orangeAccent : Colors.white10,
          width: isSuperset ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Exercise number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSuperset
                  ? Colors.orangeAccent.withValues(alpha: 0.2)
                  : ColossusTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isSuperset
                  ? const Icon(Icons.bolt, color: Colors.orangeAccent, size: 20)
                  : Text(
                      '$number',
                      style: const TextStyle(
                        color: ColossusTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$sets sets × $reps reps',
                      style: const TextStyle(
                        color: ColossusTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (isSuperset) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⚡ SUPERSET',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _totalSets(List<dynamic> exercises) {
    int total = 0;
    for (final ex in exercises) {
      if (ex is Map<String, dynamic>) {
        total += (ex['sets'] as int?) ?? 0;
      }
    }
    return total;
  }
}
