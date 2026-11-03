import 'package:flutter/material.dart';

/// Botão principal com troca animada entre texto e loading.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: loading
          ? const SizedBox(
              key: ValueKey('loading'),
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(
              label,
              key: const ValueKey('label'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );

    final handler = loading ? null : onPressed;

    if (icon == null) {
      return FilledButton(onPressed: handler, style: style, child: content);
    }

    return FilledButton.icon(
      onPressed: handler,
      style: style,
      icon: Icon(icon),
      label: content,
    );
  }
}