import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Rascunho de uma série enquanto o formulário do exercício está aberto.
class PlannedSetDraft {
  final TextEditingController rangeCtrl;
  SetType type;
  bool isDropSet;

  PlannedSetDraft({
    required String range,
    this.type = SetType.working,
    this.isDropSet = false,
  }) : rangeCtrl = TextEditingController(text: range);

  factory PlannedSetDraft.fromPlanned(PlannedSet set) => PlannedSetDraft(
    range: set.repsInput,
    type: set.type,
    isDropSet: set.isDropSet,
  );

  /// Drop set só pode acompanhar séries de Trabalho ou Aquecimento.
  bool get allowsDropSet => type != SetType.feeder;

  /// Troca o tipo, desmarcando o drop set quando o novo tipo não permite.
  void changeType(SetType newType) {
    type = newType;
    if (!allowsDropSet) isDropSet = false;
  }

  /// Cópia usada ao adicionar uma série igual à anterior.
  PlannedSetDraft copy() => PlannedSetDraft(
    range: rangeCtrl.text,
    type: type,
    isDropSet: isDropSet,
  );

  /// Monta a série. A faixa já deve ter sido validada pelo formulário.
  PlannedSet toPlannedSet() {
    final range = PlannedSet.tryParse(rangeCtrl.text, type: type)!;

    return PlannedSet(
      type: type,
      minReps: range.minReps,
      maxReps: range.maxReps,
      isDropSet: isDropSet,
    );
  }

  void dispose() => rangeCtrl.dispose();
}
