import 'package:flutter/material.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/profile/student/tabs/personal_tab.dart';
import 'package:mentz/features/profile/student/tabs/physical_tab.dart';
import 'package:mentz/features/profile/student/tabs/progress_tab.dart';
import 'package:mentz/features/profile/student/tabs/workout_tab.dart';
import 'package:mentz/features/profile/widgets/profile_header.dart';
import 'package:mentz/features/profile/widgets/profile_scaffold.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/status_chip.dart';

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
        // TODO: escolher foto (image_picker) e enviar ao Storage
        onEditPhoto:
            isOwnerView ? () => context.showSnack('Troca de foto em breve.') : null,
        chips: [
          StatusChip.active(
            student.enrollmentActive,
            activeLabel: 'Matrícula ativa',
            inactiveLabel: 'Matrícula inativa',
          ),
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
        PersonalTab(student: student),
        PhysicalTab(student: student, isOwnerView: isOwnerView),
        WorkoutTab(student: student),
        ProgressTab(student: student),
      ],
    );
  }
}