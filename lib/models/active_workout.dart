import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_models.dart';

/// Treino em andamento, guardado no campo `activeSession` de `users/{uid}`.
///
/// Fica no Firestore (e não só na memória) para o cronômetro e as séries já
/// registradas sobreviverem ao app ser fechado pelo sistema e continuarem
/// certos em outro aparelho. O tempo é sempre calculado a partir de
/// [startedAt] e das pausas ([pausedAt], [pausedDuration]), nunca contado por
/// um timer.
///
/// Há dois modos:
/// - treino novo: [exercises] são todos os exercícios do dia. Pode trazer
///   junto os pendentes de uma sessão anterior ([carriedSessionId]), feitos
///   no mesmo tempo; ao finalizar, eles voltam para aquela sessão;
/// - completar pendentes ([completingSessionId] preenchido): [exercises] são
///   só os pendentes de uma sessão anterior, nas posições [exerciseIndexes]
///   dela. Ao finalizar, eles voltam para essa sessão e nenhum treino novo é
///   contado.
class ActiveWorkout {
  final String chartId;
  final String dayId;
  final DateTime startedAt;

  /// Exercícios com as cargas e repetições registradas até agora.
  final List<ExecutedExercise> exercises;

  /// Sessão anterior sendo completada; null em um treino novo.
  final String? completingSessionId;

  /// Posição de cada item de [exercises] na sessão sendo completada.
  final List<int> exerciseIndexes;

  /// Sessão anterior cujos pendentes vieram junto com este treino novo.
  final String? carriedSessionId;

  /// Pendentes trazidos, com os valores registrados até agora.
  final List<ExecutedExercise> carriedExercises;

  /// Posição de cada item de [carriedExercises] na sessão anterior.
  final List<int> carriedIndexes;

  /// Quando a pausa em curso começou; null com o cronômetro correndo.
  final DateTime? pausedAt;

  /// Soma das pausas já encerradas (o tempo em que o treino ficou parado).
  final Duration pausedDuration;

  const ActiveWorkout({
    required this.chartId,
    required this.dayId,
    required this.startedAt,
    this.exercises = const [],
    this.completingSessionId,
    this.exerciseIndexes = const [],
    this.carriedSessionId,
    this.carriedExercises = const [],
    this.carriedIndexes = const [],
    this.pausedAt,
    this.pausedDuration = Duration.zero,
  });

  /// O cronômetro está pausado.
  bool get isPaused => pausedAt != null;

  /// Tempo de treino em [now], sem contar as pausas. Durante uma pausa o
  /// valor fica congelado no instante em que ela começou.
  Duration elapsedAt(DateTime now) {
    final end = pausedAt ?? now;
    final elapsed = end.difference(startedAt) - pausedDuration;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Início "equivalente": o instante de que o treino teria começado se nunca
  /// houvesse pausa. Serve a quem só sabe contar a partir de um início (a
  /// janela flutuante e a notificação).
  DateTime get effectiveStart => startedAt.add(pausedDuration);

  /// Indica se o treino em andamento só completa uma sessão anterior.
  bool get isCompletion => completingSessionId != null;

  /// Indica se este treino trouxe pendentes de uma sessão anterior.
  bool get hasCarried => carriedSessionId != null;

  /// Indica se este é o treino de [dayId] na planilha [chartId].
  bool isFor(String chartId, String dayId) =>
      this.chartId == chartId && this.dayId == dayId;

  /// Indica se [other] é o mesmo treino, mesmo com séries diferentes.
  bool isSameWorkout(ActiveWorkout other) =>
      isFor(other.chartId, other.dayId) &&
          startedAt == other.startedAt &&
          completingSessionId == other.completingSessionId &&
          carriedSessionId == other.carriedSessionId;

  ActiveWorkout copyWith({
    List<ExecutedExercise>? exercises,
    List<ExecutedExercise>? carriedExercises,
  }) => _copy(exercises: exercises, carriedExercises: carriedExercises);

  /// Versão pausada em [now]. Sem efeito se já estiver pausado.
  ActiveWorkout paused(DateTime now) => isPaused ? this : _copy(pausedAt: now);

  /// Versão retomada em [now]: o tempo parado entra em [pausedDuration].
  /// Sem efeito se não estiver pausado.
  ActiveWorkout resumed(DateTime now) {
    final since = pausedAt;
    if (since == null) return this;

    final gap = now.difference(since);
    return _copy(
      clearPause: true,
      pausedDuration: pausedDuration + (gap.isNegative ? Duration.zero : gap),
    );
  }

  ActiveWorkout _copy({
    List<ExecutedExercise>? exercises,
    List<ExecutedExercise>? carriedExercises,
    DateTime? pausedAt,
    bool clearPause = false,
    Duration? pausedDuration,
  }) {
    return ActiveWorkout(
      chartId: chartId,
      dayId: dayId,
      startedAt: startedAt,
      exercises: exercises ?? this.exercises,
      completingSessionId: completingSessionId,
      exerciseIndexes: exerciseIndexes,
      carriedSessionId: carriedSessionId,
      carriedExercises: carriedExercises ?? this.carriedExercises,
      carriedIndexes: carriedIndexes,
      pausedAt: clearPause ? null : (pausedAt ?? this.pausedAt),
      pausedDuration: pausedDuration ?? this.pausedDuration,
    );
  }

  Map<String, dynamic> toMap() => {
    'chartId': chartId,
    'dayId': dayId,
    'startedAt': Timestamp.fromDate(startedAt),
    'exercises': exercises.map((e) => e.toMap()).toList(),
    if (pausedAt != null) 'pausedAt': Timestamp.fromDate(pausedAt!),
    if (pausedDuration > Duration.zero)
      'pausedMs': pausedDuration.inMilliseconds,
    if (completingSessionId != null) ...{
      'completingSessionId': completingSessionId,
      'exerciseIndexes': exerciseIndexes,
    },
    if (carriedSessionId != null) ...{
      'carriedSessionId': carriedSessionId,
      'carriedExercises': carriedExercises.map((e) => e.toMap()).toList(),
      'carriedIndexes': carriedIndexes,
    },
  };

  /// Retorna null se o campo estiver ausente ou incompleto.
  static ActiveWorkout? tryFromMap(Object? data) {
    if (data is! Map) return null;

    final chartId = data['chartId'];
    final dayId = data['dayId'];
    final startedAt = data['startedAt'];
    if (chartId is! String || dayId is! String || startedAt is! Timestamp) {
      return null;
    }

    final exercises = _exercisesFrom(data['exercises']);
    final completingSessionId = data['completingSessionId'] as String?;
    final indexes = _indexesFrom(data['exerciseIndexes']);
    final carriedSessionId = data['carriedSessionId'] as String?;
    final carriedExercises = _exercisesFrom(data['carriedExercises']);
    final carriedIndexes = _indexesFrom(data['carriedIndexes']);
    final pausedAt = data['pausedAt'];
    final pausedMs = data['pausedMs'];

    // Sem as posições certas, os exercícios não teriam onde ser salvos
    if (completingSessionId != null && indexes.length != exercises.length) {
      return null;
    }
    final carriedValid =
        carriedSessionId != null &&
            carriedIndexes.length == carriedExercises.length;

    return ActiveWorkout(
      chartId: chartId,
      dayId: dayId,
      startedAt: startedAt.toDate(),
      exercises: exercises,
      completingSessionId: completingSessionId,
      exerciseIndexes: indexes,
      carriedSessionId: carriedValid ? carriedSessionId : null,
      carriedExercises: carriedValid ? carriedExercises : const [],
      carriedIndexes: carriedValid ? carriedIndexes : const [],
      pausedAt: pausedAt is Timestamp ? pausedAt.toDate() : null,
      pausedDuration: pausedMs is num
          ? Duration(milliseconds: pausedMs.toInt())
          : Duration.zero,
    );
  }

  static List<ExecutedExercise> _exercisesFrom(Object? data) =>
      (data as List?)
          ?.map((e) =>
          ExecutedExercise.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList() ??
          const [];

  static List<int> _indexesFrom(Object? data) =>
      (data as List?)?.map((i) => (i as num).toInt()).toList() ?? const [];
}