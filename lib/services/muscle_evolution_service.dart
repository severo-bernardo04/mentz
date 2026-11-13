import '../models/profile_models.dart';
import 'muscle_analysis_service.dart';

/// Evolução em uma data: variação percentual em relação ao ponto de partida.
class EvolutionPoint {
  final DateTime date;

  /// Ex: 12.5 significa 12,5% acima do primeiro treino; negativo é queda.
  final double percent;

  const EvolutionPoint(this.date, this.percent);
}

/// Evolução de uma planilha ao longo do tempo: visão geral e por grupamento.
class MuscleEvolution {
  /// Média das evoluções de todos os grupamentos, treino a treino.
  final List<EvolutionPoint> overall;

  /// Evolução de cada grupamento, treino a treino.
  final Map<String, List<EvolutionPoint>> byGroup;

  const MuscleEvolution({this.overall = const [], this.byGroup = const {}});

  /// Grupamentos com dados, em ordem alfabética.
  List<String> get groups => byGroup.keys.toList()..sort();

  /// Há pontos suficientes para desenhar uma linha.
  bool get hasData => overall.length >= 2;
}

/// Calcula a evolução muscular pela 1RM estimada. Não guarda estado nem
/// acessa o Firestore.
///
/// Regras:
/// - 1RM de uma série = carga × (1 + repetições / 30); com 1 repetição, é a
///   própria carga;
/// - só séries de Trabalho entram; em drop set, conta só a primeira etapa;
/// - séries com peso do corpo (BW) ficam de fora por enquanto, até ser
///   definido como estimar a carga delas;
/// - a evolução de um exercício é a variação da melhor 1RM do treino em
///   relação à do primeiro treino em que ele apareceu;
/// - a evolução de um grupamento é a média das evoluções dos exercícios que
///   o trabalham, cada uma multiplicada (ponderada) pela pontuação do
///   músculo no exercício (3, 2 ou 1);
/// - a visão geral é a média das evoluções de todos os grupamentos;
/// - só entram sessões da planilha informada.
abstract final class MuscleEvolutionService {
  /// 1RM estimada de uma série. Retorna 0 sem carga ou sem repetições.
  static double oneRepMax(double loadKg, double reps) {
    if (loadKg <= 0 || reps <= 0) return 0;
    if (reps == 1) return loadKg;
    return loadKg * (1 + reps / 30);
  }

  /// Melhor 1RM do exercício no treino, entre as séries de Trabalho com
  /// carga. É null se nenhuma série entra no cálculo.
  static double? bestOneRepMax(ExecutedExercise exercise) {
    double? best;
    for (final set in exercise.sets) {
      if (set.type != SetType.working || set.bodyWeight) continue;

      // loadKg e reps são os da primeira etapa, mesmo em drop set
      final value = oneRepMax(set.loadKg, set.reps);
      if (value > 0 && (best == null || value > best)) best = value;
    }
    return best;
  }

  /// Evolução da planilha [chartId] a partir das [sessions]. [findExercise]
  /// busca o exercício no catálogo, de onde vêm os papéis dos músculos.
  static MuscleEvolution evolutionOf(
    String chartId,
    List<CompletedWorkout> sessions, {
    required ExerciseLookup findExercise,
  }) {
    final ordered = sessions.where((s) => s.chartId == chartId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Por exercício: 1RM de partida, evolução mais recente e pesos por grupo
    final baseline = <String, double>{};
    final current = <String, double>{};
    final weights = <String, Map<String, int>>{};

    final overall = <EvolutionPoint>[];
    final byGroup = <String, List<EvolutionPoint>>{};

    for (final session in ordered) {
      for (final exercise in session.executedExercises) {
        final best = bestOneRepMax(exercise);
        if (best == null) continue;

        final key = exercise.exerciseId ?? exercise.name;
        final start = baseline.putIfAbsent(key, () => best);
        current[key] = (best / start - 1) * 100;
        weights.putIfAbsent(key, () => _groupWeights(exercise, findExercise));
      }
      if (current.isEmpty) continue;

      // Média ponderada por grupamento, com a evolução mais recente de cada
      // exercício (um exercício não treinado hoje mantém o último valor)
      final weightedSum = <String, double>{};
      final weightTotal = <String, int>{};
      current.forEach((key, percent) {
        weights[key]!.forEach((group, points) {
          weightedSum[group] = (weightedSum[group] ?? 0) + percent * points;
          weightTotal[group] = (weightTotal[group] ?? 0) + points;
        });
      });
      if (weightTotal.isEmpty) continue;

      var sum = 0.0;
      weightTotal.forEach((group, total) {
        final percent = weightedSum[group]! / total;
        sum += percent;
        _addPoint(byGroup.putIfAbsent(group, () => []), session.date, percent);
      });
      _addPoint(overall, session.date, sum / weightTotal.length);
    }

    return MuscleEvolution(overall: overall, byGroup: byGroup);
  }

  /// Pontos de cada grupamento no exercício (somando os músculos do grupo).
  /// Se o exercício saiu do catálogo, usa o músculo guardado na sessão.
  static Map<String, int> _groupWeights(
    ExecutedExercise executed,
    ExerciseLookup findExercise,
  ) {
    final id = executed.exerciseId;
    final exercise =
        (id == null ? null : findExercise(id)) ??
        Exercise(name: executed.name, muscle: executed.muscle);

    final result = <String, int>{};
    for (final c in MuscleAnalysisService.contributionsOf(exercise)) {
      result[c.group] = (result[c.group] ?? 0) + c.points;
    }
    return result;
  }

  /// Acrescenta o ponto; dois treinos no mesmo dia viram um ponto só.
  static void _addPoint(List<EvolutionPoint> points, DateTime date, double percent) {
    final point = EvolutionPoint(date, percent);
    if (points.isNotEmpty && _sameDay(points.last.date, date)) {
      points[points.length - 1] = point;
    } else {
      points.add(point);
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
