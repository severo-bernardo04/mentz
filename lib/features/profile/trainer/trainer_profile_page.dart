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
import 'package:mentz/services/trainer_service.dart';
import 'package:mentz/widgets/status_chip.dart';
import 'package:mentz/services/photo_service.dart';

/// Perfil do treinador: dados profissionais + ferramentas de gestão.
///
/// Os dados chegam prontos em [trainer] (carregados pelo [TrainerService]) e
/// as alterações feitas aqui são gravadas pelo mesmo serviço; a tela se
/// atualiza quando o Firestore devolve o novo estado.
class TrainerProfilePage extends StatelessWidget {
  final TrainerProfile trainer;

  const TrainerProfilePage({super.key, required this.trainer});

  Future<void> _openEditor(BuildContext context, [WorkoutPlan? plan]) async {
    final result = await context.pushFade<WorkoutPlan>(
      WorkoutEditorPage(
        plan: plan,
        studentNames: [for (final s in trainer.students) s.name],
      ),
    );
    if (!context.mounted || result == null) return;

    await _persist(
      context,
          () => TrainerService().savePlan(result),
      'Não foi possível salvar a ficha.',
    );
  }

  /// Marca o aluno como visto, procurando-o pelo nome exibido no aviso.
  Future<void> _dismissNewStudent(BuildContext context, String name) async {
    final matches = trainer.students.where((s) => s.name == name);
    if (matches.isEmpty) return;

    await _persist(
      context,
          () => TrainerService().markStudentSeen(matches.first.id),
      'Não foi possível atualizar o aviso.',
    );
  }

  /// Executa uma gravação e avisa o treinador se ela falhar.
  Future<void> _persist(
      BuildContext context,
      Future<void> Function() action,
      String errorMessage,
      ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) context.showSnack(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = trainer;

    return ProfileScaffold(
      title: 'Meu perfil',
      header: ProfileHeader(
        name: t.name,
        subtitle: t.role?.label ?? 'Treinador',
        photoUrl: t.photoUrl,
        onEditPhoto: () => _changePhoto(context),
        chips: [
          if (t.employmentActive != null)
            StatusChip.active(
              t.employmentActive!,
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
          plans: t.plans,
          onCreate: () => _openEditor(context),
          onEdit: (p) => _openEditor(context, p),
          onDelete: (p) => _persist(
            context,
                () => TrainerService().deletePlan(p.id),
            'Não foi possível excluir a ficha.',
          ),
        ),
        AgendaTab(
          trainer: t,
          appointments: t.appointments,
          newStudents: t.newStudents,
          onStatusChange: (a, status) => _persist(
            context,
                () => TrainerService().setAppointmentStatus(a.id, status),
            'Não foi possível atualizar o compromisso.',
          ),
          onDismissNewStudent: (name) => _dismissNewStudent(context, name),
        ),
      ],
    );
  }
  Future<void> _changePhoto(BuildContext context) async {
    try {
      final ok = await PhotoService().pickAndSave();
      if (ok && context.mounted) context.showSnack('Foto atualizada.');
    } catch (_) {
      if (context.mounted) {
        context.showSnack('Não foi possível enviar a foto.');
      }
    }
  }
}