  import 'package:flutter/material.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/widgets/app_text_field.dart';
import 'package:mentz/widgets/section_card.dart';

/// Nome e foco da ficha.
class PlanIdentitySection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController focusCtrl;

  const PlanIdentitySection({
    super.key,
    required this.nameCtrl,
    required this.focusCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Identificação',
      icon: Icons.edit_note,
      child: Column(
        children: [
          AppTextField(
            controller: nameCtrl,
            label: 'Nome da ficha (A, B, C...)',
            icon: Icons.label_outline,
            textCapitalization: TextCapitalization.characters,
            validator: (v) =>
                Validators.notEmpty(v, 'Dê um nome à ficha (A, B, C...).'),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: focusCtrl,
            label: 'Foco (ex: Peito e tríceps)',
            icon: Icons.center_focus_strong_outlined,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}