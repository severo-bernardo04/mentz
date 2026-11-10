import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';

/// Rascunho de um dia do ciclo enquanto o formulário está aberto.
class DayDraft {
  final TextEditingController nameCtrl;

  /// Exercícios do dia, na ordem de execução.
  final List<WorkoutExercise> exercises = [];
  int restDaysAfter;

  DayDraft({
    required String name,
    this.restDaysAfter = 1,
  }) : nameCtrl = TextEditingController(text: name);

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