import 'package:flutter/material.dart';
import 'package:mentz/features/training/controllers/day_draft.dart';
import 'package:mentz/features/training/widgets/day_tile.dart';
import 'package:mentz/widgets/section_card.dart';

/// Lista de dias do ciclo, com botão para adicionar.
class CycleDaysSection extends StatelessWidget {
  final List<DayDraft> days;

  /// Mostra o seletor de descanso em cada dia (frequência por intervalo).
  final bool intervalMode;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(DayDraft day, int value) onRestChanged;

  const CycleDaysSection({
    super.key,
    required this.days,
    required this.intervalMode,
    required this.onAdd,
    required this.onRemove,
    required this.onRestChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Dias do Ciclo (${days.length})',
      icon: Icons.view_timeline_rounded,
      trailing: TextButton.icon(
        key: const Key('add_day_button'),
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Adicionar'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Defina a sequência de treinos (ex: TREINO A, TREINO B).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < days.length; i++)
            DayTile(
              key: Key('day_item_$i'),
              index: i,
              draft: days[i],
              showRest: intervalMode,
              onRemove: () => onRemove(i),
              onRestChanged: (value) => onRestChanged(days[i], value),
            ),
        ],
      ),
    );
  }
}