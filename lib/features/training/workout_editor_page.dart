import 'package:flutter/material.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/training/controllers/plan_form_controller.dart';
import 'package:mentz/features/training/widgets/assigned_students_section.dart';
import 'package:mentz/features/training/widgets/exercise_sheet.dart';
import 'package:mentz/features/training/widgets/exercises_section.dart';
import 'package:mentz/features/training/widgets/plan_identity_section.dart';
import 'package:mentz/features/training/widgets/plan_notes_section.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/app_button.dart';
import 'package:mentz/widgets/app_page_scaffold.dart';

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
  late final PlanFormController _form = PlanFormController(widget.plan);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _editExercise({Exercise? current, int? index}) async {
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ExerciseSheet(exercise: current),
    );
    if (!mounted || result == null) return;

    _form.saveExercise(result, index: index);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_form.exercises.isEmpty) {
      context.showSnack('Adicione ao menos um exercício.');
      return;
    }

    // TODO: persistir a ficha no backend (ex: Firestore)
    Navigator.of(context).pop(_form.buildPlan());
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: _form.isEditing ? 'Editar ficha' : 'Nova ficha',
      maxWidth: 640,
      actions: [
        TextButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Salvar'),
        ),
        const SizedBox(width: 8),
      ],
      child: Form(
        key: _formKey,
        child: ListenableBuilder(
          listenable: _form,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlanIdentitySection(
                nameCtrl: _form.nameCtrl,
                focusCtrl: _form.focusCtrl,
              ),
              ExercisesSection(
                exercises: _form.exercises,
                onAdd: () => _editExercise(),
                onEdit: (i) => _editExercise(
                  current: _form.exercises[i],
                  index: i,
                ),
                onDelete: _form.removeExercise,
                onReorder: _form.reorder,
              ),
              AssignedStudentsSection(
                studentNames: widget.studentNames,
                assigned: _form.assigned,
                onToggle: _form.toggleStudent,
              ),
              PlanNotesSection(controller: _form.notesCtrl),
              const SizedBox(height: 4),
              AppButton(
                label: _form.isEditing ? 'Salvar alterações' : 'Criar ficha',
                icon: Icons.save_outlined,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}