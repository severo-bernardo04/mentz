import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/widgets/achievement_badge.dart';
import 'package:mentz/features/profile/student/widgets/body_measures_table.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/simple_bar_chart.dart';
import 'package:mentz/widgets/stat_tile.dart';

/// Aba 4: progresso e desempenho.
class ProgressTab extends StatelessWidget {
  final StudentProfile student;

  const ProgressTab({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = student;
    final unlocked = s.achievements.where((a) => a.unlocked).length;

    return ProfileTabPage(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.fitness_center,
                value: '${s.totalWorkouts}',
                label: 'Treinos realizados',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_outlined,
                value: '${s.streakWeeks} sem.',
                label: 'Sequência',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_month_outlined,
                value: '${s.monthlyFrequency.last}',
                label: 'Treinos no mês',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Frequência mensal',
          icon: Icons.bar_chart_rounded,
          child: SimpleBarChart(
            values: s.monthlyFrequency,
            labels: s.monthLabels,
          ),
        ),
        SectionCard(
          title: 'Recordes pessoais',
          icon: Icons.emoji_events_outlined,
          child: Column(
            children: [
              for (final r in s.records)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.military_tech,
                    color: Colors.amber.shade700,
                  ),
                  title: Text(
                    r.exercise,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(formatDate(r.date)),
                  trailing: Text(
                    r.value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Metas alcançadas',
          icon: Icons.task_alt,
          child: Column(
            children: [
              for (final g in s.goalsReached)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                  ),
                  title: Text(g),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Medidas corporais',
          icon: Icons.straighten,
          child: BodyMeasuresTable(measures: s.measures),
        ),
        SectionCard(
          title: 'Conquistas',
          icon: Icons.workspace_premium_outlined,
          trailing: Text(
            '$unlocked/${s.achievements.length}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              for (final a in s.achievements) AchievementBadge(achievement: a),
            ],
          ),
        ),
      ],
    );
  }
}