import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import '../../../services/exercise_catalog_service.dart';

/// Controller para gerenciar o estado da página de catálogo de exercícios:
/// busca em tempo real por nome (PT e EN), filtro por grupo muscular,
/// estados de carregamento e mensagens de erro.
class ExerciseCatalogController extends ChangeNotifier {
  final ExerciseCatalogService service;

  ExerciseCatalogController({ExerciseCatalogService? service})
      : service = service ?? ExerciseCatalogService();

  List<Exercise> _exercises = [];
  bool _loading = false;
  String? _errorMessage;
  String _query = '';
  String _selectedMuscle = 'Todos';
  bool _disposed = false;

  List<Exercise> get exercises => List.unmodifiable(_exercises);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String get selectedMuscle => _selectedMuscle;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  List<String> get availableMuscleGroups => service.getAvailableMuscleGroups();

  /// Retorna os exercícios aplicando a busca e o filtro por grupo muscular.
  List<Exercise> get filteredExercises {
    return service.search(
      query: _query,
      muscleGroup: _selectedMuscle == 'Todos' ? null : _selectedMuscle,
    );
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setMuscleGroup(String group) {
    if (_selectedMuscle == group) return;
    _selectedMuscle = group;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await service.loadExercises();
      _exercises = List<Exercise>.from(list);
    } catch (e) {
      _errorMessage = 'Erro ao carregar o catálogo de exercícios: $e';
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
