import 'package:flutter/foundation.dart';
import '../models/profile_models.dart';

/// Serviço em memória / repositório para persistência do histórico de treinos executados.
/// Compatível com expansão futura para Firebase Firestore ou SQLite.
class TrainingHistoryService extends ChangeNotifier {
  static final TrainingHistoryService _instance =
      TrainingHistoryService._internal();
  factory TrainingHistoryService() => _instance;

  TrainingHistoryService._internal() {
    _initDefaultData();
  }

  final List<CompletedWorkout> _sessions = [];

  /// Retorna as sessões ordenadas do mais recente para o mais antigo.
  List<CompletedWorkout> get sessions {
    final list = List<CompletedWorkout>.from(_sessions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(list);
  }

  void _initDefaultData() {
    if (_sessions.isNotEmpty) return;

    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    _sessions.addAll([
      CompletedWorkout(
        daysAgo(1),
        'A',
        62,
        id: 'sess-1',
        chartName: 'Training Charts 1',
        workoutName: 'TREINO A — Peito e Tríceps',
        executedExercises: [
          const ExecutedExercise(
            name: 'Supino reto',
            muscle: 'Peito',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.warmup,
                loadKg: 40,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 60,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 60,
                reps: 9,
              ),
              ExecutedSet(
                setNumber: 4,
                type: SetType.working,
                loadKg: 62.5,
                reps: 8,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Supino inclinado com halteres',
            muscle: 'Peito',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.feeder,
                loadKg: 24,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 24,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 24,
                reps: 10,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Crucifixo na máquina',
            muscle: 'Peito',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 40,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 40,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                isDropSet: true,
                loadKg: 40,
                reps: 12,
                dropStages: [DropStage(loadKg: 30, reps: 6)],
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Tríceps testa',
            muscle: 'Tríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 25,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 25,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 25,
                reps: 10,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Tríceps na polia',
            muscle: 'Tríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 30,
                reps: 15,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 30,
                reps: 15,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 32.5,
                reps: 13,
              ),
            ],
          ),
        ],
      ),
      CompletedWorkout(
        daysAgo(3),
        'C',
        71,
        id: 'sess-2',
        chartName: 'Training Charts 1',
        workoutName: 'TREINO C — Pernas e Ombros',
        executedExercises: [
          const ExecutedExercise(
            name: 'Agachamento livre',
            muscle: 'Quadríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.warmup,
                loadKg: 60,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 80,
                reps: 8,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 85,
                reps: 8,
              ),
              ExecutedSet(
                setNumber: 4,
                type: SetType.working,
                loadKg: 90,
                reps: 6,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Leg press 45°',
            muscle: 'Quadríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 180,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 200,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 200,
                reps: 10,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Desenvolvimento com halteres',
            muscle: 'Ombros',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 20,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 20,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 22,
                reps: 8,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Elevação lateral',
            muscle: 'Ombros',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 8,
                reps: 15,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 8,
                reps: 15,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                isDropSet: true,
                loadKg: 10,
                reps: 12,
                dropStages: [DropStage(loadKg: 6, reps: 6)],
              ),
            ],
          ),
        ],
      ),
      CompletedWorkout(
        daysAgo(4),
        'B',
        58,
        id: 'sess-3',
        chartName: 'Training Charts 1',
        workoutName: 'TREINO B — Costas e Bíceps',
        executedExercises: [
          const ExecutedExercise(
            name: 'Puxada frontal',
            muscle: 'Costas',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 55,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 55,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 60,
                reps: 8,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Remada curvada',
            muscle: 'Costas',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 50,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 50,
                reps: 8,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 52.5,
                reps: 8,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Rosca direta',
            muscle: 'Bíceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 30,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 30,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 30,
                reps: 10,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Rosca martelo',
            muscle: 'Bíceps',
            completed: false, // Demonstração do estado "não concluído"
            notes: 'Interrompido por dor no antebraço',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 14,
                reps: 6,
                completed: false,
              ),
            ],
          ),
        ],
      ),
      CompletedWorkout(
        daysAgo(6),
        'A',
        64,
        id: 'sess-4',
        chartName: 'Training Charts 1',
        workoutName: 'TREINO A — Peito e Tríceps',
        executedExercises: [
          const ExecutedExercise(
            name: 'Supino reto',
            muscle: 'Peito',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.warmup,
                loadKg: 40,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 57.5,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                loadKg: 57.5,
                reps: 10,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Supino inclinado com halteres',
            muscle: 'Peito',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 22,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 22,
                reps: 12,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Crucifixo na máquina',
            muscle: 'Peito',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 35,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 35,
                reps: 12,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Tríceps testa',
            muscle: 'Tríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 22.5,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 22.5,
                reps: 12,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Tríceps na polia',
            muscle: 'Tríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 27.5,
                reps: 15,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 27.5,
                reps: 15,
              ),
            ],
          ),
        ],
      ),
      CompletedWorkout(
        daysAgo(8),
        'C',
        69,
        id: 'sess-5',
        chartName: 'Training Charts 1',
        workoutName: 'TREINO C — Pernas e Ombros',
        executedExercises: [
          const ExecutedExercise(
            name: 'Agachamento livre',
            muscle: 'Quadríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 75,
                reps: 8,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 80,
                reps: 8,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Leg press 45°',
            muscle: 'Quadríceps',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 170,
                reps: 12,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 170,
                reps: 12,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Desenvolvimento com halteres',
            muscle: 'Ombros',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 18,
                reps: 10,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 18,
                reps: 10,
              ),
            ],
          ),
          const ExecutedExercise(
            name: 'Elevação lateral',
            muscle: 'Ombros',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.working,
                loadKg: 7,
                reps: 15,
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                loadKg: 7,
                reps: 15,
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  /// Carrega as sessões de treino com simulação de latência assíncrona.
  Future<List<CompletedWorkout>> loadSessions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return sessions;
  }

  /// Adiciona uma nova sessão concluída ao histórico.
  Future<void> addSession(CompletedWorkout session) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _sessions.insert(0, session);
    notifyListeners();
  }

  /// Retorna as sessões associadas a um plano/dia específico (ex: 'A', 'B', 'C').
  List<CompletedWorkout> getSessionsForWorkout(String plan, {String? chartName}) {
    return sessions.where((s) {
      final matchesPlan =
          s.plan.trim().toLowerCase() == plan.trim().toLowerCase();
      if (chartName != null && chartName.isNotEmpty) {
        return matchesPlan &&
            (s.chartName?.toLowerCase() == chartName.toLowerCase());
      }
      return matchesPlan;
    }).toList();
  }

  /// Retorna os planos distintos existentes no histórico (ex: ['A', 'B', 'C']).
  List<String> getAvailablePlans() {
    final set = <String>{};
    for (final s in _sessions) {
      set.add(s.plan);
    }
    final list = set.toList()..sort();
    return list;
  }

  @visibleForTesting
  void clearForTest() {
    _sessions.clear();
    notifyListeners();
  }

  @visibleForTesting
  void setSessionsForTest(List<CompletedWorkout> list) {
    _sessions.clear();
    _sessions.addAll(list);
    notifyListeners();
  }
}
