import 'package:flutter/material.dart';

import '../../../widgets/app_card.dart';

/// Cartão de uma planilha: nome, descrição, tipo de frequência e dias.
class TrainingChartCard extends StatelessWidget {
  final String name;
  final String? description;
  final String frequencyLabel;
  final List<String> dayNames;

  const TrainingChartCard({
    super.key,
    required this.name,
    required this.frequencyLabel,
    required this.dayNames,
    this.description,
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
            children: [for (final day in dayNames) _DayTag(day)],
          ),
        ],
      ),
    );
  }
}

class _DayTag extends StatelessWidget {
  final String name;

  const _DayTag(this.name);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withAlpha(50)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}