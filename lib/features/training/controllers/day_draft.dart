import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';

/// Rascunho de um dia do ciclo enquanto o formulário está aberto.
class DayDraft {
  final TextEditingController nameCtrl;

  /// Exercícios do dia, na ordem de execução.
  final List<WorkoutExercise> exercises = [];
  int restDaysAfter;

  /// Identificador do dia já salvo; null em um dia novo. Na edição, manter o
  /// identificador preserva o vínculo com o histórico e o ciclo de treinos.
  final String? id;

  DayDraft({
    required String name,
    this.restDaysAfter = 1,
    this.id,
  }) : nameCtrl = TextEditingController(text: name);

  /// Rascunho de um dia já salvo, para a edição da planilha.
  factory DayDraft.fromDay(TrainingDay day, {int restDaysAfter = 1}) {
    return DayDraft(name: day.name, restDaysAfter: restDaysAfter, id: day.id)
      ..exercises.addAll(day.exercises);
  }

  TrainingDay toTrainingDay({required String id, required int order}) {
    return TrainingDay(
      id: id,
      name: nameCtrl.text.trim(),
      order: order,
      exercises: List.of(exercises),
    );
  }

  void dispose() {
    nameCtrl.dispose();
  }
}