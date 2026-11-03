import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Os 7 dias da semana, destacando os dias de treino planejados.
class TrainingWeekRow extends StatelessWidget {
  /// 0 = segunda ... 6 = domingo.
  final List<int> trainingDays;

  const TrainingWeekRow({super.key, required this.trainingDays});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          _DayDot(
            label: weekdayShort[i][0],
            planned: trainingDays.contains(i),
          ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool planned;

  const _DayDot({required this.label, required this.planned});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: planned ? cs.primary : cs.surfaceContainerHighest,
          ),
          child: Icon(
            planned ? Icons.fitness_center : Icons.hotel_outlined,
            size: 17,
            color: planned ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }
}