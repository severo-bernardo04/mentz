import 'package:flutter/material.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/features/training/controllers/day_draft.dart';
import 'package:mentz/widgets/app_dropdown.dart';
import 'package:mentz/widgets/app_text_field.dart';

/// Um dia do ciclo: nome, foco e (opcional) dias de descanso depois dele.
class DayTile extends StatelessWidget {
  final int index;
  final DayDraft draft;
  final bool showRest;
  final VoidCallback onRemove;
  final ValueChanged<int> onRestChanged;

  const DayTile({
    super.key,
    required this.index,
    required this.draft,
    required this.showRest,
    required this.onRemove,
    required this.onRestChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dia ${index + 1} do ciclo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: Key('delete_day_button_$index'),
                tooltip: 'Remover dia',
                icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            key: Key('day_name_field_$index'),
            controller: draft.nameCtrl,
            label: 'Nome do dia (ex: TREINO A, FULL BODY 1)',
            icon: Icons.label_outline_rounded,
            textCapitalization: TextCapitalization.characters,
            validator: (v) => Validators.notEmpty(v, 'Nome obrigatório'),
          ),
          const SizedBox(height: 8),
          AppTextField(
            key: Key('day_focus_field_$index'),
            controller: draft.focusCtrl,
            label: 'Foco muscular ou observações (opcional)',
            icon: Icons.flag_outlined,
            textCapitalization: TextCapitalization.sentences,
          ),
          if (showRest) ...[
            const SizedBox(height: 12),
            _RestSelector(value: draft.restDaysAfter, onChanged: onRestChanged),
          ],
        ],
      ),
    );
  }
}

class _RestSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RestSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.bed_rounded, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Descanso após este treino:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppDropdown<int>(
          value: value,
          onChanged: onChanged,
          items: [
            for (final d in const [0, 1, 2, 3, 4])
              DropdownMenuItem(
                value: d,
                child: Text(d == 0 ? 'Sem descanso (0d)' : '$d dia${d > 1 ? 's' : ''}'),
              ),
          ],
        ),
      ],
    );
  }
}