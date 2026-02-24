import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/exercise_config_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';

/// Screen 3: Exercise Library with filter, sort, and selection
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _sortBy = 'name';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = _getSortedExercises(provider.filteredExercises);
    final totalSelected = provider.totalSelectedExercises;

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
          'EXERCISE LIBRARY',
          style: TextStyle(
            color: ColossusTheme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter and Sort buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterButton('FILTER',
                    onTap: () => _showFilterDialog(context)),
                const SizedBox(width: 12),
                _buildFilterButton('SORT BY',
                    onTap: () => _showSortDialog(context)),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return _buildExerciseItem(context, exercises[index], provider);
              },
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ColossusTheme.surfaceColor,
              border: Border(
                top: BorderSide(color: Colors.white12),
              ),
            ),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: ColossusTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.black, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'BACK',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Add workouts button
                Expanded(
                  child: GestureDetector(
                    onTap: totalSelected > 0
                        ? () {
                            provider.buildCustomWorkout();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ExerciseConfigScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: totalSelected > 0
                            ? ColossusTheme.primaryColor
                            : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'ADD $totalSelected WORKOUT${totalSelected == 1 ? '' : 'S'}',
                          style: TextStyle(
                            color: totalSelected > 0
                                ? Colors.black
                                : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Exercise> _getSortedExercises(List<Exercise> exercises) {
    final sorted = List<Exercise>.from(exercises);
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'muscle':
        sorted.sort(
            (a, b) => (a.muscleGroup ?? '').compareTo(b.muscleGroup ?? ''));
        break;
    }
    return sorted;
  }

  Widget _buildFilterButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ColossusTheme.surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: ColossusTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(
      BuildContext context, Exercise exercise, WorkoutProvider provider) {
    final count = provider.getExerciseCount(exercise.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColossusTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: count > 0
            ? Border.all(color: ColossusTheme.primaryColor, width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: ColossusTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (exercise.muscleGroup != null)
                  Text(
                    exercise.muscleGroup!,
                    style: const TextStyle(
                      color: ColossusTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Counter controls
          Row(
            children: [
              // Decrement
              GestureDetector(
                onTap: count > 0
                    ? () => provider.decrementExercise(exercise.id)
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: count > 0
                        ? ColossusTheme.primaryColor
                        : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: count > 0 ? Colors.black : Colors.white38,
                    size: 18,
                  ),
                ),
              ),

              // Count
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: ColossusTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // Increment
              GestureDetector(
                onTap: () => provider.incrementExercise(exercise.id),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ColossusTheme.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    final filters = ['Upper Body', 'Lower Body', 'Push', 'Pull'];

    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All Exercises',
                style: TextStyle(color: ColossusTheme.textPrimary)),
            trailing: provider.activeFilter == null
                ? const Icon(Icons.check, color: ColossusTheme.primaryColor)
                : null,
            onTap: () {
              provider.setActiveFilter(null);
              Navigator.pop(context);
            },
          ),
          ...filters.map((filter) => ListTile(
                title: Text(filter,
                    style: const TextStyle(color: ColossusTheme.textPrimary)),
                trailing: provider.activeFilter == filter
                    ? const Icon(Icons.check, color: ColossusTheme.primaryColor)
                    : null,
                onTap: () {
                  provider.setActiveFilter(filter);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Sort by Name',
                style: TextStyle(color: ColossusTheme.textPrimary)),
            trailing: _sortBy == 'name'
                ? const Icon(Icons.check, color: ColossusTheme.primaryColor)
                : null,
            onTap: () {
              setState(() => _sortBy = 'name');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Sort by Muscle Group',
                style: TextStyle(color: ColossusTheme.textPrimary)),
            trailing: _sortBy == 'muscle'
                ? const Icon(Icons.check, color: ColossusTheme.primaryColor)
                : null,
            onTap: () {
              setState(() => _sortBy = 'muscle');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
