import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import '../../../widgets/status_chip.dart';

/// Card para exibir os detalhes dos exercícios e séries efetivamente registrados na sessão.
class ExecutedExerciseCard extends StatelessWidget {
  final int index;
  final ExecutedExercise exercise;

  const ExecutedExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
  });

  Color _typeColor(SetType type, ColorScheme cs) {
    return switch (type) {
      SetType.warmup => Colors.blueGrey,
      SetType.working => cs.primary,
      SetType.failure => Colors.deepOrange,
      SetType.dropSet => Colors.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
        border: exercise.completed
            ? null
            : Border.all(color: Colors.orange.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: exercise.completed
                    ? cs.primaryContainer
                    : Colors.orange.withAlpha(40),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: exercise.completed
                        ? cs.onPrimaryContainer
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (exercise.muscle.isNotEmpty)
                      Text(
                        exercise.muscle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              StatusChip(
                label: exercise.completed ? 'Concluído' : 'Não concluído',
                icon: exercise.completed
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: exercise.completed
                    ? const Color(0xFF2E7D32)
                    : Colors.deepOrange,
              ),
            ],
          ),
          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exercise.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (exercise.sets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 44,
                          child: Text(
                            'Série',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Tipo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Carga',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 60,
                          child: Text(
                            'Reps',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 24,
                          child: Center(
                            child: Icon(Icons.check, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  for (final s in exercise.sets)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '#${s.setNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor(s.type, cs).withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.type.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _typeColor(s.type, cs),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              s.load,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              s.reps,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            child: Center(
                              child: Icon(
                                s.completed
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                size: 16,
                                color: s.completed
                                    ? Colors.green.shade600
                                    : Colors.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
