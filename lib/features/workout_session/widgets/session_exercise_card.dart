import 'package:flutter/material.dart';

import '../../../core/utils/snackbars.dart';
import '../../../models/profile_models.dart';
import '../../../widgets/half_step_field.dart';

/// Exercício da tela do treino.
///
/// Antes de iniciar, mostra as séries planejadas. Com o treino em andamento
/// ([executed] preenchido), permite informar carga e repetições de cada série,
/// marcar o exercício como feito e colore as repetições conforme a faixa.
/// Os campos vazios mostram, como dica, os valores do último treino.
class SessionExerciseCard extends StatelessWidget {
  final int index;

  /// Exercício planejado; pode faltar ao completar um treino anterior cujo
  /// exercício saiu da planilha.
  final WorkoutExercise? planned;

  /// Valores registrados; null enquanto o treino não foi iniciado.
  final ExecutedExercise? executed;
  final ValueChanged<ExecutedExercise>? onChanged;

  /// Séries do último treino em que o exercício foi feito (dicas dos campos).
  final List<ExecutedSet> previousSets;

  const SessionExerciseCard({
    super.key,
    required this.index,
    this.planned,
    this.executed,
    this.onChanged,
    this.previousSets = const [],
  }) : assert(planned != null || executed != null);

  /// Marca ou desmarca "feito". Só marca com todas as séries preenchidas.
  void _toggleDone(BuildContext context, ExecutedExercise executed, bool done) {
    if (done && !executed.allSetsFilled) {
      context.showSnack(
        'Preencha carga (ou BW) e repetições de todas as séries primeiro.',
      );
      return;
    }
    onChanged?.call(executed.copyWith(completed: done));
  }

  /// Aplica novas séries. Se alguma ficar vazia, o exercício deixa de estar feito.
  void _changeSets(ExecutedExercise executed, List<ExecutedSet> sets) {
    final updated = executed.copyWith(sets: sets);
    onChanged?.call(
      updated.completed && !updated.allSetsFilled
          ? updated.copyWith(completed: false)
          : updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final executed = this.executed;
    final done = executed?.completed ?? false;
    final rest = planned?.restLabel;
    final name = planned?.name ?? executed!.name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? RepsPerformance.top.color!.withAlpha(25)
            : cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? RepsPerformance.top.color!.withAlpha(120)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (rest != null)
                      Text(
                        'Descanso $rest',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (executed != null)
                FilterChip(
                  key: Key('exercise_done_$index'),
                  label: const Text('Feito'),
                  selected: done,
                  showCheckmark: true,
                  selectedColor: RepsPerformance.top.color!.withAlpha(60),
                  onSelected: (value) => _toggleDone(context, executed, value),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (executed == null)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final set in planned!.plannedSets) _PlannedSetChip(set),
              ],
            )
          else
            _SetsTable(
              exerciseIndex: index,
              sets: executed.sets,
              previousSets: previousSets,
              onChanged: (sets) => _changeSets(executed, sets),
            ),
        ],
      ),
    );
  }
}

/// Série planejada: faixa de repetições na cor do tipo, com marca de drop set.
class _PlannedSetChip extends StatelessWidget {
  final PlannedSet set;

  const _PlannedSetChip(this.set);

  @override
  Widget build(BuildContext context) {
    final color = set.type.color;

    return Tooltip(
      message: set.isDropSet ? '${set.type.label} + $dropSetLabel' : set.type.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: set.isDropSet ? dropSetColor : color.withAlpha(90),
            width: set.isDropSet ? 1.5 : 1,
          ),
        ),
        child: Text(
          set.isDropSet ? '${set.repsLabel} DS' : set.repsLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Tabela de séries editável: faixa, carga e repetições de cada série.
class _SetsTable extends StatelessWidget {
  final int exerciseIndex;
  final List<ExecutedSet> sets;
  final List<ExecutedSet> previousSets;
  final ValueChanged<List<ExecutedSet>> onChanged;

  const _SetsTable({
    required this.exerciseIndex,
    required this.sets,
    required this.previousSets,
    required this.onChanged,
  });

  void _replace(int index, ExecutedSet set) {
    onChanged([...sets]..[index] = set);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final header = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
    );

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 34, child: Text('Série', style: header)),
            SizedBox(
              width: 44,
              child: Text('Faixa', style: header, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Carga (kg)', style: header, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Reps', style: header, textAlign: TextAlign.center),
            ),
          ],
        ),
        if (previousSets.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Em cinza: valores do último treino',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 6),
        for (var i = 0; i < sets.length; i++)
          _SetRow(
            key: ValueKey('set_${exerciseIndex}_$i'),
            exerciseIndex: exerciseIndex,
            set: sets[i],
            // Mesma posição no último treino, quando existir
            previous: i < previousSets.length ? previousSets[i] : null,
            onChanged: (set) => _replace(i, set),
          ),
      ],
    );
  }
}

/// Uma série: número na cor do tipo, faixa, carga e repetições, mais as
/// etapas do drop set quando houver.
class _SetRow extends StatelessWidget {
  final int exerciseIndex;
  final ExecutedSet set;

  /// Mesma série no último treino, mostrada como dica nos campos vazios.
  final ExecutedSet? previous;
  final ValueChanged<ExecutedSet> onChanged;

  const _SetRow({
    super.key,
    required this.exerciseIndex,
    required this.set,
    required this.onChanged,
    this.previous,
  });

  /// Dica de um campo: o valor do último treino, ou "0" se não houver.
  static String _hint(double? value) {
    if (value == null || value <= 0) return '0';
    return HalfStepField.format(value);
  }

  /// Etapa [index] do drop set no último treino, quando existir.
  DropStage? _previousStage(int index) {
    final stages = previous?.dropStages ?? const <DropStage>[];
    return index < stages.length ? stages[index] : null;
  }

  void _replaceStage(int index, DropStage stage) {
    onChanged(set.copyWith(dropStages: [...set.dropStages]..[index] = stage));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final number = set.setNumber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 34, child: _SetBadge(set)),
              SizedBox(
                width: 44,
                child: Text(
                  set.rangeLabel ?? '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LoadCell(
                  key: Key('load_${exerciseIndex}_$number'),
                  set: set,
                  hint: previous?.bodyWeight ?? false
                      ? bodyWeightLabel
                      : _hint(previous?.loadKg),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HalfStepField(
                  key: Key('reps_${exerciseIndex}_$number'),
                  value: set.reps,
                  hint: _hint(previous?.reps),
                  textColor: set.performance?.color,
                  onChanged: (value) => onChanged(set.copyWith(reps: value)),
                ),
              ),
            ],
          ),
          if (set.isDropSet) ...[
            for (var i = 0; i < set.dropStages.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 34),
                    SizedBox(
                      width: 44,
                      child: set.dropStages.length > 1
                          ? IconButton(
                              tooltip: 'Remover etapa',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: cs.error,
                              ),
                              onPressed: () => onChanged(
                                set.copyWith(
                                  dropStages: [...set.dropStages]..removeAt(i),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 18,
                              color: dropSetColor,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HalfStepField(
                        value: set.dropStages[i].loadKg,
                        hint: _hint(_previousStage(i)?.loadKg),
                        onChanged: (value) => _replaceStage(
                          i,
                          DropStage(loadKg: value, reps: set.dropStages[i].reps),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HalfStepField(
                        value: set.dropStages[i].reps,
                        hint: _hint(_previousStage(i)?.reps),
                        onChanged: (value) => _replaceStage(
                          i,
                          DropStage(loadKg: set.dropStages[i].loadKg, reps: value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: dropSetColor,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => onChanged(
                  set.copyWith(
                    dropStages: [
                      ...set.dropStages,
                      const DropStage(loadKg: 0, reps: 0),
                    ],
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Etapa do drop set'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carga da série: campo numérico com o botão "BW" (peso do corpo). Com BW
/// marcado, o campo vira uma etiqueta "BW"; tocar nela volta para a carga.
class _LoadCell extends StatelessWidget {
  final ExecutedSet set;
  final String hint;
  final ValueChanged<ExecutedSet> onChanged;

  const _LoadCell({
    super.key,
    required this.set,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (set.bodyWeight) {
      return Tooltip(
        message: 'Peso do corpo. Toque para informar a carga.',
        child: Material(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: const Key('body_weight_on'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(set.copyWith(bodyWeight: false)),
            child: SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  bodyWeightLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return HalfStepField(
      value: set.loadKg,
      hint: hint,
      onChanged: (value) => onChanged(set.copyWith(loadKg: value)),
      suffixIcon: Tooltip(
        message: 'Peso do corpo (BW)',
        child: InkWell(
          key: const Key('body_weight_off'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => onChanged(set.copyWith(bodyWeight: true, loadKg: 0)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              bodyWeightLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Número da série na cor do tipo; o drop set ganha um contorno próprio.
class _SetBadge extends StatelessWidget {
  final ExecutedSet set;

  const _SetBadge(this.set);

  @override
  Widget build(BuildContext context) {
    final color = set.type.color;

    return Tooltip(
      message: set.isDropSet ? '${set.type.label} + $dropSetLabel' : set.type.label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withAlpha(35),
            shape: BoxShape.circle,
            border: Border.all(
              color: set.isDropSet ? dropSetColor : color.withAlpha(120),
              width: set.isDropSet ? 2 : 1,
            ),
          ),
          child: Text(
            '${set.setNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
