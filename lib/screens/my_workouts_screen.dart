import 'dart:convert';
import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/exercise_library_screen.dart';
import 'package:colossus_pt/screens/saved_workout_detail_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// My Workouts screen: shows all saved custom/customized workouts from SQLite
class MyWorkoutsScreen extends StatelessWidget {
  const MyWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final savedWorkouts = provider.savedWorkouts;

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY WORKOUTS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          // NEW button in app bar
          GestureDetector(
            onTap: () => _navigateToBuild(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColossusTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.black, size: 16),
                  SizedBox(width: 2),
                  Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: savedWorkouts.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedWorkouts.length,
              itemBuilder: (context, index) {
                return _buildWorkoutCard(context, savedWorkouts[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center,
                size: 64, color: ColossusTheme.primaryColor),
            const SizedBox(height: 24),
            const Text(
              'No Saved Workouts Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Build a custom workout or customize a preset — your saved workouts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColossusTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _navigateToBuild(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: ColossusTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BUILD A WORKOUT',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    final name = workout['name'] ?? 'Custom Workout';
    final exercisesJson = workout['exercises_json'] ?? '[]';
    final createdAt = workout['created_at'] ?? '';
    List exercises = [];
    try {
      exercises = jsonDecode(exercisesJson) as List;
    } catch (_) {}

    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateLabel = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavedWorkoutDetailScreen(workout: workout),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColossusTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ColossusTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center,
                  color: ColossusTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${exercises.length} exercises',
                        style: const TextStyle(
                          color: ColossusTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (dateLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· $dateLabel',
                          style: const TextStyle(
                            color: ColossusTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: ColossusTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _navigateToBuild(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseLibraryScreen(),
      ),
    );
  }
}
