import 'package:flutter/material.dart';

/// Texto centralizado para estados vazios.
class EmptyHint extends StatelessWidget {
  final String text;

  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
      ),
    );
  }
}