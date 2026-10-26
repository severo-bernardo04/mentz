import 'package:flutter/material.dart';
import 'package:mentz/core/utils/validators.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/app_button.dart';
import 'package:mentz/widgets/app_text_field.dart';

/// Formulário (bottom sheet) para adicionar/editar um exercício.
/// Devolve o [Exercise] via `Navigator.pop`.
class ExerciseSheet extends StatefulWidget {
  final Exercise? exercise;

  const ExerciseSheet({super.key, this.exercise});

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  static const _restOptions = [30, 45, 60, 75, 90, 120, 180];

  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.exercise?.name ?? '');
  late final _muscle =
      TextEditingController(text: widget.exercise?.muscle ?? '');
  late final _reps = TextEditingController(text: widget.exercise?.reps ?? '12');
  late final _load = TextEditingController(text: widget.exercise?.load ?? '');

  late int _sets = widget.exercise?.sets ?? 3;
  late int _rest = _restOptions.contains(widget.exercise?.restSeconds)
      ? widget.exercise!.restSeconds
      : 60;

  @override
  void dispose() {
    _name.dispose();
    _muscle.dispose();
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  String _restLabel(int seconds) =>
      seconds >= 60 && seconds % 60 == 0 ? '${seconds ~/ 60} min' : '${seconds}s';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final load = _load.text.trim();

    Navigator.of(context).pop(
      Exercise(
        name: _name.text.trim(),
        muscle: _muscle.text.trim(),
        sets: _sets,
        reps: _reps.text.trim(),
        load: load.isEmpty ? '—' : load,
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _name,
                label: 'Exercício',
                icon: Icons.fitness_center,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.notEmpty(v, 'Informe o exercício.'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _muscle,
                label: 'Grupo muscular (opcional)',
                icon: Icons.accessibility_new,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _reps,
                      label: 'Repetições',
                      icon: Icons.repeat,
                      validator: (v) => Validators.notEmpty(v, 'Obrigatório'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _load,
                      label: 'Carga inicial',
                      icon: Icons.scale_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SetsStepper(
                value: _sets,
                onChanged: (v) => setState(() => _sets = v),
              ),
              const SizedBox(height: 12),
              Text('Descanso entre séries', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final seconds in _restOptions)
                    ChoiceChip(
                      label: Text(_restLabel(seconds)),
                      selected: _rest == seconds,
                      onSelected: (_) => setState(() => _rest = seconds),
                    ),
                ],
              ),
              const SizedBox(height: 20),
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
  final ValueChanged<int> onChanged;

  const _SetsStepper({required this.value, required this.onChanged});

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
          onPressed: value < 10 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}