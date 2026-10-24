import 'package:flutter/material.dart';

/// Dropdown sem sublinhado, com cantos arredondados.
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      items: items,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(12),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}