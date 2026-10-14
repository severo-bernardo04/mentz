import 'package:flutter/foundation.dart';
import '../models/training_chart.dart';

/// Serviço em memória / repositório para persistência de planilhas de treino.
/// Pode ser facilmente estendido para SQLite, SharedPreferences ou Firebase.
class TrainingChartService extends ChangeNotifier {
  static final TrainingChartService _instance = TrainingChartService._internal();
  factory TrainingChartService() => _instance;
  TrainingChartService._internal() {
    _initDefaultData();
  }

  final List<TrainingChart> _charts = [];

  List<TrainingChart> get charts => List.unmodifiable(_charts);

  void _initDefaultData() {
    if (_charts.isNotEmpty) return;
    // Exemplo de planilha padrão para consulta imediata
    _charts.add(
      TrainingChart(
        id: 'chart-sample-1',
        name: 'Training Charts 1',
        description: 'Planilha padrão com ciclo ABC',
        days: const [
          TrainingDay(
            id: 'day-1',
            name: 'TREINO A',
            order: 1,
            focusOrDescription: 'Peito e Tríceps',
          ),
          TrainingDay(
            id: 'day-2',
            name: 'TREINO B',
            order: 2,
            focusOrDescription: 'Costas e Bíceps',
          ),
          TrainingDay(
            id: 'day-3',
            name: 'TREINO C',
            order: 3,
            focusOrDescription: 'Pernas e Ombros',
          ),
        ],
        frequencyConfig: const WorkoutFrequencyConfig(
          type: WorkoutFrequencyType.fixedDays,
          fixedWeekdays: [1, 3, 5], // Seg, Qua, Sex
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );
  }

  /// Salva uma nova planilha ou atualiza uma existente.
  Future<void> saveChart(TrainingChart chart) async {
    // Simula uma operação assíncrona realista (armazenamento/banco)
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _charts.indexWhere((c) => c.id == chart.id);
    if (index >= 0) {
      _charts[index] = chart;
    } else {
      _charts.insert(0, chart);
    }
    notifyListeners();
  }

  /// Remove uma planilha pelo ID.
  Future<void> deleteChart(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _charts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Limpa todos os dados (útil em testes).
  @visibleForTesting
  void clearForTest() {
    _charts.clear();
    notifyListeners();
  }
}
