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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < exercise.sets.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ExecutedSetRow(exercise.sets[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma série em duas linhas: número, tipo e situação em cima; faixa, carga e
/// repetições embaixo. As repetições usam a cor do desempenho na faixa.
class _ExecutedSetRow extends StatelessWidget {
  final ExecutedSet set;

  const _ExecutedSetRow(this.set);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = set.completed;
    final range = set.rangeLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${set.setNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(width: 8),
              // Tipo da série e, quando houver, o drop set que a acompanha
              _SetTag(set.type.label, set.type.color),
              if (set.isDropSet) ...[
                const SizedBox(width: 4),
                const _SetTag(dropSetLabel, dropSetColor),
              ],
              const Spacer(),
              Icon(
                done ? Icons.check_circle : Icons.cancel_outlined,
                size: 16,
                color: done ? Colors.green.shade600 : Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              if (range != null) _Value('Faixa', range, color: cs.onSurfaceVariant),
              _Value('Carga', done ? set.loadLabel : '—'),
              _Value(
                'Reps',
                done ? set.repsLabel : '—',
                color: set.performance?.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Etiqueta colorida do tipo da série, sempre em uma linha.
class _SetTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SetTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Par "rótulo valor" (ex: "Carga 40 kg").
class _Value extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Value(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
