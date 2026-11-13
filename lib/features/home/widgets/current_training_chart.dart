import 'package:flutter/material.dart';

import '../../../models/training_chart.dart';
import '../../../services/training_chart_service.dart';
import '../../../services/training_history_service.dart';
import '../../../services/workout_schedule_service.dart';
import '../../../services/workout_session_service.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../workout_session/workout_session_page.dart';
import 'empty_charts_card.dart';
import 'training_chart_card.dart';

/// Planilha atual do usuário na tela inicial (atualiza sozinha quando os
/// services notificam). As demais planilhas ficam no menu de planilhas.
///
/// O próximo treino programado aparece destacado entre os dias; se ele for
/// para hoje, um aviso acima do cartão leva direto ao treino.
class CurrentTrainingChart extends StatelessWidget {
  const CurrentTrainingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TrainingChartService(),
        TrainingHistoryService(),
        WorkoutSessionService(),
      ]),
      builder: (context, _) {
        final service = TrainingChartService();
        final current = service.currentChart;
        final error = service.errorMessage;

        if (service.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (error != null) return ErrorBanner(error);

        if (current == null) {
          return const FadeSlideIn(
            delay: Duration(milliseconds: 200),
            child: EmptyChartsCard(),
          );
        }

        // Próximo treino do ciclo, calculado pelo histórico da planilha
        final next = WorkoutScheduleService.nextWorkout(
          current,
          TrainingHistoryService().sessions,
        );
        // Com um treino em andamento, o aviso de hoje não faz sentido
        final showToday =
            next != null &&
            WorkoutScheduleService.isToday(next.date) &&
            WorkoutSessionService().active == null;

        return FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showToday) ...[
                _TodayWorkoutBanner(chart: current, day: next.day),
                const SizedBox(height: 12),
              ],
              TrainingChartCard.fromChart(
                context,
                current,
                key: const Key('current_chart_card'),
                nextDayId: next?.day.id,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Aviso de que há treino programado para hoje. Tocar abre o treino.
class _TodayWorkoutBanner extends StatelessWidget {
  final TrainingChart chart;
  final TrainingDay day;

  const _TodayWorkoutBanner({required this.chart, required this.day});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);

    return Material(
      color: cs.tertiaryContainer,
      borderRadius: radius,
      child: InkWell(
        key: const Key('today_workout_banner'),
        borderRadius: radius,
        onTap: () => Navigator.of(context).push(
          WorkoutSessionPage.route(chart, day),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.event_available_rounded, color: cs.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treino de hoje',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      day.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
