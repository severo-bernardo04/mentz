import 'package:flutter/material.dart';
import 'package:mentz/core/routes/fade_slide_route.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/features/exercises/exercises_catalog_page.dart';
import 'package:mentz/features/training/controllers/planned_set_draft.dart';
import 'package:mentz/features/training/widgets/planned_set_tile.dart';
import 'package:mentz/features/training/widgets/rest_time_picker.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/app_button.dart';
import 'package:mentz/widgets/app_text_field.dart';

/// Formulário (bottom sheet) para adicionar/editar um exercício.
/// Define o exercício, as séries (tipo e faixa) e o descanso, sem pedir carga.
/// Devolve o [WorkoutExercise] via `Navigator.pop`.
class ExerciseSheet extends StatefulWidget {
  final WorkoutExercise? exercise;

  /// Exige um exercício do catálogo, sem campos para digitar nome e músculo.
  final bool catalogOnly;

  const ExerciseSheet({super.key, this.exercise, this.catalogOnly = false});

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  static const _maxSets = 10;

  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.exercise?.name ?? '');
  late final _muscle =
      TextEditingController(text: widget.exercise?.muscle ?? '');

  /// Uma entrada por série, na ordem de execução. Novo exercício começa com 3.
  late final List<PlannedSetDraft> _sets = [
    if (widget.exercise != null)
      for (final set in widget.exercise!.plannedSets)
        PlannedSetDraft.fromPlanned(set)
    else
      for (var i = 0; i < 3; i++) PlannedSetDraft(range: '10-12'),
  ];

  /// Descanso é só uma sugestão: fica desligado até o usuário pedir.
  late bool _suggestRest = widget.exercise?.restSeconds != null;
  late int _rest = widget.exercise?.restSeconds ?? 60;

  Exercise? _catalogExercise;
  bool _missingCatalogExercise = false;

  @override
  void dispose() {
    _name.dispose();
    _muscle.dispose();
    for (final set in _sets) {
      set.dispose();
    }
    super.dispose();
  }

  /// Ajusta a quantidade de séries: novas copiam a última, e remove-se do fim.
  void _changeSetCount(int count) {
    setState(() {
      if (count > _sets.length) {
        _sets.add(_sets.last.copy());
      } else {
        _sets.removeLast().dispose();
      }
    });
  }

  Future<void> _openCatalog() async {
    final selected = await Navigator.of(context).push<Exercise>(
      fadeSlideRoute(const ExercisesCatalogPage(isSelecting: true)),
    );
    if (!mounted || selected == null) return;

    setState(() {
      _catalogExercise = selected;
      _missingCatalogExercise = false;
      _name.text = selected.name;
      _muscle.text = selected.displayPrimaryMuscle;
    });
  }

  void _submit() {
    final catalog = _catalogExercise ?? widget.exercise?.exercise;
    final isFormValid = _formKey.currentState!.validate();

    if (widget.catalogOnly && catalog == null) {
      setState(() => _missingCatalogExercise = true);
      return;
    }
    if (!isFormValid) return;

    Navigator.of(context).pop(
      WorkoutExercise(
        // Dados fixos vêm do catálogo; séries e descanso são deste treino
        exercise: widget.catalogOnly
            ? catalog!
            : Exercise(
                id: catalog?.id,
                name: _name.text.trim(),
                muscle: _muscle.text.trim(),
                nameEn: catalog?.nameEn,
                primaryMuscle: catalog?.primaryMuscle,
                highActivationMuscles:
                    catalog?.highActivationMuscles ?? const [],
                secondaryMuscles: catalog?.secondaryMuscles ?? const [],
                equipment: catalog?.equipment,
                instructions: catalog?.instructions,
              ),
        plannedSets: [for (final set in _sets) set.toPlannedSet()],
        restSeconds: _suggestRest ? _rest : null,
      ),
    );
  }

  /// Área tocável que abre o catálogo. Depois da escolha, mostra o exercício.
  Widget _buildExercisePicker(ThemeData theme) {
    final cs = theme.colorScheme;
    final selected = _catalogExercise ?? widget.exercise?.exercise;
    final radius = BorderRadius.circular(14);
    final foreground = selected == null
        ? (_missingCatalogExercise ? cs.error : cs.primary)
        : cs.onPrimaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          key: selected == null
              ? null
              : const Key('exercise_sheet_selected_card'),
          color: selected == null
              ? cs.surfaceContainerHighest.withAlpha(90)
              : cs.primaryContainer,
          borderRadius: radius,
          child: InkWell(
            key: const Key('exercise_sheet_choose_from_catalog_button'),
            borderRadius: radius,
            onTap: _openCatalog,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    selected == null ? Icons.search : Icons.check_circle,
                    color: foreground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.name ?? 'Escolher exercício',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                        if (selected != null)
                          Text(
                            selected.displayPrimaryMuscle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected != null)
                    Text('Trocar', style: TextStyle(color: foreground)),
                ],
              ),
            ),
          ),
        ),
        if (selected == null && _missingCatalogExercise)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Selecione um exercício do catálogo.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }

  /// Títulos das colunas da lista de séries.
  Widget _buildSetsHeader(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        const SizedBox(width: PlannedSetTile.numberColumnWidth),
        Expanded(child: Text('Tipo', style: style)),
        const SizedBox(width: 8),
        SizedBox(
          width: PlannedSetTile.repsColumnWidth,
          child: Text('Repetições', textAlign: TextAlign.center, style: style),
        ),
        // Espaço equivalente à coluna do botão de drop set
        const SizedBox(width: 72),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.exercise == null ? 'Novo exercício' : 'Editar exercício',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.catalogOnly)
                _buildExercisePicker(theme)
              else ...[
                OutlinedButton.icon(
                  key: const Key('exercise_sheet_choose_from_catalog_button'),
                  onPressed: _openCatalog,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Selecionar do Catálogo com Anatomia'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _name,
                  label: 'Exercício',
                  icon: Icons.fitness_center,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      Validators.notEmpty(v, 'Informe o exercício.'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _muscle,
                  label: 'Grupo muscular (opcional)',
                  icon: Icons.accessibility_new,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
              const SizedBox(height: 16),
              _SetsStepper(
                value: _sets.length,
                max: _maxSets,
                onChanged: _changeSetCount,
              ),
              const SizedBox(height: 4),
              _buildSetsHeader(theme),
              for (var i = 0; i < _sets.length; i++)
                PlannedSetTile(
                  key: ObjectKey(_sets[i]),
                  index: i,
                  draft: _sets[i],
                  onTypeChanged: (type) =>
                      setState(() => _sets[i].changeType(type)),
                  onDropSetChanged: (value) =>
                      setState(() => _sets[i].isDropSet = value),
                ),
              SwitchListTile(
                key: const Key('rest_switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Sugerir descanso',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: const Text('Opcional'),
                value: _suggestRest,
                onChanged: (value) => setState(() => _suggestRest = value),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _suggestRest
                    ? RestTimePicker(
                        initialSeconds: _rest,
                        onChanged: (seconds) => _rest = seconds,
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 12),
              AppButton(label: 'Confirmar', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetsStepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _SetsStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text('Séries', style: theme.textTheme.titleSmall),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}