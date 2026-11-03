import 'package:flutter/material.dart';
import '../../core/routes/fade_slide_route.dart';
import '../../models/profile_models.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_chip.dart';
import 'widgets/executed_exercise_card.dart';
import 'workout_spreadsheet_page.dart';

/// Tela de detalhes de uma sessão de treino específica do histórico.
class WorkoutSessionDetailPage extends StatelessWidget {
  final CompletedWorkout session;

  const WorkoutSessionDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalExercises = session.executedExercises.length;
    final totalSets = session.executedExercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );
    final completedExercises =
        session.executedExercises.where((e) => e.completed).length;

    return AppPageScaffold(
      title: 'Detalhes do Treino',
      maxWidth: 620,
      actions: [
        IconButton(
          tooltip: 'Visualizar em Planilha',
          icon: const Icon(Icons.table_chart_outlined),
          onPressed: () => context.pushFade(
            WorkoutSpreadsheetPage(initialPlan: session.plan),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          session.plan,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.displayChartName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.displayWorkoutName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
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
                        label: '${session.minutes} minutos',
                        icon: Icons.timer_outlined,
                        color: cs.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.fitness_center,
                    value: '$completedExercises/$totalExercises',
                    label: 'Exercícios',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.repeat_rounded,
                    value: '$totalSets',
                    label: 'Séries totais',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.timer_outlined,
                    value: '${session.minutes} min',
                    label: 'Duração',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: SectionCard(
              title: 'Exercícios Executados',
              icon: Icons.format_list_bulleted_rounded,
              trailing: Text(
                '$totalExercises itens',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Column(
                children: [
                  if (session.executedExercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum exercício registrado detalhadamente para esta sessão.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (var i = 0; i < session.executedExercises.length; i++)
                      ExecutedExerciseCard(
                        index: i + 1,
                        exercise: session.executedExercises[i],
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 250),
            child: AppButton(
              label: 'Ver Histórico Completo em Planilha',
              icon: Icons.table_chart_rounded,
              onPressed: () => context.pushFade(
                WorkoutSpreadsheetPage(initialPlan: session.plan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
