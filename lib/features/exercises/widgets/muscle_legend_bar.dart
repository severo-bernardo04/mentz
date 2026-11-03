import 'package:flutter/material.dart';
import 'muscle_anatomy_painter.dart';

/// Barra de legenda anatômica obrigatória conforme a especificação do Mentz:
/// - Vermelho: músculo principal
/// - Laranja: músculo de alta ativação
/// - Amarelo: músculo secundário
class MuscleLegendBar extends StatelessWidget {
  const MuscleLegendBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LegendItem(
            color: MuscleRole.primary.color,
            label: 'Músculo Principal',
          ),
          _LegendItem(
            color: MuscleRole.highActivation.color,
            label: 'Alta Ativação',
          ),
          _LegendItem(
            color: MuscleRole.secondary.color,
            label: 'Músculo Secundário',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
