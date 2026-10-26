import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Exercício da ficha, com checkbox para marcar como feito.
class ExerciseTile extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const ExerciseTile({
    super.key,
    required this.index,
    required this.exercise,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final e = exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: checked
            ? cs.primaryContainer.withAlpha(120)
            : cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: cs.primary,
            child: Text(
              '$index',
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (e.muscle.isNotEmpty)
                  Text(
                    e.muscle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(label: '${e.sets} × ${e.reps}'),
                    StatusChip(label: e.load, icon: Icons.scale_outlined),
                    StatusChip(label: e.restLabel, icon: Icons.timer_outlined),
                  ],
                ),
              ],
            ),
          ),
          Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
        ],
      ),
    );
  }
}