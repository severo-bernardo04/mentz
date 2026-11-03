import 'package:flutter/material.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/training/controllers/chart_form_controller.dart';
import 'package:mentz/features/training/widgets/chart_info_section.dart';
import 'package:mentz/features/training/widgets/cycle_days_section.dart';
import 'package:mentz/features/training/widgets/frequency_section.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/widgets/app_button.dart';
import 'package:mentz/widgets/app_page_scaffold.dart';
import 'package:mentz/widgets/error_banner.dart';
import 'package:mentz/widgets/fade_slide_in.dart';
import 'package:mentz/widgets/staggered_column.dart';

class CreateTrainingChartPage extends StatefulWidget {
  final TrainingChartService? service;

  const CreateTrainingChartPage({super.key, this.service});

  @override
  State<CreateTrainingChartPage> createState() =>
      _CreateTrainingChartPageState();
}

class _CreateTrainingChartPageState extends State<CreateTrainingChartPage> {
  final _formKey = GlobalKey<FormState>();
  final _form = ChartFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _form.clearError();
    if (!_formKey.currentState!.validate()) return;

    final chart = await _form.save(widget.service ?? TrainingChartService());
    if (!mounted || chart == null) return;

    context.showSnack(
      'Planilha "${chart.name}" criada com sucesso!',
      background: Colors.green.shade700,
    );
    Navigator.of(context).pop(chart);
  }

  void _removeDay(int index) {
    if (_form.removeDay(index)) return;

    context.showSnack(
      'A planilha deve conter pelo menos um dia de treino.',
      background: Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Nova Planilha',
      child: Form(
        key: _formKey,
        child: ListenableBuilder(
          listenable: _form,
          builder: (context, _) {
            final error = _form.errorMessage;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaggeredColumn(
                  spacing: 0,
                  startDelay: Duration.zero,
                  children: [
                    ChartInfoSection(
                      nameCtrl: _form.nameCtrl,
                      descCtrl: _form.descCtrl,
                    ),
                    FrequencySection(
                      type: _form.frequencyType,
                      selectedWeekdays: _form.selectedWeekdays,
                      onTypeChanged: _form.setFrequencyType,
                      onWeekdayToggled: _form.toggleWeekday,
                    ),
                    CycleDaysSection(
                      days: _form.days,
                      intervalMode: _form.frequencyType ==
                          WorkoutFrequencyType.intervalDays,
                      onAdd: _form.addDay,
                      onRemove: _removeDay,
                      onRestChanged: _form.setRestDays,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  child: error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ErrorBanner(error),
                        ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: AppButton(
                    label: 'Criar Planilha',
                    loading: _form.loading,
                    onPressed: _save,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}