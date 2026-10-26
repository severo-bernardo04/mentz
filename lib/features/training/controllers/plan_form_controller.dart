import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Estado e regras do editor de ficha (sem nada de interface).
class PlanFormController extends ChangeNotifier {
  final WorkoutPlan? original;
  final TextEditingController nameCtrl;
  final TextEditingController focusCtrl;
  final TextEditingController notesCtrl;
  final List<Exercise> exercises;
  final Set<String> assigned;

  PlanFormController(this.original)
      : nameCtrl = TextEditingController(text: original?.name ?? ''),
        focusCtrl = TextEditingController(text: original?.focus ?? ''),
        notesCtrl = TextEditingController(text: original?.notes ?? ''),
        // cópia profunda: o original só muda quando o treinador salvar
        exercises = [
          for (final e in original?.exercises ?? <Exercise>[]) _copy(e),
        ],
        assigned = {...?original?.assignedStudents};

  bool get isEditing => original != null;

  static Exercise _copy(Exercise e) => Exercise(
        name: e.name,
        muscle: e.muscle,
        sets: e.sets,
        reps: e.reps,
        load: e.load,
        restSeconds: e.restSeconds,
      );

  /// Adiciona o exercício, ou substitui o da posição [index].
  void saveExercise(Exercise exercise, {int? index}) {
    if (index == null) {
      exercises.add(exercise);
    } else {
      exercises[index] = exercise;
    }
    notifyListeners();
  }

  void removeExercise(int index) {
    exercises.removeAt(index);
    notifyListeners();
  }

  /// [newIndex] já vem ajustado pelo `onReorderItem` do Flutter.
  void reorder(int oldIndex, int newIndex) {
    exercises.insert(newIndex, exercises.removeAt(oldIndex));
    notifyListeners();
  }

  void toggleStudent(String name, bool selected) {
    if (selected) {
      assigned.add(name);
    } else {
      assigned.remove(name);
    }
    notifyListeners();
  }

  WorkoutPlan buildPlan() {
    return WorkoutPlan(
      id: original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameCtrl.text.trim(),
      focus: focusCtrl.text.trim(),
      exercises: exercises,
      assignedStudents: assigned.toList(),
      notes: notesCtrl.text.trim(),
      weeklyCompletion: original?.weeklyCompletion ?? 0,
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    focusCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }
}