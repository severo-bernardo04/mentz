import 'package:flutter/material.dart';

import '../../../widgets/fade_slide_in.dart';
import 'shortcut_card.dart';

/// Atalhos rápidos da home: Nova Planilha e Histórico.
class ShortcutsGrid extends StatelessWidget {
  final VoidCallback onNewChart;
  final VoidCallback? onHistory;

  const ShortcutsGrid({
    super.key,
    required this.onNewChart,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      ShortcutCard(
        key: const Key('home_new_chart_shortcut_card'),
        icon: Icons.add_task_rounded,
        label: 'Nova Planilha',
        onTap: onNewChart,
      ),
      ShortcutCard(
        key: const Key('home_history_shortcut_card'),
        icon: Icons.history_rounded,
        label: 'Histórico',
        onTap: onHistory,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: FadeSlideIn(
              delay: Duration(milliseconds: 250 + i * 80),
              child: SizedBox(
                height: 104,
                child: cards[i],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
