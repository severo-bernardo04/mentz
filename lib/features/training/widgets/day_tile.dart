import 'package:flutter/material.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/features/training/controllers/day_draft.dart';
import 'package:mentz/features/training/widgets/reorderable_exercise_list.dart';
import 'package:mentz/widgets/app_dropdown.dart';
import 'package:mentz/widgets/app_text_field.dart';

/// Um dia do ciclo em formato de acordeão: fechado mostra só o nome e a
/// quantidade de exercícios; aberto permite editar o dia.
class DayTile extends StatelessWidget {
  final int index;
  final DayDraft draft;
  final bool showRest;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final ValueChanged<int> onRestChanged;
  final VoidCallback onAddExercise;
  final ValueChanged<int> onEditExercise;
  final ValueChanged<int> onRemoveExercise;
  final ReorderCallback onReorderExercise;

  const DayTile({
    super.key,
    required this.index,
    required this.draft,
    required this.showRest,
    required this.expanded,
    required this.onToggle,
    required this.onRemove,
    required this.onRestChanged,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onRemoveExercise,
    required this.onReorderExercise,
  });

  /// Resumo exibido abaixo do nome do dia.
  String get _exercisesSummary => switch (draft.exercises.length) {
    0 => 'Sem exercícios',
    1 => '1 exercício',
    final count => '$count exercícios',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = BorderRadius.circular(16);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: Key('day_header_$index'),
              borderRadius: radius,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _buildHeader(theme),
              ),
            ),
            // Anima a abertura e o fechamento do dia
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: expanded
                  ? _buildBody()
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final cs = theme.colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cs.primary,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Acompanha o nome enquanto ele é digitado
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: draft.nameCtrl,
                builder: (context, value, _) => Text(
                  value.text.trim().isEmpty ? 'Sem nome' : value.text.trim(),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _exercisesSummary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: Key('delete_day_button_$index'),
          tooltip: 'Remover dia',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.delete_outline_rounded, color: cs.error),
          onPressed: onRemove,
        ),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: Key('day_name_field_$index'),
            controller: draft.nameCtrl,
            label: 'Nome do treino',
            textCapitalization: TextCapitalization.characters,
            validator: (v) => Validators.notEmpty(v, 'Nome obrigatório'),
          ),
          if (showRest) ...[
            const SizedBox(height: 8),
            _RestSelector(
              value: draft.restDaysAfter,
              onChanged: onRestChanged,
            ),
          ],
          const SizedBox(height: 12),
          if (draft.exercises.isNotEmpty)
            ReorderableExerciseList(
              exercises: draft.exercises,
              onEdit: onEditExercise,
              onDelete: onRemoveExercise,
              onReorder: onReorderExercise,
            ),
          FilledButton.tonalIcon(
            key: Key('add_exercise_button_$index'),
            onPressed: onAddExercise,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar exercício'),
          ),
        ],
      ),
    );
  }
}

class _RestSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RestSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.bed_rounded, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Descanso após este treino:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppDropdown<int>(
          value: value,
          onChanged: onChanged,
          items: [
            for (final d in const [0, 1, 2, 3, 4])
              DropdownMenuItem(
                value: d,
                child: Text(d == 0 ? 'Sem descanso' : '$d dia${d > 1 ? 's' : ''}'),
              ),
          ],
        ),
      ],
    );
  }
}
