import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import '../../../services/training_history_service.dart';

/// Controller de estado da tela de Histórico de Treinos.
/// Gerencia carregamento, filtros, ordenação e mensagens de erro sem lógica de UI.
class TrainingHistoryController extends ChangeNotifier {
  final TrainingHistoryService service;

  TrainingHistoryController({TrainingHistoryService? service})
      : service = service ?? TrainingHistoryService();

  List<CompletedWorkout> _sessions = [];
  bool _loading = false;
  String? _errorMessage;
  String? _selectedPlanFilter;
  bool _disposed = false;

  List<CompletedWorkout> get sessions => List.unmodifiable(_sessions);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String? get selectedPlanFilter => _selectedPlanFilter;

  /// Retorna as sessões aplicando o filtro de plano/dia selecionado.
  List<CompletedWorkout> get filteredSessions {
    if (_selectedPlanFilter == null || _selectedPlanFilter == 'Todos') {
      return _sessions;
    }
    return _sessions
        .where((s) => s.plan.toLowerCase() == _selectedPlanFilter!.toLowerCase())
        .toList();
  }

  /// Retorna os planos disponíveis para compor os filtros (ex: ['Todos', 'A', 'B', 'C']).
  List<String> get availablePlans {
    final plans = <String>{'Todos'};
    for (final s in _sessions) {
      plans.add(s.plan);
    }
    return plans.toList();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void setFilter(String? plan) {
    if (_selectedPlanFilter == plan) return;
    _selectedPlanFilter = plan;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Carrega as sessões ordenadas do mais recente para o mais antigo.
  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await service.loadSessions();
      _sessions = List<CompletedWorkout>.from(result);
      // Garantir ordenação cronológica decrescente (mais recente para mais antigo)
      _sessions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _errorMessage = 'Falha ao carregar o histórico de treinos: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
