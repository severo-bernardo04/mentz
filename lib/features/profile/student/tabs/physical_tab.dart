import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/widgets/assessment_tile.dart';
import 'package:mentz/features/profile/student/widgets/bmi_card.dart';
import 'package:mentz/features/profile/student/widgets/edit_physical_measures_sheet.dart';
import 'package:mentz/features/profile/student/widgets/goal_card.dart';
import 'package:mentz/features/profile/student/widgets/training_week_row.dart';
import 'package:mentz/features/profile/widgets/privacy_banner.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';
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
  late double? _height;
  late double? _weight;
  late DateTime? _birthDate;
  late String? _sex;
  late List<WeightEntry> _weightHistory;

  @override
  void initState() {
    super.initState();
    _height = widget.student.heightCm;
    _weight = widget.student.currentWeight;
    _birthDate = widget.student.birthDate;
    _sex = widget.student.sex;
    _weightHistory = widget.student.weightHistory;
  }

  @override
  void didUpdateWidget(covariant PhysicalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.heightCm != widget.student.heightCm) {
      _height = widget.student.heightCm;
    }
    if (oldWidget.student.currentWeight != widget.student.currentWeight) {
      _weight = widget.student.currentWeight;
      _weightHistory = widget.student.weightHistory;
    }
    if (oldWidget.student.birthDate != widget.student.birthDate) {
      _birthDate = widget.student.birthDate;
    }
    if (oldWidget.student.sex != widget.student.sex) {
      _sex = widget.student.sex;
    }
  }

  String _mask(String v) => _hidden ? '•••' : v;

  Future<void> _openEditMeasures(BuildContext context) async {
    final result = await showEditPhysicalMeasuresSheet(
      context,
      initialHeightCm: _height,
      initialWeightKg: _weight,
      initialBirthDate: _birthDate,
      initialSex: _sex,
      weightHistory: _weightHistory,
    );
    if (result != null && mounted) {
      setState(() {
        _height = result.heightCm;
        if (result.birthDate != null) _birthDate = result.birthDate;
        if (result.sex != null) _sex = result.sex;
        if (result.weightKg != null) {
          _weight = result.weightKg;
          _weightHistory = [
            ..._weightHistory,
            WeightEntry(DateTime.now(), result.weightKg!),
          ];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.student;

    final height = _height;
    final weight = _weight;
    final delta = weight == null || _weightHistory.isEmpty
        ? null
        : weight - _weightHistory.first.kg;
    final deltaText = delta == null
        ? ''
        : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';

    // Treinos realizados nos últimos 7 dias, a partir do histórico real
    final doneThisWeek = TrainingHistoryService().sessions
        .where((h) => DateTime.now().difference(h.date).inDays < 7)
        .length;
    final target = s.weeklyTarget;

    return ProfileTabPage(
      children: [
        PrivacyBanner(
          text: widget.isOwnerView ? _ownerText : _trainerText,
          hidden: _hidden,
          onToggle: () => setState(() => _hidden = !_hidden),
        ),
        BmiCard(
          heightCm: height,
          weightKg: weight,
          birthDate: _birthDate,
          sex: _sex,
          hidden: _hidden,
          isOwnerView: widget.isOwnerView,
          onEdit: widget.isOwnerView ? () => _openEditMeasures(context) : null,
        ),
        GoalCard(student: s, hidden: _hidden),
        SectionCard(
          title: 'Frequência semanal',
          icon: Icons.calendar_view_week_outlined,
          trailing: Text(
            target == null
                ? '$doneThisWeek treinos'
                : '$doneThisWeek/$target treinos',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: s.trainingDays.isEmpty
              ? const EmptyHint('Nenhum dia de treino definido.')
              : TrainingWeekRow(trainingDays: s.trainingDays),
        ),
        SectionCard(
          title: 'Histórico de peso',
          icon: Icons.show_chart,
          trailing: delta == null
              ? null
              : StatusChip(
                  label: _mask(deltaText),
                  icon: delta <= 0 ? Icons.trending_down : Icons.trending_up,
                ),
          child: _weightHistory.isEmpty
              ? const EmptyHint('Nenhum peso registrado.')
              : _hidden
              ? const EmptyHint('Valores ocultos')
              : SimpleLineChart(
                  values: [for (final w in _weightHistory) w.kg],
                  labels: [
                    for (final w in _weightHistory) formatShort(w.date),
                  ],
                  unit: ' kg',
                ),
        ),
        SectionCard(
          title: 'Avaliações físicas',
          icon: Icons.assignment_outlined,
          child: s.assessments.isEmpty
              ? const EmptyHint('Nenhuma avaliação registrada.')
              : Column(
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