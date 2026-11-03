import 'package:flutter/material.dart';

import 'fade_slide_in.dart';

/// Coluna cujos filhos aparecem em cascata (fade + deslize), já com espaçamento.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final Duration startDelay;
  final Duration step;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.spacing = 16,
    this.startDelay = const Duration(milliseconds: 250),
    this.step = const Duration(milliseconds: 80),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          FadeSlideIn(delay: startDelay + step * i, child: children[i]),
        ],
      ],
    );
  }
}