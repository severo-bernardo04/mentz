import 'package:flutter/material.dart';

import '../../../models/profile_models.dart';
import '../../../services/exercise_catalog_service.dart';
import '../../../services/muscle_evolution_service.dart';
import '../../../services/training_chart_service.dart';
import '../../../services/training_history_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/empty_hint.dart';
import '../../../widgets/simple_line_chart.dart';

/// Gráfico da evolução muscular da planilha atual, na tela inicial.
///
/// Mostra a variação da 1RM estimada desde o primeiro treino. O usuário
/// alterna entre a visão geral e um grupamento, e toca no gráfico para ver
/// o valor de cada treino. Ao trocar a planilha atual, o gráfico passa a
/// mostrar a evolução dela.
class MuscleEvolutionChart extends StatefulWidget {
  const MuscleEvolutionChart({super.key});

  @override
  State<MuscleEvolutionChart> createState() => _MuscleEvolutionChartState();
}

class _MuscleEvolutionChartState extends State<MuscleEvolutionChart> {
  static const _overall = 'Visão geral';

  /// Grupamento escolhido, ou [_overall].
  String _selected = _overall;

  /// Ex: "+12,5%" ou "-3,0%".
  static String _formatPercent(double value) {
    final text = value.abs().toStringAsFixed(1).replaceAll('.', ',');
    return '${value < 0 ? '-' : '+'}$text%';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TrainingChartService(),
        TrainingHistoryService(),
        ExerciseCatalogService(),
      ]),
      builder: (context, _) {
        final chart = TrainingChartService().currentChart;
        final evolution = chart == null
            ? const MuscleEvolution()
            : MuscleEvolutionService.evolutionOf(
                chart.id,
                TrainingHistoryService().sessions,
                findExercise: ExerciseCatalogService().findById,
              );

        return AppCard(
          padding: const EdgeInsets.all(18),
          child: evolution.hasData
              ? _buildChart(context, chart!.name, evolution)
              : EmptyHint(
                  chart == null
                      ? 'Crie uma planilha para acompanhar sua evolução.'
                      : 'Registre ao menos dois treinos de "${chart.name}" '
                            'para ver a evolução.',
                ),
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    String chartName,
    MuscleEvolution evolution,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final groups = evolution.groups;

    // A planilha atual pode ter mudado e não ter o grupamento escolhido
    final selected = groups.contains(_selected) ? _selected : _overall;
    final points = selected == _overall
        ? evolution.overall
        : evolution.byGroup[selected]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                chartName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppDropdown<String>(
              key: const Key('evolution_group_dropdown'),
              value: selected,
              onChanged: (value) => setState(() => _selected = value),
              items: [
                for (final option in [_overall, ...groups])
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (points.length < 2)
          const EmptyHint('Ainda há só um treino para este grupamento.')
        else
          SimpleLineChart(
            key: ValueKey(selected),
            interactive: true,
            values: [for (final p in points) p.percent],
            valueFormatter: _formatPercent,
            pointLabels: [for (final p in points) formatShort(p.date)],
            labels: [formatShort(points.first.date), formatShort(points.last.date)],
          ),
        const SizedBox(height: 8),
        Text(
          'Variação da 1RM estimada desde o primeiro treino. '
          'Toque no gráfico para ver cada treino.',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
