import 'package:flutter/material.dart';

enum BadgeTone { primary, secondary, tertiary }

/// Ícone dentro de um círculo colorido.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final BadgeTone tone;

  const IconBadge({super.key, required this.icon, this.tone = BadgeTone.primary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (background, foreground) = switch (tone) {
      BadgeTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      BadgeTone.secondary => (cs.secondaryContainer, cs.onSecondaryContainer),
      BadgeTone.tertiary => (cs.tertiaryContainer, cs.onTertiaryContainer),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 20),
    );
  }
}