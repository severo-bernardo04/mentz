import 'package:flutter/material.dart';
import 'package:mentz/core/routes/fade_slide_route.dart';
import 'package:mentz/features/profile/student/student_profile_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Resumo do aluno em um bottom sheet, com atalho para o perfil completo.
class StudentSheet extends StatelessWidget {
  final StudentSummary student;
  final bool canViewBilling;

  const StudentSheet({
    super.key,
    required this.student,
    required this.canViewBilling,
  });

  void _openFullProfile(BuildContext context) {
    final s = student;

    Navigator.of(context).pop();
    // TODO: buscar o perfil real do aluno pelo id (s.id)
    context.pushFade(
      StudentProfilePage(
        student: StudentProfile.sample(name: s.name),
        isOwnerView: false,
      ),
    );
  }

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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            InfoRow(icon: s.goal.icon, label: 'Objetivo', value: s.goal.label),
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    StatusChip.active(s.enrollmentActive),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openFullProfile(context),
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