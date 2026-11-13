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
import '../workout_session/widgets/pending_exercises_sheet.dart';
import '../workout_session/widgets/set_count_summary.dart';
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
    final completedExercises =
        session.executedExercises.where((e) => e.completed).length;
    final pending = session.pendingExercises;

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
                          session.shortLabel,
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
                  // Parte do tempo foi usada para pendentes de outro treino
                  if (session.carriedPending != null) ...[
                    const SizedBox(height: 12),
                    _CarriedPendingNote(session.carriedPending!),
                  ],
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
                    icon: Icons.timer_outlined,
                    value: '${session.minutes} min',
                    label: 'Duração',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 130),
            child: SetCountSummary(
              counts: session.setCountByType,
              title:
                  'Séries totais: ${SetCountSummary.totalOf(session.setCountByType)}',
            ),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              // Sem COMPLETAR: o treino já foi finalizado
              child: IncompleteWorkoutBanner(
                pendingCount: pending.length,
                onTap: () => showPendingExercisesSheet(
                  context,
                  names: [for (final e in pending) e.name],
                  indexes: [
                    for (final e in pending) session.executedExercises.indexOf(e),
                  ],
                ),
              ),
            ),
          ],
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

/// Indica que o tempo desta sessão também foi usado para completar
/// pendentes de outro treino, e quais exercícios foram.
class _CarriedPendingNote extends StatelessWidget {
  final CarriedPending carried;

  const _CarriedPendingNote(this.carried);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      key: const Key('carried_pending_note'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.playlist_add_check_rounded, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'O tempo deste treino também foi usado para pendentes do '
              '${carried.label}'
              '${carried.exerciseNames.isEmpty ? '' : ': ${carried.exerciseNames.join(', ')}'}.',
              style: TextStyle(fontSize: 13, color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
