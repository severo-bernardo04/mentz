import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import '../../../widgets/status_chip.dart';

/// Card reutilizável que exibe o resumo de uma sessão executada no histórico.
class WorkoutSessionCard extends StatelessWidget {
  final CompletedWorkout session;
  final VoidCallback onTap;

  const WorkoutSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalExercises = session.executedExercises.length;
    final uncompletedCount =
        session.executedExercises.where((e) => !e.completed).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        session.plan,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                session.displayChartName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session.displayWorkoutName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(
                      label: formatDate(session.date),
                      icon: Icons.calendar_today_outlined,
                    ),
                    StatusChip(
                      label: session.weekdayName,
                      icon: Icons.event_note_outlined,
                    ),
                    StatusChip(
                      label: '${session.minutes} min',
                      icon: Icons.timer_outlined,
                      color: cs.primary,
                    ),
                    if (totalExercises > 0)
                      StatusChip(
                        label: '$totalExercises exercícios',
                        icon: Icons.fitness_center_outlined,
                      ),
                    if (uncompletedCount > 0)
                      StatusChip(
                        label: '$uncompletedCount incompleto(s)',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
