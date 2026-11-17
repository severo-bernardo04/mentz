import 'package:flutter/material.dart';

import '../../../core/utils/duration_format.dart';
import '../../../models/profile_models.dart';

/// Cartão do cronômetro: tempo decorrido (HH:MM:SS), estado de pausa e data
/// de início do treino.
class SessionTimerCard extends StatelessWidget {
  final Duration elapsed;

  /// Início do treino; null enquanto ele não foi iniciado.
  final DateTime? startedAt;

  /// Cronômetro pausado: o tempo fica parado e o cartão avisa.
  final bool paused;

  const SessionTimerCard({
    super.key,
    required this.elapsed,
    required this.startedAt,
    this.paused = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final started = startedAt;
    final running = started != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: paused
            ? cs.secondaryContainer
            : running
            ? cs.primaryContainer
            : cs.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            formatStopwatchHms(elapsed),
            key: const Key('session_timer_text'),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: paused
                  ? cs.onSecondaryContainer
                  : running
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
              // Números de largura fixa: o texto não "pula" a cada segundo
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          if (paused) ...[
            Row(
              key: const Key('session_timer_paused'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pause_circle_rounded,
                  size: 18,
                  color: cs.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Treino pausado',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text(
            running
                ? 'Iniciado em ${formatDate(started)} (${weekdayFull[started.weekday - 1]}) '
                'às ${_formatTime(started)}'
                : 'Toque em INICIAR quando começar o treino',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: paused
                  ? cs.onSecondaryContainer
                  : running
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}