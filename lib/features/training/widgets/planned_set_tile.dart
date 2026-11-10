import 'package:flutter/material.dart';
import 'package:mentz/features/training/controllers/planned_set_draft.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/app_dropdown.dart';
import 'package:mentz/widgets/app_text_field.dart';

/// Uma série do exercício em uma única linha: número, tipo, faixa e drop set.
class PlannedSetTile extends StatelessWidget {
  /// Largura da coluna de repetições, usada também no título da lista.
  static const repsColumnWidth = 84.0;

  /// Largura da coluna do número da série, usada também no título da lista.
  static const numberColumnWidth = 24.0;

  final int index;
  final PlannedSetDraft draft;
  final ValueChanged<SetType> onTypeChanged;
  final ValueChanged<bool> onDropSetChanged;

  const PlannedSetTile({
    super.key,
    required this.index,
    required this.draft,
    required this.onTypeChanged,
    required this.onDropSetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Número da série na cor do tipo escolhido
          SizedBox(
            width: numberColumnWidth,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: draft.type.color,
              ),
            ),
          ),
          Expanded(
            child: AppDropdown<SetType>(
              key: Key('set_type_dropdown_$index'),
              value: draft.type,
              isExpanded: true,
              onChanged: onTypeChanged,
              items: [
                for (final type in SetType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: type.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: repsColumnWidth,
            child: TextFormField(
              key: Key('set_range_field_$index'),
              controller: draft.rangeCtrl,
              textAlign: TextAlign.center,
              // Teclado numérico com o sinal de "-" para digitar a faixa
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: appInputDecoration(context).copyWith(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
              ),
              // Reconhecimento aceita também um valor único (ex: 2)
              validator: (v) =>
                  PlannedSet.tryParse(v ?? '', type: draft.type) == null
                  ? 'Ex: 8-10'
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // Fica desabilitado nas séries de Reconhecimento
          FilterChip(
            key: Key('set_drop_chip_$index'),
            label: const Text('Drop'),
            tooltip: dropSetLabel,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selected: draft.isDropSet,
            selectedColor: dropSetColor.withAlpha(70),
            onSelected: draft.allowsDropSet ? onDropSetChanged : null,
          ),
        ],
      ),
    );
  }
}
