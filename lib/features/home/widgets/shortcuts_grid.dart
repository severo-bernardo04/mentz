import 'package:flutter/material.dart';

import '../../../widgets/fade_slide_in.dart';
import 'shortcut_card.dart';

/// Grade 2x2 de atalhos da home.
class ShortcutsGrid extends StatelessWidget {
  final VoidCallback onNewChart;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  const ShortcutsGrid({
    super.key,
    required this.onNewChart,
    required this.onProfile,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      ShortcutCard(
        icon: Icons.add_task_rounded,
        label: 'Nova Planilha',
        onTap: onNewChart,
      ),
      ShortcutCard(
        icon: Icons.person_outline,
        label: 'Perfil',
        onTap: onProfile,
      ),
      const ShortcutCard(icon: Icons.explore_outlined, label: 'Explorar'),
      ShortcutCard(
        key: const Key('home_settings_shortcut_card'),
        icon: Icons.settings_outlined,
        label: 'Ajustes',
        onTap: onSettings,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        for (var i = 0; i < cards.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 250 + i * 80),
            child: cards[i],
          ),
      ],
    );
  }
}