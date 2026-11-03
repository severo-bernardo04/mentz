import 'package:flutter/material.dart';
import 'package:mentz/widgets/section_card.dart';

/// Escolha dos alunos que recebem esta ficha.
class AssignedStudentsSection extends StatelessWidget {
  final List<String> studentNames;
  final Set<String> assigned;
  final void Function(String name, bool selected) onToggle;

  const AssignedStudentsSection({
    super.key,
    required this.studentNames,
    required this.assigned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Alunos desta ficha',
      icon: Icons.group_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final name in studentNames)
            FilterChip(
              label: Text(name),
              selected: assigned.contains(name),
              onSelected: (value) => onToggle(name, value),
            ),
        ],
      ),
    );
  }
}