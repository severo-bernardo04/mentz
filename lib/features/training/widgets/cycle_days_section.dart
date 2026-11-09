import 'package:flutter/material.dart';
import 'package:mentz/features/training/controllers/day_draft.dart';
import 'package:mentz/features/training/widgets/day_tile.dart';
import 'package:mentz/widgets/section_card.dart';

/// Lista de dias do ciclo. Apenas um dia fica aberto por vez.
class CycleDaysSection extends StatefulWidget {
  final List<DayDraft> days;

  /// Mostra o seletor de descanso em cada dia (frequência por intervalo).
  final bool intervalMode;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(DayDraft day, int value) onRestChanged;
  final ValueChanged<DayDraft> onAddExercise;
  final void Function(DayDraft day, int index) onEditExercise;
  final void Function(DayDraft day, int index) onRemoveExercise;
  final void Function(DayDraft day, int oldIndex, int newIndex) onReorderExercise;

  const CycleDaysSection({
    super.key,
    required this.days,
    required this.intervalMode,
    required this.onAdd,
    required this.onRemove,
    required this.onRestChanged,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onRemoveExercise,
    required this.onReorderExercise,
  });

  @override
  State<CycleDaysSection> createState() => _CycleDaysSectionState();
}

class _CycleDaysSectionState extends State<CycleDaysSection> {
  /// Índice do dia aberto; null quando todos estão fechados.
  int? _expanded = 0;

  void _toggle(int index) {
    setState(() => _expanded = _expanded == index ? null : index);
  }

  /// Adiciona um dia e já o deixa aberto. No limite de dias, nada muda.
  void _addDay() {
    final countBefore = widget.days.length;
    widget.onAdd();
    if (widget.days.length > countBefore) setState(() => _expanded = countBefore);
  }

  /// Remove o dia e volta para o primeiro. O último dia não pode ser removido.
  void _removeDay(int index) {
    final countBefore = widget.days.length;
    widget.onRemove(index);
    if (widget.days.length < countBefore) setState(() => _expanded = 0);
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;

    return SectionCard(
      title: 'Dias do Ciclo (${days.length})',
      icon: Icons.view_timeline_rounded,
      trailing: TextButton.icon(
        key: const Key('add_day_button'),
        onPressed: _addDay,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Adicionar'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < days.length; i++)
            DayTile(
              key: Key('day_item_$i'),
              index: i,
              draft: days[i],
              showRest: widget.intervalMode,
              expanded: _expanded == i,
              onToggle: () => _toggle(i),
              onRemove: () => _removeDay(i),
              onRestChanged: (value) => widget.onRestChanged(days[i], value),
              onAddExercise: () => widget.onAddExercise(days[i]),
              onEditExercise: (index) => widget.onEditExercise(days[i], index),
              onRemoveExercise: (index) =>
                  widget.onRemoveExercise(days[i], index),
              onReorderExercise: (oldIndex, newIndex) =>
                  widget.onReorderExercise(days[i], oldIndex, newIndex),
            ),
        ],
      ),
    );
  }
}
