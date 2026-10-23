import 'package:flutter/material.dart';
import 'package:mentz/core/routes/fade_slide_route.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/profile/trainer/tabs/agenda_tab.dart';
import 'package:mentz/features/profile/trainer/tabs/plans_tab.dart';
import 'package:mentz/features/profile/trainer/tabs/professional_tab.dart';
import 'package:mentz/features/profile/trainer/tabs/students_tab.dart';
import 'package:mentz/features/profile/widgets/profile_header.dart';
import 'package:mentz/features/profile/widgets/profile_scaffold.dart';
import 'package:mentz/features/training/workout_editor_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Perfil do treinador: dados profissionais + ferramentas de gestão.
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
    final result = await context.pushFade<WorkoutPlan>(
      WorkoutEditorPage(
        plan: plan,
        studentNames: [for (final s in widget.trainer.students) s.name],
      ),
    );
    if (!mounted || result == null) return;

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
        // TODO: escolher foto (image_picker) e enviar ao Storage
        onEditPhoto: () => context.showSnack('Troca de foto em breve.'),
        chips: [
          StatusChip.active(
            t.employmentActive,
            activeLabel: 'Vínculo ativo',
            inactiveLabel: 'Vínculo inativo',
          ),
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
        ProfessionalTab(trainer: t),
        StudentsTab(trainer: t),
        PlansTab(
          plans: _plans,
          onCreate: () => _openEditor(),
          onEdit: _openEditor,
          onDelete: (p) => setState(() => _plans.remove(p)),
        ),
        AgendaTab(
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