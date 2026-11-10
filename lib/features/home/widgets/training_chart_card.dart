import 'package:flutter/material.dart';

import '../../../widgets/app_card.dart';

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

  const TrainingChartCard({
    super.key,
    required this.name,
    required this.frequencyLabel,
    required this.dayNames,
    required this.onDayTap,
    this.description,
    this.runningDayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppCard(
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
              Chip(
                label: Text(frequencyLabel, style: const TextStyle(fontSize: 11)),
                backgroundColor: cs.surfaceContainerHighest,
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
                  onTap: () => onDayTap(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dia da planilha; abre o treino ao ser tocado.
class _DayTag extends StatelessWidget {
  final String name;
  final bool running;
  final VoidCallback onTap;

  const _DayTag(this.name, {required this.running, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

    // Material transparente: o InkWell desenha o toque sobre o fundo colorido
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: running ? cs.primary : cs.primary.withAlpha(20),
            borderRadius: radius,
            border: Border.all(color: cs.primary.withAlpha(running ? 255 : 50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (running) ...[
                Icon(Icons.timer_rounded, size: 14, color: cs.onPrimary),
                const SizedBox(width: 4),
              ],
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: running ? cs.onPrimary : cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}