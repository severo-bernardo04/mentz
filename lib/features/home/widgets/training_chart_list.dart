import 'package:flutter/material.dart';

import '../../../models/training_chart.dart';
import '../../../services/training_chart_service.dart';
import '../../../widgets/fade_slide_in.dart';
import 'empty_charts_card.dart';
import 'training_chart_card.dart';

/// Lista de planilhas (atualiza sozinha quando o service notifica).
class TrainingChartList extends StatelessWidget {
  const TrainingChartList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TrainingChartService(),
      builder: (context, _) {
        final charts = TrainingChartService().charts;

        if (charts.isEmpty) {
          return const FadeSlideIn(
            delay: Duration(milliseconds: 200),
            child: EmptyChartsCard(),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < charts.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 200 + i * 60),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TrainingChartCard(
                    name: charts[i].name,
                    description: charts[i].description,
                    frequencyLabel: charts[i].frequencyConfig.type ==
                            WorkoutFrequencyType.fixedDays
                        ? 'Dias Fixos'
                        : 'Intervalo',
                    dayNames: [for (final day in charts[i].days) day.name],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}