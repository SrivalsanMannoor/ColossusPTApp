import 'package:colossus_pt/screens/exercise_library_screen.dart';
import 'package:colossus_pt/screens/my_workouts_screen.dart';
import 'package:colossus_pt/screens/workout_selection_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:colossus_pt/widgets/feedback_helper.dart';
import 'package:flutter/material.dart';

/// Screen 1: Workout Home with Choose/Build/My Workouts options
class WorkoutHomeScreen extends StatelessWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.pest_control, color: ColossusTheme.primaryColor),
          onPressed: () =>
              FeedbackHelper.showFeedbackMenu(context, 'Workout Home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),

            // App Logo/Title Area
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ColossusTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: ColossusTheme.primaryColor,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Choose a Workout Button
            _buildPrimaryButton(
              context,
              'COLOSSUS\nWORKOUT',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutSelectionScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // My Workouts Button
            _buildSecondaryButton(
              context,
              'MY\nWORKOUTS',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyWorkoutsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Build My Own Workout Button
            _buildSecondaryButton(
              context,
              'BUILD\nMY OWN WORKOUT',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseLibraryScreen(),
                  ),
                );
              },
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: ColossusTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, String text,
      {required VoidCallback onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: ColossusTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: ColossusTheme.primaryColor, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColossusTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
