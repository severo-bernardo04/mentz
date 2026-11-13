import 'package:flutter/material.dart';

import '../../../models/profile_models.dart';

/// Quantidade de séries de Aquecimento, Reconhecimento e Trabalho, cada tipo
/// com a sua cor.
///
/// Na forma padrão é um quadro com o [title] e os três totais em destaque
/// (tela do treino e Detalhes do Treino). Com [compact], vira uma linha
/// discreta, usada dentro do cartão da planilha.
class SetCountSummary extends StatelessWidget {
  final Map<SetType, int> counts;
  final String? title;
  final bool compact;

  const SetCountSummary({
    super.key,
    required this.counts,
    this.title,
    this.compact = false,
  });

  /// Soma das séries de todos os tipos.
  static int totalOf(Map<SetType, int> counts) =>
      counts.values.fold(0, (total, count) => total + count);

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact() : _buildTile(context);
  }

  Widget _buildCompact() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final type in SetType.values)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${counts[type] ?? 0} ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: type.label),
              ],
            ),
            style: TextStyle(fontSize: 11, color: type.color),
          ),
      ],
    );
  }

  Widget _buildTile(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              for (final type in SetType.values)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${counts[type] ?? 0}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: type.color,
                        ),
                      ),
                      // Rótulo sempre em uma linha, reduzindo se faltar espaço
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          type.label,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: type.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
