import 'package:flutter/material.dart';
import 'package:mentz/features/training/controllers/day_draft.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/training_chart_service.dart';

/// Estado e regras do formulário de planilha, para criar uma nova ou editar
/// uma existente (sem nada de interface).
class ChartFormController extends ChangeNotifier {
  /// Planilha sendo editada; null ao criar uma nova.
  final TrainingChart? editing;

  final TextEditingController nameCtrl;

  /// Dias do ciclo. Uma planilha nova começa com 3 dias padrão (ABC).
  final List<DayDraft> days;

  /// 1 = Seg ... 7 = Dom.
  final Set<int> selectedWeekdays;

  WorkoutFrequencyType frequencyType;
  bool loading = false;

  /// Com [editing], o formulário começa preenchido com os dados da planilha.
  ChartFormController({this.editing})
    : nameCtrl = TextEditingController(
        text: editing?.name ?? 'Training Charts 7',
      ),
      days = editing == null ? _defaultDays() : _daysOf(editing),
      selectedWeekdays = _weekdaysOf(editing),
      frequencyType =
          editing?.frequencyConfig.type ?? WorkoutFrequencyType.fixedDays;

  bool get isEditing => editing != null;

  static List<DayDraft> _defaultDays() => [
    DayDraft(name: 'TREINO A', restDaysAfter: 1),
    DayDraft(name: 'TREINO B', restDaysAfter: 1),
    DayDraft(name: 'TREINO C', restDaysAfter: 2),
  ];

  /// Dias da planilha, na ordem do ciclo, com o descanso de cada um.
  static List<DayDraft> _daysOf(TrainingChart chart) {
    final sorted = [...chart.days]..sort((a, b) => a.order.compareTo(b.order));
    final rest = chart.frequencyConfig.intervalRestDays;

    return [
      for (var i = 0; i < sorted.length; i++)
        DayDraft.fromDay(
          sorted[i],
          restDaysAfter: i < rest.length ? rest[i] : 1,
        ),
    ];
  }

  /// Dias da semana marcados; o padrão vale para planilha nova ou de intervalo.
  static Set<int> _weekdaysOf(TrainingChart? chart) {
    final saved = chart?.frequencyConfig.fixedWeekdays ?? const <int>[];
    return saved.isEmpty ? {1, 3, 5} : saved.toSet();
  }
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

  /// Adiciona um dia ao ciclo. Retorna false se já estiver no limite.
  bool addDay() {
    if (days.length >= TrainingChart.maxDays) return false;

    final letter = String.fromCharCode(65 + (days.length % 26));
    days.add(DayDraft(name: 'TREINO $letter'));
    errorMessage = null;
    notifyListeners();
    return true;
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

  /// Adiciona o exercício ao dia, ou substitui o da posição [index].
  void saveExercise(DayDraft day, WorkoutExercise exercise, {int? index}) {
    if (index == null) {
      day.exercises.add(exercise);
    } else {
      day.exercises[index] = exercise;
    }
    errorMessage = null;
    notifyListeners();
  }

  void removeExercise(DayDraft day, int index) {
    day.exercises.removeAt(index);
    notifyListeners();
  }

  /// [newIndex] já vem ajustado pelo `onReorderItem` do Flutter.
  void reorderExercise(DayDraft day, int oldIndex, int newIndex) {
    day.exercises.insert(newIndex, day.exercises.removeAt(oldIndex));
    notifyListeners();
  }

  /// Dias como estão no formulário agora, para prévias (ex: a pontuação
  /// muscular) antes de salvar.
  List<TrainingDay> get previewDays => [
    for (var i = 0; i < days.length; i++)
      days[i].toTrainingDay(id: days[i].id ?? 'preview-$i', order: i + 1),
  ];

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
      if (days[i].exercises.isEmpty) {
        return 'Adicione ao menos um exercício em ${days[i].nameCtrl.text.trim()}.';
      }
    }

    if (frequencyType == WorkoutFrequencyType.fixedDays &&
        selectedWeekdays.isEmpty) {
      return 'Selecione ao menos um dia da semana para treinar.';
    }

    return null;
  }

  /// Monta a planilha a salvar. Na edição, mantém o identificador da
  /// planilha e dos dias já existentes (o histórico e o ciclo dependem
  /// deles), além da data de criação e da marcação de planilha atual.
  TrainingChart buildChart() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final isFixed = frequencyType == WorkoutFrequencyType.fixedDays;

    return TrainingChart(
      id: editing?.id ?? 'chart-$stamp',
      name: nameCtrl.text.trim(),
      description: editing?.description,
      selectedAt: editing?.selectedAt,
      days: [
        for (var i = 0; i < days.length; i++)
          days[i].toTrainingDay(
            id: days[i].id ?? 'day-$stamp-$i',
            order: i + 1,
          ),
      ],
      frequencyConfig: WorkoutFrequencyConfig(
        type: frequencyType,
        fixedWeekdays: isFixed ? (selectedWeekdays.toList()..sort()) : const [],
        intervalRestDays:
            isFixed ? const [] : [for (final d in days) d.restDaysAfter],
      ),
      createdAt: editing?.createdAt ?? DateTime.now(),
    );
  }

  /// Valida as regras e salva. Retorna a planilha salva, ou null se falhou
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
    } catch (_) {
      errorMessage = 'Não foi possível salvar a planilha. Tente novamente.';
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
    for (final day in days) {
      day.dispose();
    }
    super.dispose();
  }
}