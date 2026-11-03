import 'package:flutter/material.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Aba 1: informações pessoais e matrícula.
class PersonalTab extends StatelessWidget {
  final StudentProfile student;

  const PersonalTab({super.key, required this.student});

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