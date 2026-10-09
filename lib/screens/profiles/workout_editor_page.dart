// ARQUIVO NOVO — crie em lib/screens/profile/workout_editor_page.dart. Não altera nenhum arquivo existente por si só.
import 'package:flutter/material.dart';

import '../../models/profile_models.dart';
import '../auth_widgets.dart';
import 'profile_widgets.dart';

/// Criação e edição de fichas de treino (uso do treinador).
/// Retorna o [WorkoutPlan] salvo via `Navigator.pop`.
class WorkoutEditorPage extends StatefulWidget {
  final WorkoutPlan? plan;
  final List<String> studentNames;

  const WorkoutEditorPage({super.key, this.plan, required this.studentNames});

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _focusCtrl;
  late final TextEditingController _notesCtrl;

  late final List<Exercise> _exercises;
  late final Set<String> _assigned;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _focusCtrl = TextEditingController(text: p?.focus ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    // cópia profunda: só altera o original ao salvar
    _exercises = [
      for (final e in p?.exercises ?? <Exercise>[])
        Exercise(
          name: e.name,
          muscle: e.muscle,
          sets: e.sets,
          reps: e.reps,
          load: e.load,
          restSeconds: e.restSeconds,
        ),
    ];
    _assigned = {...?p?.assignedStudents};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _editExercise({Exercise? current, int? index}) async {
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExerciseSheet(exercise: current),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _exercises.add(result);
      } else {
        _exercises[index] = result;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um exercício.')),
      );
      return;
    }

    final old = widget.plan;
    final plan = WorkoutPlan(
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      focus: _focusCtrl.text.trim(),
      exercises: _exercises,
      assignedStudents: _assigned.toList(),
      notes: _notesCtrl.text.trim(),
      weeklyCompletion: old?.weeklyCompletion ?? 0,
    );

    // TODO: persistir a ficha no backend (ex: Firestore)
    Navigator.of(context).pop(plan);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar ficha' : 'Nova ficha',
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
        ),
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Salvar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AuthBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  SectionCard(
                    title: 'Identificação',
                    icon: Icons.edit_note,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Dê um nome à ficha (A, B, C...).'
                              : null,
                          decoration: authInputDecoration(
                            context,
                            label: 'Nome da ficha (A, B, C...)',
                            icon: Icons.label_outline,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _focusCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: authInputDecoration(
                            context,
                            label: 'Foco (ex: Peito e tríceps)',
                            icon: Icons.center_focus_strong_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Exercícios',
                    icon: Icons.fitness_center,
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => _editExercise(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar'),
                    ),
                    child: _exercises.isEmpty
                        ? const EmptyHint('Nenhum exercício ainda.')
                        : ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            onReorder: (oldI, newI) => setState(() {
                              if (newI > oldI) newI--;
                              _exercises.insert(
                                  newI, _exercises.removeAt(oldI));
                            }),
                            children: [
                              for (var i = 0; i < _exercises.length; i++)
                                _EditableExerciseTile(
                                  key: ObjectKey(_exercises[i]),
                                  index: i,
                                  exercise: _exercises[i],
                                  onEdit: () => _editExercise(
                                    current: _exercises[i],
                                    index: i,
                                  ),
                                  onDelete: () =>
                                      setState(() => _exercises.removeAt(i)),
                                ),
                            ],
                          ),
                  ),
                  SectionCard(
                    title: 'Alunos desta ficha',
                    icon: Icons.group_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final n in widget.studentNames)
                          FilterChip(
                            label: Text(n),
                            selected: _assigned.contains(n),
                            onSelected: (v) => setState(() {
                              v ? _assigned.add(n) : _assigned.remove(n);
                            }),
                          ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Observações sobre a execução',
                    icon: Icons.sticky_note_2_outlined,
                    child: TextFormField(
                      controller: _notesCtrl,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'Ex: manter a postura na remada, controlar a descida...',
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withAlpha(90),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isEditing ? 'Salvar alterações' : 'Criar ficha'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableExerciseTile extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EditableExerciseTile({
    super.key,
    required this.index,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final e = exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.drag_indicator),
          ),
        ),
        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${e.sets} × ${e.reps}  •  ${e.load}  •  descanso ${e.restLabel}',
        ),
        trailing: IconButton(
          tooltip: 'Remover',
          icon: Icon(Icons.delete_outline, color: cs.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

/// Formulário (bottom sheet) para adicionar/editar um exercício.
class _ExerciseSheet extends StatefulWidget {
  final Exercise? exercise;
  const _ExerciseSheet({this.exercise});

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _muscle;
  late final TextEditingController _reps;
  late final TextEditingController _load;
  late int _sets;
  late int _rest;

  static const _restOptions = [30, 45, 60, 75, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _name = TextEditingController(text: e?.name ?? '');
    _muscle = TextEditingController(text: e?.muscle ?? '');
    _reps = TextEditingController(text: e?.reps ?? '12');
    _load = TextEditingController(text: e?.load ?? '');
    _sets = e?.sets ?? 3;
    _rest = _restOptions.contains(e?.restSeconds) ? e!.restSeconds : 60;
  }

  @override
  void dispose() {
    _name.dispose();
    _muscle.dispose();
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Exercise(
        name: _name.text.trim(),
        muscle: _muscle.text.trim(),
        sets: _sets,
        reps: _reps.text.trim(),
        load: _load.text.trim().isEmpty ? '—' : _load.text.trim(),
        restSeconds: _rest,
      ),
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
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o exercício.'
                    : null,
                decoration: authInputDecoration(
                  context,
                  label: 'Exercício',
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _muscle,
                textCapitalization: TextCapitalization.sentences,
                decoration: authInputDecoration(
                  context,
                  label: 'Grupo muscular (opcional)',
                  icon: Icons.accessibility_new,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _reps,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                      decoration: authInputDecoration(
                        context,
                        label: 'Repetições',
                        icon: Icons.repeat,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _load,
                      decoration: authInputDecoration(
                        context,
                        label: 'Carga inicial',
                        icon: Icons.scale_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Séries', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: _sets > 1 ? () => setState(() => _sets--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$_sets',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _sets < 10 ? () => setState(() => _sets++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Descanso entre séries', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in _restOptions)
                    ChoiceChip(
                      label: Text(r >= 60 && r % 60 == 0 ? '${r ~/ 60} min' : '${r}s'),
                      selected: _rest == r,
                      onSelected: (_) => setState(() => _rest = r),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}