import 'package:flutter/material.dart';

import '../../../widgets/app_card.dart';

/// Estado vazio da lista de planilhas.
class EmptyChartsCard extends StatelessWidget {
  const EmptyChartsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center_outlined, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                'Nenhuma planilha cadastrada ainda.',
                style: TextStyle(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}