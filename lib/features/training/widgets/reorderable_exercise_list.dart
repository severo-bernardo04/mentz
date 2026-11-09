import 'package:flutter/material.dart';
import 'package:mentz/features/training/widgets/editable_exercise_tile.dart';
import 'package:mentz/models/profile_models.dart';

/// Lista reordenável dos exercícios de um treino: arrastar, editar e remover.
/// Usada dentro de telas roláveis, por isso não tem rolagem própria.
class ReorderableExerciseList extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  /// `newIndex` já vem ajustado para a remoção do item em `oldIndex`.
  final ReorderCallback onReorder;

  const ReorderableExerciseList({
    super.key,
    required this.exercises,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
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
    );
  }
}
