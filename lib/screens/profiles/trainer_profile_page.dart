import 'package:flutter/material.dart';

import '../../models/profile_models.dart';
import '../auth_widgets.dart';
import 'profile_widgets.dart';
import 'student_profile_page.dart';
import 'workout_editor_page.dart';

/// Perfil do treinador: dados profissionais + ferramentas de gestão.
/// As informações pessoais ficam na aba "Perfil"; o restante são ferramentas de trabalho.
class TrainerProfilePage extends StatefulWidget {
  final TrainerProfile trainer;
  const TrainerProfilePage({super.key, required this.trainer});

  @override
  State<TrainerProfilePage> createState() => _TrainerProfilePageState();
}

class _TrainerProfilePageState extends State<TrainerProfilePage> {
  late final List<WorkoutPlan> _plans = [...widget.trainer.plans];
  late final List<Appointment> _appointments = [...widget.trainer.appointments];
  late final List<String> _newStudents = [...widget.trainer.newStudents];

  Future<void> _openEditor([WorkoutPlan? plan]) async {
    final result = await Navigator.of(context).push<WorkoutPlan>(
      fadeSlideRoute(
        WorkoutEditorPage(
          plan: plan,
          studentNames: [for (final s in widget.trainer.students) s.name],
        ),
      ),
    );
    if (result == null) return;

    setState(() {
      final i = _plans.indexWhere((p) => p.id == result.id);
      if (i >= 0) {
        _plans[i] = result;
      } else {
        _plans.add(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trainer;

    return ProfileScaffold(
      title: 'Meu perfil',
      header: ProfileHeader(
        name: t.name,
        subtitle: t.role.label,
        photoUrl: t.photoUrl,
        onEditPhoto: () {
          // TODO: escolher foto (image_picker) e enviar ao Storage
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Troca de foto em breve.')),
          );
        },
        chips: [
          StatusChip.active(t.employmentActive,
              activeLabel: 'Vínculo ativo', inactiveLabel: 'Vínculo inativo'),
          if (t.cref != null)
            StatusChip(label: 'CREF ${t.cref}', icon: Icons.verified_outlined),
        ],
      ),
      tabs: const [
        ProfileTabSpec(Icons.badge_outlined, 'Perfil'),
        ProfileTabSpec(Icons.groups_outlined, 'Alunos'),
        ProfileTabSpec(Icons.assignment_outlined, 'Treinos'),
        ProfileTabSpec(Icons.event_note_outlined, 'Agenda'),
      ],
      pages: [
        _ProfessionalTab(trainer: t),
        _StudentsTab(trainer: t),
        _PlansTab(
          plans: _plans,
          onCreate: () => _openEditor(),
          onEdit: _openEditor,
          onDelete: (p) => setState(() => _plans.remove(p)),
        ),
        _AgendaTab(
          trainer: t,
          appointments: _appointments,
          newStudents: _newStudents,
          onChanged: () => setState(() {}),
          onDismissNewStudent: (n) => setState(() => _newStudents.remove(n)),
        ),
      ],
    );
  }
}

// ───────────────────────── 1. Informações profissionais ─────────────────────────

class _ProfessionalTab extends StatelessWidget {
  final TrainerProfile trainer;
  const _ProfessionalTab({required this.trainer});

  @override
  Widget build(BuildContext context) {
    final t = trainer;

    return ProfileTabPage(
      children: [
        SectionCard(
          title: 'Contato profissional',
          icon: Icons.contact_mail_outlined,
          child: Column(
            children: [
              InfoRow(
                icon: Icons.person_outline,
                label: 'Nome completo',
                value: t.name,
              ),
              InfoRow(
                icon: Icons.mail_outline,
                label: 'E-mail profissional',
                value: t.email,
              ),
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone profissional',
                value: t.phone,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Dados profissionais',
          icon: Icons.work_outline,
          trailing: StatusChip.active(t.employmentActive),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.assignment_ind_outlined,
                label: 'Cargo',
                value: t.role.label,
              ),
              if (t.cref != null)
                InfoRow(
                  icon: Icons.verified_outlined,
                  label: 'CREF',
                  value: t.cref!,
                ),
              InfoRow(
                icon: Icons.timelapse,
                label: 'Tempo de experiência',
                value:
                    '${t.experienceYears} ${t.experienceYears == 1 ? 'ano' : 'anos'}',
              ),
              InfoRow(
                icon: Icons.handshake_outlined,
                label: 'Vínculo com a academia',
                value: t.employmentActive ? 'Ativo' : 'Inativo',
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Especialidades',
          icon: Icons.sports_gymnastics,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in t.specialties) StatusChip(label: s)],
          ),
        ),
        SectionCard(
          title: 'Formação e qualificações',
          icon: Icons.school_outlined,
          child: Column(
            children: [
              for (final q in t.qualifications)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.workspace_premium_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(q),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Horários de atendimento',
          icon: Icons.schedule,
          child: Column(
            children: [
              for (final e in t.availability.entries)
                InfoRow(
                  icon: Icons.access_time,
                  label: e.key,
                  value: e.value,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 2. Gestão de alunos ─────────────────────────

class _StudentsTab extends StatefulWidget {
  final TrainerProfile trainer;
  const _StudentsTab({required this.trainer});

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String _query = '';

  void _openStudent(StudentSummary s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StudentSheet(
        student: s,
        canViewBilling: widget.trainer.canViewBilling,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final q = _query.trim().toLowerCase();
    final list = [
      for (final s in widget.trainer.students)
        if (q.isEmpty || s.name.toLowerCase().contains(q)) s,
    ];

    return ProfileTabPage(
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: authInputDecoration(
            context,
            label: 'Buscar aluno por nome',
            icon: Icons.search,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '${list.length} ${list.length == 1 ? 'aluno vinculado' : 'alunos vinculados'}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        if (list.isEmpty) const EmptyHint('Nenhum aluno encontrado.'),
        for (final s in list)
          _StudentCard(
            student: s,
            showBilling: widget.trainer.canViewBilling,
            onTap: () => _openStudent(s),
          ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentSummary student;
  final bool showBilling;
  final VoidCallback onTap;

  const _StudentCard({
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
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            s.goal.label,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
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
                        label: s.currentWorkout, icon: Icons.fitness_center),
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

class _StudentSheet extends StatelessWidget {
  final StudentSummary student;
  final bool canViewBilling;

  const _StudentSheet({required this.student, required this.canViewBilling});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = student;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: s.goal.icon,
              label: 'Objetivo',
              value: s.goal.label,
            ),
            InfoRow(
              icon: Icons.fitness_center,
              label: 'Treino atual',
              value: s.currentWorkout,
            ),
            InfoRow(
              icon: Icons.trending_up,
              label: 'Frequência na semana',
              value: '${s.doneThisWeek} de ${s.weeklyTarget} treinos',
            ),
            InfoRow(
              icon: Icons.monitor_heart_outlined,
              label: 'Última avaliação física',
              value: formatDate(s.lastAssessment),
            ),
            InfoRow(
              icon: Icons.event_outlined,
              label: 'Próximo acompanhamento',
              value: formatDate(s.nextFollowUp),
            ),
            if (canViewBilling)
              InfoRow(
                icon: Icons.card_membership_outlined,
                label: 'Plano / matrícula',
                value: s.planName,
                valueWidget: Row(
                  children: [
                    Text(
                      '${s.planName}  ',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    StatusChip.active(s.enrollmentActive),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: buscar o perfil real do aluno pelo id (s.id)
                Navigator.of(context).push(
                  fadeSlideRoute(
                    StudentProfilePage(
                      student: StudentProfile.sample(name: s.name),
                      isOwnerView: false,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Ver perfil completo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 3. Criação e acompanhamento de treinos ─────────────────────────

class _PlansTab extends StatelessWidget {
  final List<WorkoutPlan> plans;
  final VoidCallback onCreate;
  final ValueChanged<WorkoutPlan> onEdit;
  final ValueChanged<WorkoutPlan> onDelete;

  const _PlansTab({
    required this.plans,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context, WorkoutPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir treino ${p.name}?'),
        content: const Text(
          'A ficha será removida dos alunos associados. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) onDelete(p);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ProfileTabPage(
      children: [
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova ficha de treino'),
        ),
        const SizedBox(height: 16),
        if (plans.isEmpty) const EmptyHint('Você ainda não criou nenhuma ficha.'),
        for (final p in plans)
          SectionCard(
            title: 'Treino ${p.name}',
            icon: Icons.assignment_outlined,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit(p);
                if (v == 'delete') _confirmDelete(context, p);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.focus.isNotEmpty)
                  Text(
                    p.focus,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: '${p.exercises.length} exercícios',
                      icon: Icons.fitness_center,
                    ),
                    StatusChip(
                      label: '${p.assignedStudents.length} alunos',
                      icon: Icons.group_outlined,
                    ),
                  ],
                ),
                if (p.assignedStudents.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Conclusão na semana',
                          style: theme.textTheme.labelLarge),
                      Text(
                        '${(p.weeklyCompletion * 100).round()}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: p.weeklyCompletion,
                      backgroundColor: cs.primary.withAlpha(30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.assignedStudents.join(', '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (p.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(90),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.notes)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onEdit(p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar ficha'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── 4. Agenda e acompanhamento ─────────────────────────

class _AgendaTab extends StatefulWidget {
  final TrainerProfile trainer;
  final List<Appointment> appointments;
  final List<String> newStudents;
  final VoidCallback onChanged;
  final ValueChanged<String> onDismissNewStudent;

  const _AgendaTab({
    required this.trainer,
    required this.appointments,
    required this.newStudents,
    required this.onChanged,
    required this.onDismissNewStudent,
  });

  @override
  State<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<_AgendaTab> {
  bool _weekly = false;
  int _day = (DateTime.now().weekday - 1).clamp(0, 6);

  List<Appointment> _forDay(int d) {
    final l = widget.appointments.where((a) => a.day == d).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return l;
  }

  void _setStatus(Appointment a, AppointmentStatus s) {
    setState(() => a.status = s);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final missed = widget.appointments
        .where((a) => a.status == AppointmentStatus.missed)
        .toList();
    final reassess =
        widget.trainer.students.where((s) => s.needsReassessment).toList();

    return ProfileTabPage(
      children: [
        // Novos alunos
        if (widget.newStudents.isNotEmpty)
          SectionCard(
            title: 'Novos alunos',
            icon: Icons.notifications_active_outlined,
            trailing: Badge(label: Text('${widget.newStudents.length}')),
            child: Column(
              children: [
                for (final n in widget.newStudents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: cs.tertiaryContainer,
                      child: Icon(Icons.person_add_alt_1,
                          color: cs.onTertiaryContainer, size: 20),
                    ),
                    title: Text(n,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Novo aluno vinculado a você'),
                    trailing: TextButton(
                      onPressed: () => widget.onDismissNewStudent(n),
                      child: const Text('Ciente'),
                    ),
                  ),
              ],
            ),
          ),

        // Alternância dia / semana
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.today_outlined),
              label: Text('Dia'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.date_range_outlined),
              label: Text('Semana'),
            ),
          ],
          selected: {_weekly},
          onSelectionChanged: (v) => setState(() => _weekly = v.first),
        ),
        const SizedBox(height: 14),

        if (!_weekly) ...[
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _DayPill(
                        label: weekdayShort[i],
                        count: _forDay(i).length,
                        selected: _day == i,
                        onTap: () => setState(() => _day = i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: weekdayShort[_day],
            icon: Icons.event_note_outlined,
            child: _AppointmentList(
              items: _forDay(_day),
              onStatus: _setStatus,
            ),
          ),
        ] else
          for (var i = 0; i < 7; i++)
            if (_forDay(i).isNotEmpty)
              SectionCard(
                title: weekdayShort[i],
                icon: Icons.event_note_outlined,
                child: _AppointmentList(
                  items: _forDay(i),
                  onStatus: _setStatus,
                ),
              ),

        // Lembretes de reavaliação
        SectionCard(
          title: 'Lembretes de reavaliação',
          icon: Icons.alarm_outlined,
          child: reassess.isEmpty
              ? const EmptyHint('Nenhuma reavaliação pendente.')
              : Column(
                  children: [
                    for (final s in reassess)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFEF6C00)),
                        title: Text(s.name),
                        subtitle: Text(
                          'Última avaliação: ${formatDate(s.lastAssessment)}',
                        ),
                      ),
                  ],
                ),
        ),

        // Faltas
        SectionCard(
          title: 'Registro de faltas',
          icon: Icons.person_off_outlined,
          child: missed.isEmpty
              ? const EmptyHint('Nenhuma falta registrada.')
              : Column(
                  children: [
                    for (final a in missed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(Icons.cancel_outlined, color: cs.error),
                        title: Text(a.student),
                        subtitle: Text(
                          '${weekdayShort[a.day]} às ${a.time} • ${a.type.label}',
                        ),
                        trailing: TextButton(
                          onPressed: () =>
                              _setStatus(a, AppointmentStatus.scheduled),
                          child: const Text('Desfazer'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _DayPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurface;

    return Material(
      color: selected ? cs.primary : cs.surface.withAlpha(235),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    color: fg, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<Appointment> items;
  final void Function(Appointment, AppointmentStatus) onStatus;

  const _AppointmentList({required this.items, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyHint('Sem compromissos neste dia.');

    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final a in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                a.time,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              a.student,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                decoration: a.status == AppointmentStatus.done
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(a.type.icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(child: Text(a.type.label)),
              ],
            ),
            trailing: switch (a.status) {
              AppointmentStatus.done =>
                Icon(Icons.check_circle, color: Colors.green.shade600),
              AppointmentStatus.missed =>
                Icon(Icons.cancel, color: cs.error),
              AppointmentStatus.scheduled => PopupMenuButton<AppointmentStatus>(
                  tooltip: 'Ações',
                  onSelected: (s) => onStatus(a, s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: AppointmentStatus.done,
                      child: Text('Marcar como realizado'),
                    ),
                    PopupMenuItem(
                      value: AppointmentStatus.missed,
                      child: Text('Registrar falta'),
                    ),
                  ],
                ),
            },
          ),
      ],
    );
  }
}