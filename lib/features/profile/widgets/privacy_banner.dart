import 'package:flutter/material.dart';

/// Aviso de privacidade para dados sensíveis, com botão de ocultar valores.
class PrivacyBanner extends StatelessWidget {
  final String text;
  final bool hidden;
  final VoidCallback? onToggle;

  const PrivacyBanner({
    super.key,
    required this.text,
    this.hidden = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: cs.onTertiaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onTertiaryContainer,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
          if (onToggle != null)
            IconButton(
              tooltip: hidden ? 'Mostrar valores' : 'Ocultar valores',
              onPressed: onToggle,
              icon: Icon(
                hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: cs.onTertiaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}