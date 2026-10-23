import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Avaliação física expansível (data, peso, % de gordura e observações).
class AssessmentTile extends StatelessWidget {
  final Assessment assessment;
  final bool hidden;

  const AssessmentTile({
    super.key,
    required this.assessment,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = assessment;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        formatDate(a.date),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        hidden
            ? '•••'
            : '${a.weight.toStringAsFixed(1)} kg  •  '
                '${a.bodyFat.toStringAsFixed(1)}% gordura',
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            a.notes,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}