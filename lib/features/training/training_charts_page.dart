import 'package:flutter/material.dart';

import '../../core/routes/fade_slide_route.dart';
import '../../core/utils/snackbars.dart';
import '../../models/training_chart.dart';
import '../../services/training_chart_service.dart';
import '../../services/workout_session_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/empty_hint.dart';
import '../../widgets/error_banner.dart';
import '../home/widgets/training_chart_card.dart';
import 'create_training_chart_page.dart';

/// Menu de planilhas: lista todas as planilhas do usuário, destaca a atual
/// e permite escolher outra como atual. A tela inicial, o próximo treino e o
/// gráfico de evolução seguem a planilha atual.
class TrainingChartsPage extends StatelessWidget {
  const TrainingChartsPage({super.key});

  Future<void> _select(BuildContext context, TrainingChart chart) async {
    try {
      await TrainingChartService().selectChart(chart.id);
      if (context.mounted) {
        context.showSnack('"${chart.name}" agora é a planilha atual.');
      }
    } catch (_) {
      if (context.mounted) {
        context.showSnack('Não foi possível trocar a planilha atual.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Minhas Planilhas',
      actions: [
        IconButton(
          tooltip: 'Nova planilha',
          icon: const Icon(Icons.add_rounded),
          onPressed: () => context.pushFade(const CreateTrainingChartPage()),
        ),
      ],
      child: ListenableBuilder(
        listenable: Listenable.merge([
          TrainingChartService(),
          WorkoutSessionService(),
        ]),
        builder: (context, _) {
          final service = TrainingChartService();
          final charts = service.charts;
          final current = service.currentChart;
          final error = service.errorMessage;

          if (service.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (error != null) return ErrorBanner(error);
          if (charts.isEmpty) {
            return const EmptyHint('Nenhuma planilha cadastrada ainda.');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final chart in charts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TrainingChartCard.fromChart(
                    context,
                    chart,
                    key: Key('chart_card_${chart.id}'),
                    isCurrent: chart.id == current?.id,
                    onSelect: chart.id == current?.id
                        ? null
                        : () => _select(context, chart),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
