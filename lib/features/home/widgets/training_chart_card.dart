import 'package:flutter/material.dart';

import '../../../core/routes/fade_slide_route.dart';
import '../../../core/utils/snackbars.dart';
import '../../../models/training_chart.dart';
import '../../../services/workout_session_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';
import '../../training/create_training_chart_page.dart';
import '../../workout_session/workout_session_page.dart';

/// Cartão de uma planilha: nome, descrição, tipo de frequência e dias.
/// Tocar em um dia chama [onDayTap] com a posição dele em [dayNames].
class TrainingChartCard extends StatelessWidget {
  final String name;
  final String? description;
  final String frequencyLabel;
  final List<String> dayNames;
  final ValueChanged<int> onDayTap;

  /// Posição do dia com treino em andamento, destacado com um cronômetro.
  final int? runningDayIndex;

  /// Posição do próximo treino programado, destacado em outra cor.
  final int? nextDayIndex;

  /// Destaca o cartão como a planilha atual (usado no menu de planilhas).
  final bool isCurrent;

  /// Quando informado, mostra o botão para tornar esta a planilha atual.
  final VoidCallback? onSelect;

  /// Quando informado, mostra o botão de editar a planilha.
  final VoidCallback? onEdit;

  const TrainingChartCard({
    super.key,
    required this.name,
    required this.frequencyLabel,
    required this.dayNames,
    required this.onDayTap,
    this.description,
    this.runningDayIndex,
    this.nextDayIndex,
    this.isCurrent = false,
    this.onSelect,
    this.onEdit,
  });

  /// Monta o cartão a partir de [chart]: tocar em um dia abre o treino, e o
  /// dia com treino em andamento aparece destacado. Com [nextDayId], o
  /// próximo treino programado também ganha destaque.
  factory TrainingChartCard.fromChart(
    BuildContext context,
    TrainingChart chart, {
    Key? key,
    String? nextDayId,
    bool isCurrent = false,
    VoidCallback? onSelect,
  }) {
    final runningDayId = WorkoutSessionService().runningDayIdIn(chart.id);
    final runningIndex = chart.days.indexWhere((d) => d.id == runningDayId);
    final nextIndex = chart.days.indexWhere((d) => d.id == nextDayId);

    return TrainingChartCard(
      key: key,
      name: chart.name,
      description: chart.description,
      frequencyLabel:
          chart.frequencyConfig.type == WorkoutFrequencyType.fixedDays
          ? 'Dias Fixos'
          : 'Intervalo',
      dayNames: [for (final day in chart.days) day.name],
      runningDayIndex: runningIndex < 0 ? null : runningIndex,
      nextDayIndex: nextIndex < 0 ? null : nextIndex,
      isCurrent: isCurrent,
      onSelect: onSelect,
      onEdit: () {
        // Editar com um treino rodando deixaria as séries já registradas
        // fora de sincronia com os exercícios da planilha
        if (runningDayId != null) {
          context.showSnack(
            'Finalize o treino em andamento antes de editar a planilha.',
          );
          return;
        }
        context.pushFade(CreateTrainingChartPage(chart: chart));
      },
      onDayTap: (index) => Navigator.of(context).push(
        WorkoutSessionPage.route(chart, chart.days[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      // Contorno na cor principal para a planilha atual
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isCurrent ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.table_chart_rounded,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrent)
                  StatusChip(
                    label: 'Atual',
                    icon: Icons.check_circle,
                    color: cs.primary,
                  )
                else
                  StatusChip(label: frequencyLabel),
                if (onEdit != null)
                  IconButton(
                    key: const Key('edit_chart_button'),
                    tooltip: 'Editar planilha',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < dayNames.length; i++)
                  _DayTag(
                    dayNames[i],
                    running: i == runningDayIndex,
                    next: i == nextDayIndex,
                    onTap: () => onDayTap(i),
                  ),
              ],
            ),
            if (onSelect != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Definir como atual'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dia da planilha; abre o treino ao ser tocado. Três aparências:
/// em andamento (preenchido na cor principal, com cronômetro), próximo
/// treino programado (cor terciária, com calendário) e normal.
class _DayTag extends StatelessWidget {
  final String name;
  final bool running;
  final bool next;
  final VoidCallback onTap;

  const _DayTag(
    this.name, {
    required this.running,
    required this.next,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

    // O treino em andamento tem prioridade sobre o destaque de próximo
    final highlightNext = next && !running;
    final background = running
        ? cs.primary
        : highlightNext
        ? cs.tertiaryContainer
        : cs.primary.withAlpha(20);
    final foreground = running
        ? cs.onPrimary
        : highlightNext
        ? cs.onTertiaryContainer
        : cs.primary;
    final border = running
        ? cs.primary
        : highlightNext
        ? cs.tertiary
        : cs.primary.withAlpha(50);

    // Material transparente: o InkWell desenha o toque sobre o fundo colorido
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          key: highlightNext ? const Key('next_day_tag') : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: Border.all(color: border, width: highlightNext ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (running || highlightNext) ...[
                Icon(
                  running ? Icons.timer_rounded : Icons.event_rounded,
                  size: 14,
                  color: foreground,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlightNext ? FontWeight.w800 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
