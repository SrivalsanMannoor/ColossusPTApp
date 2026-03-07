import 'dart:convert';
import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/exercise_config_screen.dart';
import 'package:colossus_pt/screens/exercise_library_screen.dart';
import 'package:colossus_pt/screens/saved_workout_detail_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:colossus_pt/widgets/feedback_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// My Workouts screen: shows all saved custom/customized workouts from SQLite
class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final savedWorkouts = provider.savedWorkouts
        .where((w) => (w['type'] ?? 'my_own') == 'my_own')
        .toList();

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.pest_control,
                  color: ColossusTheme.primaryColor),
              onPressed: () =>
                  FeedbackHelper.showFeedbackMenu(context, 'My Workouts'),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ],
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
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
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
    final workoutType = workout['type'] ?? 'my_own';
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

    // Color based on type
    final cardColor = workoutType == 'customised'
        ? const Color(0xFF0097B2)
        : const Color(0xFF10BB82);

    return GestureDetector(
      onTap: () => _showWorkoutPopup(context, workout),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  workoutType == 'customised' ? 'CUSTOM' : 'MY OWN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${exercises.length} exercises',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
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

  void _showWorkoutPopup(BuildContext context, Map<String, dynamic> workout) {
    final name = workout['name'] ?? 'Custom Workout';
    final exercisesJson = workout['exercises_json'] ?? '[]';
    List exercises = [];
    try {
      exercises = jsonDecode(exercisesJson) as List;
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Workout name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center,
                        size: 16, color: ColossusTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${exercises.length} exercises',
                      style: const TextStyle(
                          color: ColossusTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            ColossusTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (workout['type'] ?? 'my_own') == 'customised'
                            ? 'CUSTOMISED'
                            : 'MY OWN',
                        style: const TextStyle(
                          color: ColossusTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // START WORKOUT button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SavedWorkoutDetailScreen(workout: workout),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: ColossusTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'START WORKOUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // EDIT WORKOUT button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      final provider = context.read<WorkoutProvider>();
                      try {
                        final parsed =
                            jsonDecode(exercisesJson) as List<dynamic>;
                        final savedId = workout['id'] as int?;
                        final savedName = (workout['name'] ?? '').toString();
                        final savedType =
                            (workout['type'] ?? 'my_own').toString();
                        provider.loadSavedWorkoutForEditing(
                          parsed.cast<Map<String, dynamic>>(),
                          savedWorkoutId: savedId,
                          savedWorkoutName: savedName,
                          savedWorkoutType: savedType,
                        );
                      } catch (_) {}
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExerciseConfigScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(
                        child: Text(
                          'EDIT WORKOUT',
                          style: TextStyle(
                            color: ColossusTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
