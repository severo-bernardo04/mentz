import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/widgets/assessment_tile.dart';
import 'package:mentz/features/profile/student/widgets/goal_card.dart';
import 'package:mentz/features/profile/student/widgets/training_week_row.dart';
import 'package:mentz/features/profile/widgets/privacy_banner.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/simple_line_chart.dart';
import 'package:mentz/widgets/stat_tile.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Aba 2: dados físicos e objetivos (privados, com opção de ocultar valores).
class PhysicalTab extends StatefulWidget {
  final StudentProfile student;
  final bool isOwnerView;

  const PhysicalTab({
    super.key,
    required this.student,
    required this.isOwnerView,
  });

  @override
  State<PhysicalTab> createState() => _PhysicalTabState();
}

class _PhysicalTabState extends State<PhysicalTab> {
  static const _ownerText = 'Seus dados corporais e de saúde são privados. '
      'Só você e profissionais autorizados da academia podem vê-los.';

  static const _trainerText = 'Dados privados do aluno. Acesso permitido '
      'apenas ao treinador responsável. Não compartilhe.';

  bool _hidden = false;

  String _mask(String v) => _hidden ? '•••' : v;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.student;

    final delta = s.currentWeight - s.weightHistory.first.kg;
    final deltaText = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';

    return ProfileTabPage(
      children: [
        PrivacyBanner(
          text: widget.isOwnerView ? _ownerText : _trainerText,
          hidden: _hidden,
          onToggle: () => setState(() => _hidden = !_hidden),
        ),
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
        GoalCard(student: s, hidden: _hidden),
        SectionCard(
          title: 'Frequência semanal',
          icon: Icons.calendar_view_week_outlined,
          trailing: Text(
            '${s.doneThisWeek}/${s.weeklyTarget} treinos',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: TrainingWeekRow(trainingDays: s.trainingDays),
        ),
        SectionCard(
          title: 'Histórico de peso',
          icon: Icons.show_chart,
          trailing: StatusChip(
            label: _mask(deltaText),
            icon: delta <= 0 ? Icons.trending_down : Icons.trending_up,
          ),
          child: _hidden
              ? const EmptyHint('Valores ocultos')
              : SimpleLineChart(
                  values: [for (final w in s.weightHistory) w.kg],
                  labels: [
                    for (final w in s.weightHistory) formatShort(w.date),
                  ],
                  unit: ' kg',
                ),
        ),
        SectionCard(
          title: 'Avaliações físicas',
          icon: Icons.assignment_outlined,
          child: Column(
            children: [
              for (final a in s.assessments)
                AssessmentTile(assessment: a, hidden: _hidden),
            ],
          ),
        ),
      ],
    );
  }
}