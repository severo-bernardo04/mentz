import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/widgets/achievement_badge.dart';
import 'package:mentz/features/profile/student/widgets/body_measures_table.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/simple_bar_chart.dart';
import 'package:mentz/widgets/stat_tile.dart';

/// Aba 4: progresso e desempenho.
/// Os totais de treinos vêm do histórico real do usuário.
class ProgressTab extends StatelessWidget {
  static const _monthNames = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];
  static const _chartMonths = 6;

  final StudentProfile student;

  const ProgressTab({super.key, required this.student});

  /// Primeiro dia de cada um dos últimos meses, do mais antigo ao atual.
  List<DateTime> _lastMonths(DateTime now) => [
    for (var i = _chartMonths - 1; i >= 0; i--)
      DateTime(now.year, now.month - i),
  ];

  int _countIn(List<CompletedWorkout> sessions, DateTime month) => sessions
      .where((s) => s.date.year == month.year && s.date.month == month.month)
      .length;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TrainingHistoryService(),
      builder: (context, _) => _buildContent(
        context,
        TrainingHistoryService().sessions,
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<CompletedWorkout> sessions) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = student;
    final unlocked = s.achievements.where((a) => a.unlocked).length;
    final months = _lastMonths(DateTime.now());

    return ProfileTabPage(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.fitness_center,
                value: '${sessions.length}',
                label: 'Treinos realizados',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_month_outlined,
                value: '${_countIn(sessions, months.last)}',
                label: 'Treinos no mês',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Frequência mensal',
          icon: Icons.bar_chart_rounded,
          child: sessions.isEmpty
              ? const EmptyHint('Nenhum treino realizado ainda.')
              : SimpleBarChart(
                  values: [for (final m in months) _countIn(sessions, m)],
                  labels: [for (final m in months) _monthNames[m.month - 1]],
                ),
        ),
        SectionCard(
          title: 'Recordes pessoais',
          icon: Icons.emoji_events_outlined,
          child: s.records.isEmpty
              ? const EmptyHint('Nenhum recorde registrado.')
              : Column(
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
          child: s.goalsReached.isEmpty
              ? const EmptyHint('Nenhuma meta registrada.')
              : Column(
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
          child: s.measures.isEmpty
              ? const EmptyHint('Nenhuma medida registrada.')
              : BodyMeasuresTable(measures: s.measures),
        ),
        SectionCard(
          title: 'Conquistas',
          icon: Icons.workspace_premium_outlined,
          trailing: s.achievements.isEmpty
              ? null
              : Text(
                  '$unlocked/${s.achievements.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
          child: s.achievements.isEmpty
              ? const EmptyHint('Nenhuma conquista ainda.')
              : GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: [
                    for (final a in s.achievements)
                      AchievementBadge(achievement: a),
                  ],
                ),
        ),
      ],
    );
  }
}
