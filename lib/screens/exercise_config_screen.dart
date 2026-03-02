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

  /// Build a list of groups from exercises.
  /// Each group is a list of exercise indices. Superset pairs form one group.
  List<List<int>> _buildGroups(WorkoutProvider provider) {
    final exercises = provider.customExercises;
    final visited = <int>{};
    final groups = <List<int>>[];

    for (int i = 0; i < exercises.length; i++) {
      if (visited.contains(i)) continue;
      final partner = provider.getSupersetPartner(i);
      if (partner != null && partner == i + 1 && !visited.contains(partner)) {
        // Superset pair (adjacent)
        groups.add([i, partner]);
        visited.add(i);
        visited.add(partner);
      } else {
        groups.add([i]);
        visited.add(i);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = provider.customExercises;
    final groups = _buildGroups(provider);

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

          // Exercise list (grouped)
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
                    itemCount: groups.length,
                    onReorder: (oldGroupIdx, newGroupIdx) {
                      _onGroupReorder(
                          provider, groups, oldGroupIdx, newGroupIdx);
                    },
                    itemBuilder: (context, groupIdx) {
                      final group = groups[groupIdx];
                      if (group.length == 2) {
                        // Superset pair — render as one combined widget
                        return _buildSupersetGroup(
                          key: ValueKey('group_${group[0]}_${group[1]}'),
                          context: context,
                          groupIndex: groupIdx,
                          indices: group,
                          provider: provider,
                        );
                      } else {
                        // Single exercise
                        final index = group[0];
                        final workoutExercise = exercises[index];
                        return _buildExerciseConfigItem(
                          key: ValueKey(
                              workoutExercise.exercise.id + index.toString()),
                          context: context,
                          groupIndex: groupIdx,
                          index: index,
                          name: workoutExercise.exercise.name,
                          sets: workoutExercise.sets,
                          reps: workoutExercise.reps,
                          provider: provider,
                          isInSuperset: false,
                          partnerIndex: null,
                          isSelectingSuperset: _supersetSelectingFor != null,
                          isSelectedForSuperset: _supersetSelectingFor == index,
                        );
                      }
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

                // Save button
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final provider = context.read<WorkoutProvider>();
                      // Always prompt for a name
                      final name = await _showNameDialog(context);
                      if (name == null) return;
                      if (!context.mounted) return;
                      // Determine workout type
                      final isEditing = provider.editingWorkoutId != null;
                      final type = isEditing ? 'customised' : 'my_own';

                      // Save to SQLite DB
                      final saved = await provider.saveCustomWorkoutToDB(
                        name: name,
                        type: type,
                      );
                      if (!context.mounted) return;

                      if (isEditing) {
                        provider.clearEditingState();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(saved
                              ? 'Workout "$name" saved!'
                              : 'No exercises to save'),
                          backgroundColor: ColossusTheme.primaryColor,
                        ),
                      );
                      if (saved) {
                        Navigator.popUntil(context, (route) => route.isFirst);
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

  /// Handle reorder at the group level
  void _onGroupReorder(WorkoutProvider provider, List<List<int>> groups,
      int oldIdx, int newIdx) {
    if (oldIdx < newIdx) newIdx -= 1;
    if (oldIdx == newIdx) return;

    // Build the new ordered list of exercise indices
    final reorderedGroups = List<List<int>>.from(groups);
    final movedGroup = reorderedGroups.removeAt(oldIdx);
    reorderedGroups.insert(newIdx, movedGroup);

    // Flatten to get the new exercise order
    final newOrder = <int>[];
    for (final g in reorderedGroups) {
      newOrder.addAll(g);
    }

    // Apply the new order to the provider
    provider.reorderByNewOrder(newOrder);
  }

  Future<String?> _showNameDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final text = controller.text.trim();
            final isValid = text.isNotEmpty;

            return AlertDialog(
              backgroundColor: ColossusTheme.surfaceColor,
              title: const Text('Name Your Workout',
                  style: TextStyle(color: ColossusTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: ColossusTheme.textPrimary),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Upper Body Day',
                      hintStyle: TextStyle(color: ColossusTheme.textSecondary),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: ColossusTheme.primaryColor),
                      ),
                    ),
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
                  onPressed: isValid ? () => Navigator.pop(ctx, text) : null,
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      color: isValid
                          ? ColossusTheme.primaryColor
                          : ColossusTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Render a superset pair as a single combined widget
  Widget _buildSupersetGroup({
    required Key key,
    required BuildContext context,
    required int groupIndex,
    required List<int> indices,
    required WorkoutProvider provider,
  }) {
    final exercises = provider.customExercises;
    final ex1 = exercises[indices[0]];
    final ex2 = exercises[indices[1]];

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ColossusTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Superset header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0x33FFC107),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.orangeAccent, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'SUPERSET',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                // Remove superset
                GestureDetector(
                  onTap: () {
                    provider.toggleSuperset(indices[0], indices[1]);
                  },
                  child: const Icon(Icons.close,
                      color: Colors.orangeAccent, size: 16),
                ),
                const SizedBox(width: 8),
                // Drag handle
                ReorderableDragStartListener(
                  index: groupIndex,
                  child: const Icon(Icons.drag_handle,
                      color: ColossusTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Exercise 1
          _buildInlineExercise(
            index: indices[0],
            name: ex1.exercise.name,
            sets: ex1.sets,
            provider: provider,
          ),
          const Divider(height: 1, color: Colors.white12),
          // Exercise 2
          _buildInlineExercise(
            index: indices[1],
            name: ex2.exercise.name,
            sets: ex2.sets,
            provider: provider,
          ),
        ],
      ),
    );
  }

  /// Mini exercise row inside a superset group
  Widget _buildInlineExercise({
    required int index,
    required String name,
    required int sets,
    required WorkoutProvider provider,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orangeAccent,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: ColossusTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Sets control
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: sets > 1
                    ? () => provider.updateCustomExercise(index, sets: sets - 1)
                    : null,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: sets > 1
                        ? ColossusTheme.primaryColor
                        : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      const Icon(Icons.remove, color: Colors.black, size: 14),
                ),
              ),
              Container(
                width: 28,
                alignment: Alignment.center,
                child: Text(
                  '$sets',
                  style: const TextStyle(
                    color: ColossusTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    provider.updateCustomExercise(index, sets: sets + 1),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: ColossusTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseConfigItem({
    required Key key,
    required BuildContext context,
    required int groupIndex,
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
            width: isSelectedForSuperset ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ColossusTheme.primaryColor,
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

            // Exercise name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: ColossusTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Superset button
            if (!isSelectingSuperset)
              GestureDetector(
                onTap: () {
                  setState(() => _supersetSelectingFor = index);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: ColossusTheme.textSecondary,
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
              index: groupIndex,
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
