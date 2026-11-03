import 'package:flutter/material.dart';
import 'package:mentz/features/training/controllers/day_draft.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/training_chart_service.dart';

/// Estado e regras do formulário de nova planilha (sem nada de interface).
class ChartFormController extends ChangeNotifier {
  final nameCtrl = TextEditingController(text: 'Training Charts 7');
  final descCtrl = TextEditingController();

  /// Começa com 3 dias padrão (ABC).
  final List<DayDraft> days = [
    DayDraft(name: 'TREINO A', focus: 'Peito e Tríceps', restDaysAfter: 1),
    DayDraft(name: 'TREINO B', focus: 'Costas e Bíceps', restDaysAfter: 1),
    DayDraft(name: 'TREINO C', focus: 'Pernas e Ombros', restDaysAfter: 2),
  ];

  /// 1 = Seg ... 7 = Dom.
  final Set<int> selectedWeekdays = {1, 3, 5};

  WorkoutFrequencyType frequencyType = WorkoutFrequencyType.fixedDays;
  bool loading = false;
  String? errorMessage;

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void setFrequencyType(WorkoutFrequencyType type) {
    frequencyType = type;
    notifyListeners();
  }

  void toggleWeekday(int weekday, bool selected) {
    if (selected) {
      selectedWeekdays.add(weekday);
    } else {
      selectedWeekdays.remove(weekday);
    }
    notifyListeners();
  }

  void addDay() {
    final letter = String.fromCharCode(65 + (days.length % 26));
    days.add(DayDraft(name: 'TREINO $letter'));
    errorMessage = null;
    notifyListeners();
  }

  /// Remove o dia [index]. Retorna false se for o último (não pode remover).
  bool removeDay(int index) {
    if (days.length <= 1) return false;

    days.removeAt(index).dispose();
    errorMessage = null;
    notifyListeners();
    return true;
  }

  void setRestDays(DayDraft day, int value) {
    day.restDaysAfter = value;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  /// Regras que vão além dos campos do Form. Retorna a mensagem de erro, se houver.
  String? validateRules() {
    if (days.isEmpty) {
      return 'Adicione pelo menos um dia de treino ao ciclo.';
    }

    for (var i = 0; i < days.length; i++) {
      if (days[i].nameCtrl.text.trim().isEmpty) {
        return 'O dia #${i + 1} está com o nome vazio.';
      }
    }

    if (frequencyType == WorkoutFrequencyType.fixedDays &&
        selectedWeekdays.isEmpty) {
      return 'Selecione ao menos um dia da semana para treinar.';
    }

    return null;
  }

  TrainingChart buildChart() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final isFixed = frequencyType == WorkoutFrequencyType.fixedDays;
    final desc = descCtrl.text.trim();

    return TrainingChart(
      id: 'chart-$stamp',
      name: nameCtrl.text.trim(),
      description: desc.isEmpty ? null : desc,
      days: [
        for (var i = 0; i < days.length; i++)
          days[i].toTrainingDay(id: 'day-$stamp-$i', order: i + 1),
      ],
      frequencyConfig: WorkoutFrequencyConfig(
        type: frequencyType,
        fixedWeekdays: isFixed ? (selectedWeekdays.toList()..sort()) : const [],
        intervalRestDays:
            isFixed ? const [] : [for (final d in days) d.restDaysAfter],
      ),
      createdAt: DateTime.now(),
    );
  }

  /// Valida as regras e salva. Retorna a planilha criada, ou null se falhou
  /// (nesse caso veja [errorMessage]).
  Future<TrainingChart?> save(TrainingChartService service) async {
    errorMessage = validateRules();
    if (errorMessage != null) {
      notifyListeners();
      return null;
    }

    loading = true;
    notifyListeners();

    try {
      final chart = buildChart();
      await service.saveChart(chart);
      return chart;
    } catch (e) {
      errorMessage = 'Erro ao salvar a planilha: $e';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    nameCtrl.dispose();
    descCtrl.dispose();
    for (final day in days) {
      day.dispose();
    }
    super.dispose();
  }
}