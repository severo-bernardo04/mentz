import 'package:flutter/material.dart';

import '../../../core/routes/fade_slide_route.dart';
import '../../../models/training_chart.dart';
import '../../../services/training_chart_service.dart';
import '../../../services/workout_session_service.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../workout_session/workout_session_page.dart';
import 'empty_charts_card.dart';
import 'training_chart_card.dart';

/// Lista de planilhas (atualiza sozinha quando os services notificam).
/// Tocar em um dia abre a tela do treino daquele dia.
class TrainingChartList extends StatelessWidget {
  const TrainingChartList({super.key});

  /// Posição do dia de [chart] com treino em andamento, se houver.
  static int? _runningDayIndex(TrainingChart chart) {
    final active = WorkoutSessionService().active;
    if (active == null || active.chartId != chart.id) return null;

    final index = chart.days.indexWhere((d) => d.id == active.dayId);
    return index < 0 ? null : index;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TrainingChartService(),
        WorkoutSessionService(),
      ]),
      builder: (context, _) {
        final service = TrainingChartService();
        final charts = service.charts;
        final error = service.errorMessage;

        if (service.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (error != null) return ErrorBanner(error);

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
                    runningDayIndex: _runningDayIndex(charts[i]),
                    onDayTap: (dayIndex) => context.pushFade(
                      WorkoutSessionPage(
                        chart: charts[i],
                        day: charts[i].days[dayIndex],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}