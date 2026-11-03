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
                load: '40 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '60 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '60 kg',
                reps: '9',
              ),
              ExecutedSet(
                setNumber: 4,
                type: SetType.working,
                load: '62.5 kg',
                reps: '8',
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
                load: '24 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '24 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '24 kg',
                reps: '10',
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
                load: '40 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '40 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.dropSet,
                load: '40 kg / 30 kg',
                reps: '12 + 6',
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
                load: '25 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '25 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '25 kg',
                reps: '10',
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
                load: '30 kg',
                reps: '15',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '30 kg',
                reps: '15',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.failure,
                load: '32.5 kg',
                reps: '13',
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
                load: '60 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '80 kg',
                reps: '8',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '85 kg',
                reps: '8',
              ),
              ExecutedSet(
                setNumber: 4,
                type: SetType.working,
                load: '90 kg',
                reps: '6',
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
                load: '180 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '200 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '200 kg',
                reps: '10',
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
                load: '20 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '20 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '22 kg',
                reps: '8',
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
                load: '8 kg',
                reps: '15',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '8 kg',
                reps: '15',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.dropSet,
                load: '10 kg / 6 kg',
                reps: '12 + 6',
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
                load: '55 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '55 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '60 kg',
                reps: '8',
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
                load: '50 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '50 kg',
                reps: '8',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '52.5 kg',
                reps: '8',
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
                load: '30 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '30 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '30 kg',
                reps: '10',
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
                load: '14 kg',
                reps: '6',
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
                load: '40 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '57.5 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 3,
                type: SetType.working,
                load: '57.5 kg',
                reps: '10',
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
                load: '22 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '22 kg',
                reps: '12',
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
                load: '35 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '35 kg',
                reps: '12',
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
                load: '22.5 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '22.5 kg',
                reps: '12',
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
                load: '27.5 kg',
                reps: '15',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '27.5 kg',
                reps: '15',
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
                load: '75 kg',
                reps: '8',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '80 kg',
                reps: '8',
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
                load: '170 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '170 kg',
                reps: '12',
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
                load: '18 kg',
                reps: '10',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '18 kg',
                reps: '10',
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
                load: '7 kg',
                reps: '15',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '7 kg',
                reps: '15',
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
