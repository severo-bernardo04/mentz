import 'package:flutter/material.dart';

import '../../models/profile_models.dart';
import 'profile_widgets.dart';

/// Perfil do aluno.
///
/// [isOwnerView] = true  → o próprio aluno vendo seu perfil.
/// [isOwnerView] = false → treinador autorizado vendo o perfil de um aluno.
class StudentProfilePage extends StatelessWidget {
  final StudentProfile student;
  final bool isOwnerView;

  const StudentProfilePage({
    super.key,
    required this.student,
    this.isOwnerView = true,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: isOwnerView ? 'Meu perfil' : 'Perfil do aluno',
      header: ProfileHeader(
        name: student.name,
        subtitle: student.plan,
        photoUrl: student.photoUrl,
        onEditPhoto: isOwnerView
            ? () {
                // TODO: escolher foto (image_picker) e enviar ao Storage
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Troca de foto em breve.')),
                );
              }
            : null,
        chips: [
          StatusChip.active(student.enrollmentActive,
              activeLabel: 'Matrícula ativa',
              inactiveLabel: 'Matrícula inativa'),
          StatusChip(label: student.goal.label, icon: student.goal.icon),
        ],
      ),
      tabs: const [
        ProfileTabSpec(Icons.person_outline, 'Pessoal'),
        ProfileTabSpec(Icons.monitor_heart_outlined, 'Físico'),
        ProfileTabSpec(Icons.fitness_center, 'Treino'),
        ProfileTabSpec(Icons.insights_outlined, 'Progresso'),
      ],
      pages: [
        _PersonalTab(student: student),
        _PhysicalTab(student: student, isOwnerView: isOwnerView),
        _WorkoutTab(student: student),
        _ProgressTab(student: student),
      ],
    );
  }
}

// ───────────────────────── 1. Informações pessoais ─────────────────────────

class _PersonalTab extends StatelessWidget {
  final StudentProfile student;
  const _PersonalTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;

    return ProfileTabPage(
      children: [
        SectionCard(
          title: 'Informações pessoais',
          icon: Icons.badge_outlined,
          child: Column(
            children: [
              InfoRow(
                icon: Icons.person_outline,
                label: 'Nome completo',
                value: s.name,
              ),
              InfoRow(
                icon: Icons.cake_outlined,
                label: 'Nascimento',
                value:
                    '${formatDate(s.birthDate)}  •  ${ageFrom(s.birthDate)} anos',
              ),
              InfoRow(
                icon: Icons.mail_outline,
                label: 'E-mail',
                value: s.email,
              ),
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: s.phone,
              ),
              if (s.sex != null)
                InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Sexo (opcional)',
                  value: s.sex!,
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Matrícula',
          icon: Icons.card_membership_outlined,
          trailing: StatusChip.active(s.enrollmentActive),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.event_available_outlined,
                label: 'Data de matrícula',
                value: formatDate(s.enrollmentDate),
              ),
              InfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Plano da academia',
                value: s.plan,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 2. Dados físicos e objetivos ─────────────────────────

class _PhysicalTab extends StatefulWidget {
  final StudentProfile student;
  final bool isOwnerView;
  const _PhysicalTab({required this.student, required this.isOwnerView});

  @override
  State<_PhysicalTab> createState() => _PhysicalTabState();
}

class _PhysicalTabState extends State<_PhysicalTab> {
  bool _hidden = false;

  String _mask(String v) => _hidden ? '•••' : v;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = widget.student;

    final first = s.weightHistory.first.kg;
    final delta = s.currentWeight - first;
    final deltaText = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';

    return ProfileTabPage(
      children: [
        PrivacyBanner(
          text: widget.isOwnerView
              ? 'Seus dados corporais e de saúde são privados. Só você e '
                  'profissionais autorizados da academia podem vê-los.'
              : 'Dados privados do aluno. Acesso permitido apenas ao '
                  'treinador responsável. Não compartilhe.',
          hidden: _hidden,
          onToggle: () => setState(() => _hidden = !_hidden),
        ),

        // Medidas atuais
        SectionCard(
          title: 'Medidas atuais',
          icon: Icons.straighten,
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.height,
                  value: _mask('${s.heightCm.toStringAsFixed(0)} cm'),
                  label: 'Altura',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.monitor_weight_outlined,
                  value: _mask('${s.currentWeight.toStringAsFixed(1)} kg'),
                  label: 'Peso atual',
                ),
              ),
            ],
          ),
        ),

        // Objetivo e meta
        SectionCard(
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
                    Text('Meta de peso',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      _mask(
                          '${s.currentWeight.toStringAsFixed(1)} → ${s.targetWeight!.toStringAsFixed(0)} kg'),
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: _hidden ? 0 : _goalProgress(s),
                    backgroundColor: cs.primary.withAlpha(30),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Frequência semanal
        SectionCard(
          title: 'Frequência semanal',
          icon: Icons.calendar_view_week_outlined,
          trailing: Text(
            '${s.doneThisWeek}/${s.weeklyTarget} treinos',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DayDot(
                  label: weekdayShort[i][0],
                  planned: s.trainingDays.contains(i),
                ),
            ],
          ),
        ),

        // Histórico de peso
        SectionCard(
          title: 'Histórico de peso',
          icon: Icons.show_chart,
          trailing: StatusChip(
            label: _hidden ? '•••' : deltaText,
            icon: delta <= 0 ? Icons.trending_down : Icons.trending_up,
          ),
          child: _hidden
              ? const EmptyHint('Valores ocultos')
              : SimpleLineChart(
                  values: [for (final w in s.weightHistory) w.kg],
                  labels: [
                    for (final w in s.weightHistory) formatShort(w.date)
                  ],
                  unit: ' kg',
                ),
        ),

        // Avaliações anteriores
        SectionCard(
          title: 'Avaliações físicas',
          icon: Icons.assignment_outlined,
          child: Column(
            children: [
              for (final a in s.assessments)
                _AssessmentTile(assessment: a, hidden: _hidden),
            ],
          ),
        ),
      ],
    );
  }

  /// Progresso em direção à meta, tomando o primeiro peso como ponto de partida.
  double _goalProgress(StudentProfile s) {
    final start = s.weightHistory.first.kg;
    final target = s.targetWeight!;
    final total = target - start;
    if (total == 0) return 1;
    return ((s.currentWeight - start) / total).clamp(0.0, 1.0);
  }
}

class _GoalChip extends StatelessWidget {
  final FitnessGoal goal;
  final bool selected;
  const _GoalChip({required this.goal, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(goal.icon,
              size: 16, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            goal.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool planned;
  const _DayDot({required this.label, required this.planned});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: planned ? cs.primary : cs.surfaceContainerHighest,
          ),
          child: Icon(
            planned ? Icons.fitness_center : Icons.hotel_outlined,
            size: 17,
            color: planned ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  final Assessment assessment;
  final bool hidden;
  const _AssessmentTile({required this.assessment, required this.hidden});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = assessment;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(formatDate(a.date),
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        hidden
            ? '•••'
            : '${a.weight.toStringAsFixed(1)} kg  •  ${a.bodyFat.toStringAsFixed(1)}% gordura',
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            a.notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 3. Informações de treino ─────────────────────────

class _WorkoutTab extends StatefulWidget {
  final StudentProfile student;
  const _WorkoutTab({required this.student});

  @override
  State<_WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<_WorkoutTab> {
  int _selected = 0;
  final Set<String> _checked = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = widget.student;
    final plan = s.workouts[_selected];

    return ProfileTabPage(
      children: [
        // Próximo treino + treinador
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _DayDot(
                      label: weekdayShort[i][0],
                      planned: s.trainingDays.contains(i),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Treino atual
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
                _ExerciseTile(
                  index: i + 1,
                  exercise: plan.exercises[i],
                  checked: _checked.contains('${plan.id}-$i'),
                  onChanged: (v) => setState(() {
                    final key = '${plan.id}-$i';
                    v ? _checked.add(key) : _checked.remove(key);
                  }),
                ),
            ],
          ),
        ),

        // Histórico
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
                  trailing:
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _ExerciseTile({
    required this.index,
    required this.exercise,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final e = exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: checked
            ? cs.primaryContainer.withAlpha(120)
            : cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: cs.primary,
            child: Text(
              '$index',
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 13,
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
                  e.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (e.muscle.isNotEmpty)
                  Text(
                    e.muscle,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(label: '${e.sets} × ${e.reps}'),
                    StatusChip(label: e.load, icon: Icons.scale_outlined),
                    StatusChip(label: e.restLabel, icon: Icons.timer_outlined),
                  ],
                ),
              ],
            ),
          ),
          Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
        ],
      ),
    );
  }
}

// ───────────────────────── 4. Progresso e desempenho ─────────────────────────

class _ProgressTab extends StatelessWidget {
  final StudentProfile student;
  const _ProgressTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = student;

    return ProfileTabPage(
      children: [
        // Resumo
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
                  leading: Icon(Icons.military_tech, color: Colors.amber.shade700),
                  title: Text(r.exercise,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  leading:
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                  title: Text(g),
                ),
            ],
          ),
        ),

        SectionCard(
          title: 'Medidas corporais',
          icon: Icons.straighten,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 0,
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(label: Text('Data')),
                DataColumn(label: Text('Peito'), numeric: true),
                DataColumn(label: Text('Cintura'), numeric: true),
                DataColumn(label: Text('Quadril'), numeric: true),
                DataColumn(label: Text('Braço'), numeric: true),
                DataColumn(label: Text('Coxa'), numeric: true),
              ],
              rows: [
                for (final m in s.measures)
                  DataRow(cells: [
                    DataCell(Text(formatShort(m.date))),
                    DataCell(Text('${m.chest}')),
                    DataCell(Text('${m.waist}')),
                    DataCell(Text('${m.hip}')),
                    DataCell(Text('${m.arm}')),
                    DataCell(Text('${m.thigh}')),
                  ]),
              ],
            ),
          ),
        ),

        SectionCard(
          title: 'Conquistas',
          icon: Icons.workspace_premium_outlined,
          trailing: Text(
            '${s.achievements.where((a) => a.unlocked).length}/${s.achievements.length}',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
          ),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              for (final a in s.achievements) _Badge(achievement: a),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Achievement achievement;
  const _Badge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = achievement;

    return Tooltip(
      message: a.description,
      child: Opacity(
        opacity: a.unlocked ? 1 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: a.unlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.tertiary],
                      )
                    : null,
                color: a.unlocked ? null : cs.surfaceContainerHighest,
              ),
              child: Icon(
                a.unlocked ? a.icon : Icons.lock_outline,
                color: a.unlocked ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}