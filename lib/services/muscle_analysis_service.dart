import '../models/profile_models.dart';
import '../models/training_chart.dart';

/// Papel de um músculo em um exercício, com os pontos que ele vale.
enum MuscleRole {
  primary('Principal', 3),
  highActivation('Alta ativação', 2),
  secondary('Secundário', 1);

  final String label;
  final int points;
  const MuscleRole(this.label, this.points);
}

/// Um músculo trabalhado por um exercício: papel e grupamento a que pertence.
class MuscleContribution {
  final String exerciseName;

  /// Músculo como está cadastrado no catálogo (ex: "Deltoide anterior").
  final String muscle;

  /// Grupamento do músculo (ex: "Ombros").
  final String group;
  final MuscleRole role;

  /// Dia do exercício, informado na pontuação da planilha inteira.
  final String? dayName;

  const MuscleContribution({
    required this.exerciseName,
    required this.muscle,
    required this.group,
    required this.role,
    this.dayName,
  });

  int get points => role.points;
}

/// Pontuação de um grupamento em um treino, com o que a compõe.
class MuscleScore {
  final String group;
  final List<MuscleContribution> contributions;

  const MuscleScore(this.group, this.contributions);

  int get points => contributions.fold(0, (total, c) => total + c.points);
}

/// Análises feitas sobre o que está planejado na planilha: contagem de
/// séries por tipo e pontuação muscular. Não guarda estado nem acessa o
/// Firestore; usa os papéis dos músculos cadastrados em cada exercício.
abstract final class MuscleAnalysisService {
  /// Palavras que identificam cada grupamento no nome do músculo. A ordem
  /// importa: "braquiorradial" precisa vir antes de "braquial".
  ///
  /// A divisão foi pensada para casar com o nível intermediário
  /// (`MuscleGroup`) da biblioteca `muscle_mapper`, prevista para o boneco:
  ///
  /// | Grupamento        | `MuscleGroup` da muscle_mapper |
  /// |-------------------|--------------------------------|
  /// | Peito             | chest                          |
  /// | Costas            | lats + lowerBack               |
  /// | Trapézio          | traps                          |
  /// | Ombros            | deltoids                       |
  /// | Bíceps            | biceps                         |
  /// | Tríceps           | triceps                        |
  /// | Antebraço         | forearms                       |
  /// | Abdômen           | abs + obliques                 |
  /// | Quadríceps        | quads                          |
  /// | Posterior de coxa | hamstrings                     |
  /// | Glúteos           | glutes                         |
  /// | Panturrilha       | calves                         |
  static const _groupKeywords = <String, List<String>>{
    'Peito': ['peitoral', 'peito', 'serrátil'],
    'Trapézio': ['trapézio'],
    'Costas': ['dorsal', 'redondo', 'romboide', 'lombar', 'costas'],
    'Ombros': ['deltoide', 'ombro'],
    'Antebraço': ['antebraço', 'braquiorradial'],
    'Bíceps': ['bíceps', 'braquial'],
    'Tríceps': ['tríceps'],
    'Abdômen': ['abdômen', 'oblíquo', 'core'],
    'Quadríceps': ['quadríceps'],
    'Posterior de coxa': ['isquiotibiais', 'posterior'],
    'Glúteos': ['glúteo'],
    'Panturrilha': ['panturrilha', 'sóleo', 'pés'],
  };

  /// Grupamento de [muscle]. Um músculo que não se encaixa em nenhum
  /// grupamento conhecido forma um grupamento com o próprio nome.
  static String groupOf(String muscle) {
    final name = muscle.trim().toLowerCase();

    // "Deltoide posterior" é ombro, não posterior de coxa
    for (final entry in _groupKeywords.entries) {
      if (entry.value.any(name.contains)) return entry.key;
    }
    return muscle.trim();
  }

  /// Músculos trabalhados por [exercise]: 3 pontos para o principal, 2 para
  /// cada um de alta ativação e 1 para cada secundário.
  static List<MuscleContribution> contributionsOf(
    Exercise exercise, {
    String? dayName,
  }) {
    MuscleContribution of(String muscle, MuscleRole role) => MuscleContribution(
          exerciseName: exercise.name,
          muscle: muscle.trim(),
          group: groupOf(muscle),
          role: role,
          dayName: dayName,
        );

    final primary = (exercise.primaryMuscle ?? exercise.muscle).trim();

    return [
      if (primary.isNotEmpty) of(primary, MuscleRole.primary),
      for (final muscle in exercise.highActivationMuscles)
        if (muscle.trim().isNotEmpty) of(muscle, MuscleRole.highActivation),
      for (final muscle in exercise.secondaryMuscles)
        if (muscle.trim().isNotEmpty) of(muscle, MuscleRole.secondary),
    ];
  }

  /// Pontuação de cada grupamento no treino [day], da maior para a menor.
  /// Em caso de empate, vale a ordem alfabética.
  static List<MuscleScore> dayScores(TrainingDay day) => _scoresOf([day]);

  /// Pontuação de cada grupamento na planilha inteira (um ciclo completo),
  /// somando todos os dias. Cada contribuição guarda o dia de origem.
  static List<MuscleScore> chartScores(TrainingChart chart) =>
      _scoresOf(chart.days, withDayName: true);

  static List<MuscleScore> _scoresOf(
    Iterable<TrainingDay> days, {
    bool withDayName = false,
  }) {
    final byGroup = <String, List<MuscleContribution>>{};
    for (final day in days) {
      for (final planned in day.exercises) {
        final contributions = contributionsOf(
          planned.exercise,
          dayName: withDayName ? day.name : null,
        );
        for (final contribution in contributions) {
          byGroup.putIfAbsent(contribution.group, () => []).add(contribution);
        }
      }
    }

    final scores = [
      for (final entry in byGroup.entries) MuscleScore(entry.key, entry.value),
    ];
    scores.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : a.group.compareTo(b.group);
    });
    return scores;
  }

  /// Quantidade de séries planejadas de cada tipo em [exercises]. Uma série
  /// com drop set conta no tipo que ela acompanha.
  static Map<SetType, int> setCounts(Iterable<WorkoutExercise> exercises) {
    final counts = {for (final type in SetType.values) type: 0};
    for (final exercise in exercises) {
      for (final set in exercise.plannedSets) {
        counts[set.type] = counts[set.type]! + 1;
      }
    }
    return counts;
  }

  /// Séries de cada tipo no treino [day].
  static Map<SetType, int> daySetCounts(TrainingDay day) =>
      setCounts(day.exercises);

  /// Séries de cada tipo na planilha inteira.
  static Map<SetType, int> chartSetCounts(TrainingChart chart) =>
      setCounts(chart.days.expand((day) => day.exercises));
}
