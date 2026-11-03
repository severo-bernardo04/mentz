import 'package:flutter/material.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/widgets/app_text_field.dart';
import 'package:mentz/widgets/section_card.dart';

/// Nome e descrição da planilha.
class ChartInfoSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;

  const ChartInfoSection({
    super.key,
    required this.nameCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Dados da Planilha',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          AppTextField(
            key: const Key('chart_name_field'),
            controller: nameCtrl,
            label: 'Nome da planilha',
            icon: Icons.fitness_center_rounded,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => Validators.notEmpty(v, 'Informe o nome da planilha.'),
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('chart_desc_field'),
            controller: descCtrl,
            label: 'Objetivo ou descrição (opcional)',
            icon: Icons.notes_rounded,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}