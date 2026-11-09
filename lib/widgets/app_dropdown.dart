import 'package:flutter/material.dart';

/// Dropdown sem sublinhado, com cantos arredondados.
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  /// Faz o dropdown ocupar toda a largura disponível.
  final bool isExpanded;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      items: items,
      isExpanded: isExpanded,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(12),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}