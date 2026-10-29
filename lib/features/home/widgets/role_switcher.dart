import 'package:flutter/material.dart';

import '../../../models/profile_models.dart';

/// TODO: remover — apenas para testar os dois perfis (aluno/treinador).
class RoleSwitcher extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  const RoleSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: UserRole.student,
          icon: Icon(Icons.person_outline),
          label: Text('Aluno'),
        ),
        ButtonSegment(
          value: UserRole.trainer,
          icon: Icon(Icons.sports_gymnastics),
          label: Text('Treinador'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}