import 'package:flutter/material.dart';

/// Etiqueta arredondada com ícone opcional. `color == null` = neutro.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const StatusChip({super.key, required this.label, this.icon, this.color});

  /// Atalho verde/vermelho para estados ativo/inativo.
  factory StatusChip.active(
    bool active, {
    String? activeLabel,
    String? inactiveLabel,
  }) {
    return StatusChip(
      label: active ? (activeLabel ?? 'Ativa') : (inactiveLabel ?? 'Inativa'),
      icon: active ? Icons.check_circle : Icons.pause_circle,
      color: active ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSecondaryContainer;
    final bg = color != null ? color!.withAlpha(30) : cs.secondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}