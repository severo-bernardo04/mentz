import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gráfico de barras simples com animação de entrada.
class SimpleBarChart extends StatelessWidget {
  final List<num> values;
  final List<String> labels;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 130,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxV = values.isEmpty ? 1 : values.reduce(math.max);

    return SizedBox(
      height: height + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${values[i]}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxV == 0 ? 0.0 : values[i] / maxV,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        height: math.max(4.0, height * v),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: i == values.length - 1
                              ? cs.primary
                              : cs.primary.withAlpha(110),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}