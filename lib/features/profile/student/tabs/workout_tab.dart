import 'package:flutter/material.dart';
import 'package:mentz/core/routes/fade_slide_route.dart';
import 'package:mentz/features/profile/student/widgets/exercise_tile.dart';
import 'package:mentz/features/profile/student/widgets/training_week_row.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/features/training_history/training_history_page.dart';
import 'package:mentz/features/training_history/workout_session_detail_page.dart';
import 'package:mentz/features/workout_session/widgets/pending_exercises_sheet.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/services/workout_schedule_service.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/section_card.dart';

/// Aba 3: próximo treino, ficha atual (com checklist) e histórico.
class WorkoutTab extends StatefulWidget {
  final StudentProfile student;

  const WorkoutTab({super.key, required this.student});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  /// Quantidade de treinos recentes mostrados nesta aba.
  static const _recentSessions = 5;

  int _selected = 0;
  final Set<String> _checked = {};

  void _toggleExercise(String key, bool done) {
    setState(() {
      if (done) {
        _checked.add(key);
      } else {
        _checked.remove(key);
      }
    });
  }

  /// Próximo treino da planilha atual.
  String _nextWorkoutText() {
    final current = TrainingChartService().currentChart;
    if (current == null) return 'Nenhuma planilha criada';

    final next = WorkoutScheduleService.nextWorkout(
      current,
      TrainingHistoryService().sessions,
    );
    return next == null
        ? notInformed
        : WorkoutScheduleService.label(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = widget.student;
    final plan = s.workouts.isEmpty ? null : s.workouts[_selected];

    return ProfileTabPage(
      children: [
        SectionCard(
          title: 'Próximo treino',
          icon: Icons.event_outlined,
          child: Column(
            children: [
              // Recalcula sempre que as planilhas ou o histórico mudam
              ListenableBuilder(
                listenable: Listenable.merge([
                  TrainingChartService(),
                  TrainingHistoryService(),
                ]),
                builder: (context, _) => InfoRow(
                  icon: Icons.play_circle_outline,
                  label: 'Programado',
                  value: _nextWorkoutText(),
                ),
              ),
              InfoRow(
                icon: Icons.support_agent_outlined,
                label: 'Treinador responsável',
                value: s.trainerName ?? notInformed,
              ),
              const SizedBox(height: 8),
              if (s.trainingDays.isNotEmpty)
                TrainingWeekRow(trainingDays: s.trainingDays),
            ],
          ),
        ),
        SectionCard(
          title: 'Treino atual',
          icon: Icons.fitness_center,
          child: plan == null
              ? const EmptyHint('Nenhuma ficha de treino.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < s.workouts.length; i++)
                          ChoiceChip(
                            label: Text('Treino ${s.workouts[i].name}'),
                            selected: _selected == i,
                            onSelected: (_) => setState(() => _selected = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      plan.focus,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < plan.exercises.length; i++)
                      ExerciseTile(
                        index: i + 1,
                        exercise: plan.exercises[i],
                        checked: _checked.contains('${plan.id}-$i'),
                        onChanged: (done) =>
                            _toggleExercise('${plan.id}-$i', done),
                      ),
                  ],
                ),
        ),
        SectionCard(
          title: 'Treinos concluídos',
          icon: Icons.history,
          trailing: TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Ver todos'),
            onPressed: () => context.pushFade(const TrainingHistoryPage()),
          ),
          // Mesma fonte de "Ver todos", com os exercícios de cada treino
          child: ListenableBuilder(
            listenable: TrainingHistoryService(),
            builder: (context, _) {
              final sessions = TrainingHistoryService().sessions
                  .take(_recentSessions)
                  .toList();

              if (sessions.isEmpty) {
                return const EmptyHint('Nenhum treino concluído ainda.');
              }

              return Column(
                children: [
                  for (final h in sessions)
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () => context.pushFade(
                          WorkoutSessionDetailPage(session: h),
                        ),
                        // Quantidade de exercícios do treino
                        leading: Tooltip(
                          message: 'Exercícios',
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              '${h.executedExercises.length}',
                              style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        title: Text(h.workoutName ?? h.plan),
                        subtitle: Text(
                          '${formatDate(h.date)}  •  ${h.minutes} min',
                        ),
                        // Verde quando completo; laranja com pendentes
                        trailing: h.isIncomplete
                            ? const Icon(
                                Icons.warning_amber_rounded,
                                color: incompleteColor,
                              )
                            : Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                              ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
