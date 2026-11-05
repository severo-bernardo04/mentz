import 'package:flutter/material.dart';

/// Cartão com sombra suave (o Material interno permite ink/checkbox/etc).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      );
    }

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
        child: content,
      ),
    );
  }
}
