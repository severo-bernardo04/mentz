import 'package:flutter/material.dart';
import 'package:mentz/widgets/app_text_field.dart';
import 'package:mentz/widgets/section_card.dart';

/// Observações sobre a execução da ficha.
class PlanNotesSection extends StatelessWidget {
  final TextEditingController controller;

  const PlanNotesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Observações sobre a execução',
      icon: Icons.sticky_note_2_outlined,
      child: AppTextField(
        controller: controller,
        hint: 'Ex: manter a postura na remada, controlar a descida...',
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}