import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Cartão de um aluno na lista do treinador.
class StudentCard extends StatelessWidget {
  final StudentSummary student;
  final bool showBilling;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.showBilling,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = student;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        s.name[0].toUpperCase(),
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
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
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            s.goal.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showBilling) StatusChip.active(s.enrollmentActive),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: s.currentWorkout,
                      icon: Icons.fitness_center,
                    ),
                    StatusChip(
                      label: 'Próx.: ${formatShort(s.nextFollowUp)}',
                      icon: Icons.event_outlined,
                    ),
                    if (s.needsReassessment)
                      const StatusChip(
                        label: 'Reavaliar',
                        icon: Icons.warning_amber_rounded,
                        color: Color(0xFFEF6C00),
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