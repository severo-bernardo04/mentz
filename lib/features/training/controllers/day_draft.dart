import 'package:flutter/material.dart';
import 'package:mentz/models/training_chart.dart';

/// Rascunho de um dia do ciclo enquanto o formulário está aberto.
class DayDraft {
  final TextEditingController nameCtrl;
  final TextEditingController focusCtrl;
  int restDaysAfter;

  DayDraft({
    required String name,
    String focus = '',
    this.restDaysAfter = 1,
  })  : nameCtrl = TextEditingController(text: name),
        focusCtrl = TextEditingController(text: focus);

  TrainingDay toTrainingDay({required String id, required int order}) {
    final focus = focusCtrl.text.trim();

    return TrainingDay(
      id: id,
      name: nameCtrl.text.trim(),
      order: order,
      focusOrDescription: focus.isEmpty ? null : focus,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    focusCtrl.dispose();
  }
}