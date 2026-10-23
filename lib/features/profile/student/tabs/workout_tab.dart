import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/widgets/exercise_tile.dart';
import 'package:mentz/features/profile/student/widgets/training_week_row.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = widget.student;
    final plan = s.workouts[_selected];

    return ProfileTabPage(
      children: [
        SectionCard(
          title: 'Próximo treino',
          icon: Icons.event_outlined,
          child: Column(
            children: [
              InfoRow(
                icon: Icons.play_circle_outline,
                label: 'Programado',
                value: s.nextWorkoutLabel,
              ),
              InfoRow(
                icon: Icons.support_agent_outlined,
                label: 'Treinador responsável',
                value: s.trainerName,
              ),
              const SizedBox(height: 8),
              TrainingWeekRow(trainingDays: s.trainingDays),
            ],
          ),
        ),
        SectionCard(
          title: 'Treino atual',
          icon: Icons.fitness_center,
          child: Column(
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
                  onChanged: (done) => _toggleExercise('${plan.id}-$i', done),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Treinos concluídos',
          icon: Icons.history,
          child: Column(
            children: [
              for (final h in s.history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      h.plan,
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text('Treino ${h.plan}'),
                  subtitle: Text('${formatDate(h.date)}  •  ${h.minutes} min'),
                  trailing: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}