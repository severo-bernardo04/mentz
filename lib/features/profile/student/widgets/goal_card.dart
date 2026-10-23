import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/section_card.dart';

/// Objetivo do aluno + progresso em direção à meta de peso.
class GoalCard extends StatelessWidget {
  final StudentProfile student;
  final bool hidden;

  const GoalCard({super.key, required this.student, required this.hidden});

  /// Progresso em direção à meta, tomando o primeiro peso como ponto de partida.
  double get _progress {
    final start = student.weightHistory.first.kg;
    final total = student.targetWeight! - start;
    if (total == 0) return 1;
    return ((student.currentWeight - start) / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = student;

    return SectionCard(
      title: 'Objetivo',
      icon: Icons.flag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in FitnessGoal.values)
                _GoalChip(goal: g, selected: g == s.goal),
            ],
          ),
          if (s.targetWeight != null) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meta de peso',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hidden
                      ? '•••'
                      : '${s.currentWeight.toStringAsFixed(1)} → '
                          '${s.targetWeight!.toStringAsFixed(0)} kg',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: hidden ? 0 : _progress,
                backgroundColor: theme.colorScheme.primary.withAlpha(30),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final FitnessGoal goal;
  final bool selected;

  const _GoalChip({required this.goal, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(goal.icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            goal.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}