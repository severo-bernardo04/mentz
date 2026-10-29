import 'package:flutter/material.dart';
import 'package:mentz/features/training/widgets/editable_exercise_tile.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/section_card.dart';

/// Lista reordenável de exercícios da ficha.
class ExercisesSection extends StatelessWidget {
  final List<Exercise> exercises;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  /// `newIndex` já vem ajustado para a remoção do item em `oldIndex`.
  final ReorderCallback onReorder;

  const ExercisesSection({
    super.key,
    required this.exercises,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Exercícios',
      icon: Icons.fitness_center,
      trailing: FilledButton.tonalIcon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Adicionar'),
      ),
      child: exercises.isEmpty
          ? const EmptyHint('Nenhum exercício ainda.')
          : ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: onReorder,
              children: [
                for (var i = 0; i < exercises.length; i++)
                  EditableExerciseTile(
                    key: ObjectKey(exercises[i]),
                    index: i,
                    exercise: exercises[i],
                    onEdit: () => onEdit(i),
                    onDelete: () => onDelete(i),
                  ),
              ],
            ),
    );
  }
}