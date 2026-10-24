import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart' show weekdayShort;
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/widgets/section_card.dart';

/// Escolha entre dias fixos da semana ou ciclo por intervalos.
class FrequencySection extends StatelessWidget {
  final WorkoutFrequencyType type;

  /// 1 = Seg ... 7 = Dom.
  final Set<int> selectedWeekdays;
  final ValueChanged<WorkoutFrequencyType> onTypeChanged;
  final void Function(int weekday, bool selected) onWeekdayToggled;

  const FrequencySection({
    super.key,
    required this.type,
    required this.selectedWeekdays,
    required this.onTypeChanged,
    required this.onWeekdayToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Frequência de Execução',
      icon: Icons.calendar_month_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<WorkoutFrequencyType>(
            key: const Key('frequency_segmented_button'),
            segments: const [
              ButtonSegment(
                value: WorkoutFrequencyType.fixedDays,
                label: Text('Dias Fixos'),
                icon: Icon(Icons.date_range_rounded),
              ),
              ButtonSegment(
                value: WorkoutFrequencyType.intervalDays,
                label: Text('Por Intervalo'),
                icon: Icon(Icons.timelapse_rounded),
              ),
            ],
            selected: {type},
            onSelectionChanged: (set) => onTypeChanged(set.first),
          ),
          const SizedBox(height: 16),
          if (type == WorkoutFrequencyType.fixedDays)
            _WeekdayPicker(
              selected: selectedWeekdays,
              onToggled: onWeekdayToggled,
            )
          else
            const _IntervalHint(),
        ],
      ),
    );
  }
}

TextStyle? _labelStyle(BuildContext context) {
  final theme = Theme.of(context);

  return theme.textTheme.bodyMedium?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w600,
  );
}

class _WeekdayPicker extends StatelessWidget {
  final Set<int> selected;
  final void Function(int weekday, bool selected) onToggled;

  const _WeekdayPicker({required this.selected, required this.onToggled});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dias da semana em que você treina:',
          style: _labelStyle(context),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                key: Key('weekday_chip_$day'),
                label: Text(weekdayShort[day - 1]),
                selected: selected.contains(day),
                onSelected: (value) => onToggled(day, value),
              ),
          ],
        ),
      ],
    );
  }
}

class _IntervalHint extends StatelessWidget {
  const _IntervalHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ciclo por intervalos variáveis:', style: _labelStyle(context)),
        const SizedBox(height: 6),
        Text(
          'Configure os dias de descanso após cada dia de treino logo abaixo.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}