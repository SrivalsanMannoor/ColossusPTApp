import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/exercise_config_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';

/// Screens 2.0 and 2.1: Workout Selection Grid with Detail
class WorkoutSelectionScreen extends StatefulWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  Workout? _selectedWorkout;
  bool _isPreparing = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final workouts = provider.presetWorkouts;

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Preparing indicator and Start button (when workout selected)
          if (_selectedWorkout != null)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildPreparingSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Workout grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final workout = workouts[index];
                  return _buildWorkoutCard(workout);
                },
                childCount: workouts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Preparing indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: ColossusTheme.primaryColor, width: 2),
                ),
                child: _isPreparing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              ColossusTheme.primaryColor),
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        color: ColossusTheme.primaryColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREPARING',
                    style: TextStyle(
                      color: ColossusTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '#${_selectedWorkout!.number}',
                    style: const TextStyle(
                      color: ColossusTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Load the preset workout for editing
                  final provider = context.read<WorkoutProvider>();
                  provider.loadPresetWorkoutForEditing(_selectedWorkout!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExerciseConfigScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.tune,
                  color: ColossusTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Start button
          GestureDetector(
            onTap: () async {
              // Record workout as performed in SQLite
              final provider = context.read<WorkoutProvider>();
              await provider.recordWorkoutPerformed(_selectedWorkout!.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Starting ${_selectedWorkout!.displayName}...'),
                  backgroundColor: ColossusTheme.primaryColor,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: ColossusTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'START',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected workout name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: ColossusTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _selectedWorkout!.displayName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final isSelected = _selectedWorkout?.id == workout.id;
    final isLocked = workout.isLocked;

    Color cardColor;
    if (isLocked) {
      cardColor = const Color(0xFF4A3728); // Brown for locked
    } else if (isSelected) {
      cardColor = ColossusTheme.primaryColor;
    } else {
      cardColor = ColossusTheme.primaryColor.withOpacity(0.9);
    }

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              setState(() {
                _selectedWorkout = workout;
                _isPreparing = true;
              });
              // Simulate preparation
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  setState(() {
                    _isPreparing = false;
                  });
                }
              });
            },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      workout.category.icon,
                      color: isLocked ? Colors.white38 : Colors.black87,
                      size: 18,
                    ),
                  ),

                  const Spacer(),

                  // Workout name
                  Text(
                    workout.category.displayName,
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '#${workout.number}',
                    style: TextStyle(
                      color: isLocked ? Colors.white54 : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Exercise count
                  if (!isLocked)
                    Text(
                      '${workout.exercises.length} exercises',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),

                  // Last performed text
                  if (!isLocked)
                    Text(
                      workout.lastPerformedText,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            // Lock overlay
            if (isLocked)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.lock,
                  color: Colors.white38,
                  size: 16,
                ),
              ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
