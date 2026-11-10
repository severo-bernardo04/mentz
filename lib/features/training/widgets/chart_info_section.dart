import 'package:flutter/material.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/widgets/app_text_field.dart';
import 'package:mentz/widgets/section_card.dart';

/// Nome da planilha.
class ChartInfoSection extends StatelessWidget {
  final TextEditingController nameCtrl;

  const ChartInfoSection({super.key, required this.nameCtrl});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Nome da Planilha',
      icon: Icons.assignment_outlined,
      child: AppTextField(
        key: const Key('chart_name_field'),
        controller: nameCtrl,
        textCapitalization: TextCapitalization.sentences,
        validator: (v) {
          final emptyError = Validators.notEmpty(v, 'Informe o nome da planilha.');
          if (emptyError != null) return emptyError;

          return v!.trim().length > TrainingChart.maxNameLength
              ? 'Use no máximo ${TrainingChart.maxNameLength} caracteres.'
              : null;
        },
      ),
    );
  }
}