import 'package:flutter/material.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/status_chip.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/profile/student/widgets/edit_personal_info_sheet.dart';

/// Aba 1: contato, dados profissionais, especialidades e horários.
class ProfessionalTab extends StatelessWidget {
  final TrainerProfile trainer;

  const ProfessionalTab({super.key, required this.trainer});

  @override
  Widget build(BuildContext context) {
    final t = trainer;
    final primary = Theme.of(context).colorScheme.primary;
    final experience = t.experienceYears;
    final years = experience == null
        ? notInformed
        : '$experience ${experience == 1 ? 'ano' : 'anos'}';

    return ProfileTabPage(
      children: [

        SectionCard(
          title: 'Contato profissional',
          icon: Icons.contact_mail_outlined,
          trailing: IconButton(
            key: const Key('edit_trainer_personal_info_button'),
            tooltip: 'Editar',
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
            ),
            onPressed: () async {
              final saved = await showEditPersonalInfoSheet(
                context,
                name: t.name,
                phone: t.phone,
                birthDate: t.birthDate,
                sex: t.sex,
              );

              if (saved == true && context.mounted) {
                context.showSnack('Informações atualizadas.');
              }
            },
          ),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.person_outline,
                label: 'Nome completo',
                value: t.name,
              ),
              InfoRow(
                icon: Icons.cake_outlined,
                label: 'Nascimento',
                value: t.birthDate == null
                    ? notInformed
                    : '${formatDate(t.birthDate!)}  •  '
                    '${ageFrom(t.birthDate!)} anos',
              ),
              InfoRow(
                icon: Icons.mail_outline,
                label: 'E-mail profissional',
                value: t.email.isEmpty
                    ? notInformed
                    : t.email,
              ),
              InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone profissional',
                value: t.phone ?? notInformed,
              ),
              if (t.sex != null)
                InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Sexo (opcional)',
                  value: t.sex!,
                ),
            ],
          ),
        ),

        SectionCard(
          title: 'Dados profissionais',
          icon: Icons.work_outline,
          trailing: t.employmentActive == null
              ? null
              : StatusChip.active(t.employmentActive!),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.assignment_ind_outlined,
                label: 'Cargo',
                value: t.role?.label ?? notInformed,
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
                value: t.employmentActive == null
                    ? notInformed
                    : (t.employmentActive! ? 'Ativo' : 'Inativo'),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Especialidades',
          icon: Icons.sports_gymnastics,
          child: t.specialties.isEmpty
              ? const EmptyHint('Nenhuma especialidade cadastrada.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in t.specialties) StatusChip(label: s),
                  ],
                ),
        ),
        SectionCard(
          title: 'Formação e qualificações',
          icon: Icons.school_outlined,
          child: t.qualifications.isEmpty
              ? const EmptyHint('Nenhuma qualificação cadastrada.')
              : Column(
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
          child: t.availability.isEmpty
              ? const EmptyHint('Nenhum horário cadastrado.')
              : Column(
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