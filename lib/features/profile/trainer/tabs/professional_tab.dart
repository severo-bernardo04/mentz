import 'package:flutter/material.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Aba 1: contato, dados profissionais, especialidades e horários.
class ProfessionalTab extends StatelessWidget {
  final TrainerProfile trainer;

  const ProfessionalTab({super.key, required this.trainer});

  @override
  Widget build(BuildContext context) {
    final t = trainer;
    final primary = Theme.of(context).colorScheme.primary;
    final years = '${t.experienceYears} '
        '${t.experienceYears == 1 ? 'ano' : 'anos'}';

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
                value: years,
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
                  leading: Icon(
                    Icons.workspace_premium_outlined,
                    color: primary,
                  ),
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
                InfoRow(icon: Icons.access_time, label: e.key, value: e.value),
            ],
          ),
        ),
      ],
    );
  }
}