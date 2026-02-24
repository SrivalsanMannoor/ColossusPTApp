import 'package:colossus_pt/providers/workout_provider.dart';
import 'package:colossus_pt/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen 4: Exercise Configuration for custom workout
class ExerciseConfigScreen extends StatefulWidget {
  const ExerciseConfigScreen({super.key});

  @override
  State<ExerciseConfigScreen> createState() => _ExerciseConfigScreenState();
}

class _ExerciseConfigScreenState extends State<ExerciseConfigScreen> {
  // When non-null, user is selecting a superset partner for this index
  int? _supersetSelectingFor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = provider.customExercises;

    return Scaffold(
      backgroundColor: ColossusTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          provider.editingWorkoutId != null
              ? 'EDIT WORKOUT'
              : 'CONFIGURE WORKOUT',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColossusTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColossusTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _supersetSelectingFor != null
                        ? 'TAP ANOTHER EXERCISE TO PAIR AS SUPERSET'
                        : 'TAP AND HOLD TO REORDER · TAP ⚡ TO CREATE SUPERSET',
                    style: const TextStyle(
                      color: ColossusTheme.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_supersetSelectingFor != null)
                  GestureDetector(
                    onTap: () => setState(() => _supersetSelectingFor = null),
                    child: const Icon(
                      Icons.close,
                      color: ColossusTheme.textSecondary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: exercises.isEmpty
                ? const Center(
                    child: Text(
                      'No exercises added',
                      style: TextStyle(color: ColossusTheme.textSecondary),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderExercise(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final workoutExercise = exercises[index];
                      final isInSuperset = provider.isInSuperset(index);
                      final partner = provider.getSupersetPartner(index);

                      return _buildExerciseConfigItem(
                        key: ValueKey(
                            workoutExercise.exercise.id + index.toString()),
                        context: context,
                        index: index,
                        name: workoutExercise.exercise.name,
                        sets: workoutExercise.sets,
                        reps: workoutExercise.reps,
                        provider: provider,
                        isInSuperset: isInSuperset,
                        partnerIndex: partner,
                        isSelectingSuperset: _supersetSelectingFor != null,
                        isSelectedForSuperset: _supersetSelectingFor == index,
                      );
                    },
                  ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ColossusTheme.surfaceColor,
            ),
            child: Row(
              children: [
                // Easy button
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
                          'EASY',
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

                // Save button
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final provider = context.read<WorkoutProvider>();
                      if (provider.editingWorkoutId != null) {
                        // Editing an existing preset workout — update in-memory
                        provider.updatePresetWorkoutExercises(
                          provider.editingWorkoutId!,
                          provider.customExercises,
                        );
                        provider.clearEditingState();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Workout updated!'),
                            backgroundColor: ColossusTheme.primaryColor,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        // New custom workout — prompt for name, then save
                        final name = await _showNameDialog(context);
                        if (name == null) return; // user cancelled
                        if (!context.mounted) return;
                        final saved =
                            await provider.saveCustomWorkoutToDB(name: name);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(saved
                                ? 'Workout saved!'
                                : 'No exercises to save'),
                            backgroundColor: ColossusTheme.primaryColor,
                          ),
                        );
                        if (saved) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: ColossusTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.black,
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

  Future<String?> _showNameDialog(BuildContext context) {
    final controller = TextEditingController(text: 'Custom Workout');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColossusTheme.surfaceColor,
        title: const Text('Name Your Workout',
            style: TextStyle(color: ColossusTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: ColossusTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Upper Body Day',
            hintStyle: const TextStyle(color: ColossusTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
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
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isEmpty ? 'Custom Workout' : text);
            },
            child: const Text('SAVE',
                style: TextStyle(color: ColossusTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseConfigItem({
    required Key key,
    required BuildContext context,
    required int index,
    required String name,
    required int sets,
    required int reps,
    required WorkoutProvider provider,
    required bool isInSuperset,
    int? partnerIndex,
    required bool isSelectingSuperset,
    required bool isSelectedForSuperset,
  }) {
    // Determine border color based on superset state
    Color borderColor = Colors.transparent;
    if (isSelectedForSuperset) {
      borderColor = Colors.orangeAccent;
    } else if (isInSuperset) {
      borderColor = ColossusTheme.primaryColor;
    } else if (isSelectingSuperset && _supersetSelectingFor != index) {
      borderColor = Colors.white24; // eligible for selection
    }

    return GestureDetector(
      key: key,
      onTap: isSelectingSuperset
          ? () {
              if (_supersetSelectingFor != null &&
                  _supersetSelectingFor != index) {
                provider.toggleSuperset(_supersetSelectingFor!, index);
                setState(() => _supersetSelectingFor = null);
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ColossusTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isInSuperset || isSelectedForSuperset ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isInSuperset
                    ? Colors.orangeAccent
                    : ColossusTheme.primaryColor,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Exercise name + superset label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: ColossusTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isInSuperset && partnerIndex != null)
                    Text(
                      '⚡ Superset with #${partnerIndex + 1}',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Superset button
            if (!isSelectingSuperset)
              GestureDetector(
                onTap: () {
                  if (isInSuperset) {
                    // Remove from superset
                    provider.toggleSuperset(index, partnerIndex!);
                  } else {
                    // Start selection mode
                    setState(() => _supersetSelectingFor = index);
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: isInSuperset
                        ? Colors.orangeAccent.withValues(alpha: 0.2)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.bolt,
                    color: isInSuperset
                        ? Colors.orangeAccent
                        : ColossusTheme.textSecondary,
                    size: 16,
                  ),
                ),
              ),

            // Sets control
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: sets > 1
                      ? () =>
                          provider.updateCustomExercise(index, sets: sets - 1)
                      : null,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: sets > 1
                          ? ColossusTheme.primaryColor
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        const Icon(Icons.remove, color: Colors.black, size: 16),
                  ),
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$sets',
                    style: const TextStyle(
                      color: ColossusTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      provider.updateCustomExercise(index, sets: sets + 1),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ColossusTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_handle,
                color: ColossusTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
