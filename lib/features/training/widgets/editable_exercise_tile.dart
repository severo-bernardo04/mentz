import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Exercício na lista do editor: arrastar, editar (toque) e remover.
class EditableExerciseTile extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EditableExerciseTile({
    super.key,
    required this.index,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.drag_indicator),
          ),
        ),
        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${e.sets} × ${e.reps}  •  ${e.load}  •  descanso ${e.restLabel}',
        ),
        trailing: IconButton(
          tooltip: 'Remover',
          icon: Icon(Icons.delete_outline, color: cs.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}