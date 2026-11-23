import 'package:flutter/material.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/status_chip.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/profile/student/widgets/edit_personal_info_sheet.dart';

/// Aba 1: informações pessoais e matrícula.
class PersonalTab extends StatelessWidget {
  final StudentProfile student;
  final bool isOwnerView;

  const PersonalTab({
    super.key,
    required this.student,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;

    return ProfileTabPage(
      children: [
        SectionCard(
          title: 'Informações pessoais',
          icon: Icons.badge_outlined,
          trailing: isOwnerView
              ? IconButton(
            key: const Key('edit_personal_info_button'),
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final saved = await showEditPersonalInfoSheet(
                context,
                name: s.name,
                phone: s.phone,
                birthDate: s.birthDate,
                sex: s.sex,
              );
              if (saved == true && context.mounted) {
                context.showSnack('Informações atualizadas.');
              }
            },
          )
              : null,
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
                value: s.birthDate == null
                    ? notInformed
                    : '${formatDate(s.birthDate!)}  •  '
                          '${ageFrom(s.birthDate!)} anos',
              ),
              InfoRow(
                icon: Icons.mail_outline,
                label: 'E-mail',
                value: s.email.isEmpty ? notInformed : s.email,
              ),
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: s.phone ?? notInformed,
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
          trailing: s.enrollmentActive == null
              ? null
              : StatusChip.active(s.enrollmentActive!),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.event_available_outlined,
                label: 'Data de matrícula',
                value: s.enrollmentDate == null
                    ? notInformed
                    : formatDate(s.enrollmentDate!),
              ),
              InfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Plano da academia',
                value: s.plan ?? notInformed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}