import 'package:flutter/material.dart';

/// Cartão com sombra suave (o Material interno permite ink/checkbox/etc).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(235),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}