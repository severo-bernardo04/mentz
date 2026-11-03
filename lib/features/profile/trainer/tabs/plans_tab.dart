import 'package:flutter/material.dart';
import 'package:mentz/features/profile/trainer/widgets/plan_card.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/empty_hint.dart';

/// Aba 3: fichas de treino criadas pelo treinador.
class PlansTab extends StatelessWidget {
  final List<WorkoutPlan> plans;
  final VoidCallback onCreate;
  final ValueChanged<WorkoutPlan> onEdit;
  final ValueChanged<WorkoutPlan> onDelete;

  const PlansTab({
    super.key,
    required this.plans,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _confirmDelete(BuildContext context, WorkoutPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir treino ${p.name}?'),
        content: const Text(
          'A ficha será removida dos alunos associados. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (ok == true) onDelete(p);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileTabPage(
      children: [
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova ficha de treino'),
        ),
        const SizedBox(height: 16),
        if (plans.isEmpty) const EmptyHint('Você ainda não criou nenhuma ficha.'),
        for (final p in plans)
          PlanCard(
            plan: p,
            onEdit: () => onEdit(p),
            onDelete: () => _confirmDelete(context, p),
          ),
      ],
    );
  }
}