import 'dart:convert';
import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/screens/exercise_config_screen.dart';
import 'package:colossus_pt/screens/saved_workout_detail_screen.dart';
import 'package:colossus_pt/theme.dart';
import 'package:colossus_pt/widgets/feedback_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';

/// Unified item for the workout selection grid
class WorkoutItem {
  final String id;
  final String displayName;
  final String type; // 'default', 'customised', 'my_own'
  final WorkoutCategory? category;
  final int exerciseCount;
  final bool isLocked;
  final String lastPerformedText;
  // If from preset
  final Workout? presetWorkout;
  // If from saved/custom
  final Map<String, dynamic>? savedWorkoutData;

  WorkoutItem({
    required this.id,
    required this.displayName,
    required this.type,
    this.category,
    required this.exerciseCount,
    this.isLocked = false,
    this.lastPerformedText = '',
    this.presetWorkout,
    this.savedWorkoutData,
  });
}

/// Screens 2.0 and 2.1: Workout Selection Grid with Filter/Sort and Popup
class WorkoutSelectionScreen extends StatefulWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  String _filterType = 'all'; // 'all', 'default', 'customised', 'my_own'
  String _sortBy =
      'alphabetical'; // 'alphabetical', 'full_body', 'lower_body', 'upper_body'

  List<WorkoutItem> _buildWorkoutList(WorkoutProvider provider) {
    final items = <WorkoutItem>[];

    // Add preset workouts
    for (final workout in provider.presetWorkouts) {
      items.add(WorkoutItem(
        id: workout.id,
        displayName: workout.displayName,
        type: 'default',
        category: workout.category,
        exerciseCount: workout.exercises.length,
        isLocked: workout.isLocked,
        lastPerformedText: workout.lastPerformedText,
        presetWorkout: workout,
      ));
    }

    // Add saved workouts
    for (final saved in provider.savedWorkouts) {
      final exercisesJson = saved['exercises_json'] ?? '[]';
      List exercises = [];
      try {
        exercises = jsonDecode(exercisesJson) as List;
      } catch (_) {}

      final savedType = saved['type'] ?? 'my_own';
      // Only show customised workouts in Colossus Workout tab (not 'my_own')
      if (savedType == 'my_own') continue;

      // Compute "performed X days ago" from created_at
      String performedText = '';
      final createdAt = saved['created_at'];
      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt.toString());
          final days = DateTime.now().difference(date).inDays;
          if (days == 0) {
            performedText = 'Performed today';
          } else if (days == 1) {
            performedText = 'Performed yesterday';
          } else {
            performedText = 'Performed $days days ago';
          }
        } catch (_) {}
      }

      items.add(WorkoutItem(
        id: 'saved_${saved['id']}',
        displayName: saved['name'] ?? 'Custom Workout',
        type: savedType,
        exerciseCount: exercises.length,
        savedWorkoutData: saved,
        lastPerformedText: performedText,
      ));
    }

    return items;
  }

  List<WorkoutItem> _applyFilterAndSort(List<WorkoutItem> items) {
    // Filter
    var filtered = items.where((item) {
      if (_filterType == 'all') return true;
      return item.type == _filterType;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'alphabetical':
        filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case 'full_body':
        filtered.sort((a, b) {
          final aFull = a.category == WorkoutCategory.fullBody ? 0 : 1;
          final bFull = b.category == WorkoutCategory.fullBody ? 0 : 1;
          if (aFull != bFull) return aFull.compareTo(bFull);
          return a.displayName.compareTo(b.displayName);
        });
        break;
      case 'lower_body':
        filtered.sort((a, b) {
          final aLower = a.category == WorkoutCategory.lowerBody ? 0 : 1;
          final bLower = b.category == WorkoutCategory.lowerBody ? 0 : 1;
          if (aLower != bLower) return aLower.compareTo(bLower);
          return a.displayName.compareTo(b.displayName);
        });
        break;
      case 'upper_body':
        filtered.sort((a, b) {
          final aUpper = a.category == WorkoutCategory.upperBody ? 0 : 1;
          final bUpper = b.category == WorkoutCategory.upperBody ? 0 : 1;
          if (aUpper != bUpper) return aUpper.compareTo(bUpper);
          return a.displayName.compareTo(b.displayName);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final allItems = _buildWorkoutList(provider);
    final items = _applyFilterAndSort(allItems);

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
                  FeedbackHelper.showFeedbackMenu(context, 'Colossus Workout'),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        title: const Text(
          'COLOSSUS WORKOUT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
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
                // Filter button
                Expanded(
                  child: GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: ColossusTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.filter_list,
                              color: ColossusTheme.primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'FILTER: ${_filterLabel}',
                            style: const TextStyle(
                              color: ColossusTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Sort By button
                Expanded(
                  child: GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: ColossusTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sort,
                              color: ColossusTheme.primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'SORT: ${_sortLabel}',
                            style: const TextStyle(
                              color: ColossusTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Workout grid
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No workouts found',
                      style: TextStyle(color: ColossusTheme.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildWorkoutCard(items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String get _filterLabel {
    switch (_filterType) {
      case 'all':
        return 'All';
      case 'default':
        return 'Default';
      case 'customised':
        return 'Customised';
      case 'my_own':
        return 'My Own';
      default:
        return 'All';
    }
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'alphabetical':
        return 'A-Z';
      case 'full_body':
        return 'Full Body';
      case 'lower_body':
        return 'Lower Body';
      case 'upper_body':
        return 'Upper Body';
      default:
        return 'Sort';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption('All', 'all'),
                _buildFilterOption('Default', 'default'),
                _buildFilterOption('Customised', 'customised'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isActive = _filterType == value;
    return ListTile(
      onTap: () {
        setState(() => _filterType = value);
        Navigator.pop(context);
      },
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color:
            isActive ? ColossusTheme.primaryColor : ColossusTheme.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color:
              isActive ? ColossusTheme.primaryColor : ColossusTheme.textPrimary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColossusTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SORT BY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption('Alphabetical (A-Z)', 'alphabetical'),
                _buildSortOption('Full Body First', 'full_body'),
                _buildSortOption('Lower Body First', 'lower_body'),
                _buildSortOption('Upper Body First', 'upper_body'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isActive = _sortBy == value;
    return ListTile(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color:
            isActive ? ColossusTheme.primaryColor : ColossusTheme.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color:
              isActive ? ColossusTheme.primaryColor : ColossusTheme.textPrimary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutItem item) {
    final isLocked = item.isLocked;
    final isCustom = item.type != 'default';

    Color cardColor;
    if (isLocked) {
      cardColor = const Color(0xFF4A3728);
    } else if (item.type == 'customised') {
      cardColor = const Color(0xFF0097B2); // teal-blue for customised
    } else if (item.type == 'my_own') {
      cardColor = const Color(0xFF10BB82); // green for my own
    } else {
      cardColor = ColossusTheme.primaryColor.withValues(alpha: 0.9);
    }

    return GestureDetector(
      onTap: isLocked ? null : () => _showWorkoutPopup(item),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  if (isCustom)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type == 'customised' ? 'CUSTOM' : 'MY OWN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (!isCustom && item.category != null)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        item.category!.icon,
                        color: isLocked ? Colors.white38 : Colors.black87,
                        size: 18,
                      ),
                    ),

                  const Spacer(),

                  // Workout name
                  if (!isCustom && item.category != null)
                    Text(
                      item.category!.displayName,
                      style: TextStyle(
                        color: isLocked ? Colors.white38 : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    item.displayName,
                    style: TextStyle(
                      color: isLocked ? Colors.white54 : Colors.black,
                      fontSize: isCustom ? 13 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (!isLocked)
                    Text(
                      '${item.exerciseCount} exercises',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),

                  if (!isLocked && item.lastPerformedText.isNotEmpty)
                    Text(
                      item.lastPerformedText,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
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
                child: Icon(Icons.lock, color: Colors.white38, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showWorkoutPopup(WorkoutItem item) {
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
                  item.displayName,
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
                      '${item.exerciseCount} exercises',
                      style: const TextStyle(
                          color: ColossusTheme.textSecondary, fontSize: 14),
                    ),
                    if (item.type != 'default') ...[
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
                          item.type == 'customised' ? 'CUSTOMISED' : 'MY OWN',
                          style: const TextStyle(
                            color: ColossusTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // START WORKOUT button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);

                      // Build exercise list for the detail screen
                      List<Map<String, dynamic>> exerciseList = [];
                      String workoutName = item.displayName;

                      if (item.presetWorkout != null) {
                        final provider = context.read<WorkoutProvider>();
                        provider.recordWorkoutPerformed(item.presetWorkout!.id);
                        exerciseList = item.presetWorkout!.exercises
                            .map((e) => {
                                  'exercise_name': e.exercise.name,
                                  'sets': e.sets,
                                  'reps': e.reps,
                                  'muscleGroup': e.exercise.muscleGroup,
                                })
                            .toList();
                      } else if (item.savedWorkoutData != null) {
                        workoutName =
                            (item.savedWorkoutData!['name'] ?? 'Custom Workout')
                                .toString();
                        try {
                          final json =
                              item.savedWorkoutData!['exercises_json'] ?? '[]';
                          final parsed = jsonDecode(json) as List<dynamic>;
                          exerciseList = parsed.cast<Map<String, dynamic>>();
                        } catch (_) {}
                      }

                      // Navigate to exercise list screen with BEGIN WORKOUT
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedWorkoutDetailScreen(
                            workout: item.savedWorkoutData ??
                                {
                                  'name': workoutName,
                                  'exercises_json': jsonEncode(exerciseList),
                                },
                          ),
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
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // EDIT WORKOUT button (for all workout types)
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      final provider = context.read<WorkoutProvider>();

                      if (item.presetWorkout != null) {
                        provider
                            .loadPresetWorkoutForEditing(item.presetWorkout!);
                      } else if (item.savedWorkoutData != null) {
                        // Load saved workout exercises for editing
                        try {
                          final json =
                              item.savedWorkoutData!['exercises_json'] ?? '[]';
                          final parsed = jsonDecode(json) as List<dynamic>;
                          final savedId = item.savedWorkoutData!['id'] as int?;
                          final savedName =
                              (item.savedWorkoutData!['name'] ?? '').toString();
                          final savedType =
                              (item.savedWorkoutData!['type'] ?? 'my_own')
                                  .toString();
                          provider.loadSavedWorkoutForEditing(
                            parsed.cast<Map<String, dynamic>>(),
                            savedWorkoutId: savedId,
                            savedWorkoutName: savedName,
                            savedWorkoutType: savedType,
                          );
                        } catch (_) {}
                      }

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
