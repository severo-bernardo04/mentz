import 'package:flutter/material.dart';

/// Botão principal com troca animada entre texto e loading.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: AnimatedSwitcher(
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
      ),
    );
  }
}