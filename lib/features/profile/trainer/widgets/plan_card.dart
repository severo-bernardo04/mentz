import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Cartão de uma ficha de treino: resumo, conclusão semanal e ações.
class PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = plan;

    return SectionCard(
      title: 'Treino ${p.name}',
      icon: Icons.assignment_outlined,
      trailing: PopupMenuButton<String>(
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.focus.isNotEmpty)
            Text(
              p.focus,
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: '${p.exercises.length} exercícios',
                icon: Icons.fitness_center,
              ),
              StatusChip(
                label: '${p.assignedStudents.length} alunos',
                icon: Icons.group_outlined,
              ),
            ],
          ),
          if (p.assignedStudents.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Conclusão na semana', style: theme.textTheme.labelLarge),
                Text(
                  '${(p.weeklyCompletion * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: p.weeklyCompletion,
                backgroundColor: cs.primary.withAlpha(30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p.assignedStudents.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (p.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(90),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.notes)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar ficha'),
            ),
          ),
        ],
      ),
    );
  }
}