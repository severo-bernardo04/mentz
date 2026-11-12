import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/profile_models.dart';
import '../../../models/training_chart.dart';
import '../../../services/training_chart_service.dart';
import '../../../services/training_history_service.dart';
import '../../../services/workout_schedule_service.dart';
import '../../../services/workout_session_service.dart';

/// Estado da tela de um treino: se está em andamento, o tempo decorrido, os
/// exercícios pendentes (deste e de treinos anteriores) e as ações de
/// iniciar, completar, ignorar, finalizar e descartar.
///
/// O tempo vem do [WorkoutSessionService], calculado pelo horário de início.
/// O timer daqui só pede para a tela redesenhar a cada segundo, então sair e
/// voltar para a tela não altera a contagem.
class WorkoutSessionController extends ChangeNotifier {
  final TrainingChart chart;
  final TrainingDay day;
  final WorkoutSessionService _service;
  final TrainingHistoryService _history;

  Timer? _ticker;
  bool _busy = false;
  String? _errorMessage;

  WorkoutSessionController({
    required this.chart,
    required this.day,
    WorkoutSessionService? service,
    TrainingHistoryService? history,
  }) : _service = service ?? WorkoutSessionService(),
       _history = history ?? TrainingHistoryService() {
    _service.addListener(_onChanged);
    _history.addListener(_onChanged);
    _syncTicker();
  }

  bool get busy => _busy;
  String? get errorMessage => _errorMessage;

  /// Este dia está com o cronômetro rodando (treino novo ou completando).
  bool get isRunning => _service.active?.isFor(chart.id, day.id) ?? false;

  /// O cronômetro está rodando só para completar uma sessão anterior.
  bool get isCompleting => isRunning && _service.active!.isCompletion;

  /// Outro treino está em andamento, o que impede iniciar este.
  bool get otherIsRunning => _service.active != null && !isRunning;

  /// Nome do outro treino em andamento, quando a planilha ainda existir.
  String? get otherWorkoutName {
    final active = _service.active;
    if (active == null || isRunning) return null;

    for (final chart in TrainingChartService().charts) {
      if (chart.id != active.chartId) continue;
      for (final day in chart.days) {
        if (day.id == active.dayId) return day.name;
      }
    }
    return null;
  }

  /// Próximo treino programado desta planilha, pelo ciclo e pelo histórico.
  NextWorkout? get nextWorkout =>
      WorkoutScheduleService.nextWorkout(chart, _history.sessions);

  Duration get elapsed => isRunning ? _service.elapsed : Duration.zero;

  DateTime? get startedAt => isRunning ? _service.active!.startedAt : null;

  /// Sessão sendo completada agora, quando o modo completar está ativo.
  CompletedWorkout? get completingSession =>
      isCompleting ? _sessionById(_service.active!.completingSessionId) : null;

  /// Sessão anterior cujos pendentes vieram junto com este treino.
  CompletedWorkout? get carriedSession =>
      isRunning ? _sessionById(_service.active!.carriedSessionId) : null;

  /// Pendentes trazidos de um treino anterior, com os valores registrados.
  List<ExecutedExercise> get carriedExercises =>
      isRunning ? _service.active!.carriedExercises : const [];

  CompletedWorkout? _sessionById(String? id) {
    if (id == null) return null;
    for (final session in _history.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Sessão anterior desta planilha com pendentes para completar. Só é
  /// oferecida com nenhum treino em andamento.
  CompletedWorkout? get previousPending => _service.active != null
      ? null
      : _history.openPendingSession(chart.id);

  /// Exercícios exibidos com campos de carga e repetições; null enquanto o
  /// cronômetro deste dia não estiver rodando.
  List<ExecutedExercise>? get executed {
    if (!isRunning) return null;

    final exercises = _service.active!.exercises;
    if (isCompleting) return exercises;

    // Treino iniciado sem séries salvas: segue o que está planejado
    return exercises.length == day.exercises.length ? exercises : null;
  }

  /// Todos os exercícios da tela, em uma só lista: os do treino e, em
  /// seguida, os pendentes trazidos. As posições usadas pela tela
  /// ([pendingIndexes], [updateExercise]) seguem esta lista.
  List<ExecutedExercise> get allExercises =>
      [...?executed, ...carriedExercises];

  /// Quantos itens de [allExercises] são do treino (o resto são trazidos).
  int get ownCount => executed?.length ?? 0;

  /// Exercício planejado correspondente à posição [index] da tela, para
  /// mostrar o descanso sugerido. Pode ser null se saiu da planilha.
  WorkoutExercise? plannedAt(int index) {
    if (!isCompleting && index < day.exercises.length) {
      return day.exercises[index];
    }

    // Completar ou pendente trazido: procura o exercício na planilha
    final exerciseId = allExercises[index].exerciseId;
    for (final chartDay in chart.days) {
      for (final planned in chartDay.exercises) {
        if (planned.exercise.id == exerciseId) return planned;
      }
    }
    return null;
  }

  /// Séries do último treino em que o exercício foi feito, como referência.
  /// A sessão anterior em aberto não serve: ela é a que está sendo feita.
  List<ExecutedSet> previousSetsFor(String? exerciseId) {
    final active = _service.active;
    return _history.previousSetsFor(
      exerciseId,
      excludeSessionId: active?.completingSessionId ?? active?.carriedSessionId,
    );
  }

  /// Posições (em [allExercises]) dos exercícios não marcados como feitos.
  List<int> get pendingIndexes {
    if (executed == null) return const [];
    final exercises = allExercises;
    return [
      for (var i = 0; i < exercises.length; i++)
        if (!exercises[i].completed) i,
    ];
  }

  /// Registra as alterações de carga, repetições ou "feito" do exercício na
  /// posição [index] de [allExercises].
  void updateExercise(int index, ExecutedExercise exercise) {
    final own = ownCount;
    if (index < own) {
      _service.updateExercise(index, exercise);
    } else {
      _service.updateExercise(index - own, exercise, carried: true);
    }
  }

  void _onChanged() {
    _syncTicker();
    notifyListeners();
  }

  /// Liga o timer de redesenho só enquanto este treino estiver em andamento.
  void _syncTicker() {
    if (isRunning) {
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => notifyListeners(),
      );
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// Inicia o treino. Com [carryFrom], os pendentes dessa sessão anterior
  /// aparecem junto para serem feitos no mesmo tempo.
  Future<bool> start({CompletedWorkout? carryFrom}) => _run(
        () => _service.start(chart, day, carryFrom: carryFrom),
        'Não foi possível iniciar o treino.',
      );

  /// Inicia o cronômetro só para completar os pendentes de [session].
  Future<bool> startCompletion(CompletedWorkout session) => _run(
        () => _service.startCompletion(session),
        'Não foi possível iniciar o cronômetro.',
      );

  /// Deixa de oferecer os pendentes de [session] para completar.
  Future<bool> ignorePending(CompletedWorkout session) => _run(
        () => _history.ignorePending(session),
        'Não foi possível ignorar os pendentes.',
      );

  Future<bool> discard() =>
      _run(_service.discard, 'Não foi possível descartar o treino.');

  /// Finaliza (treino novo ou completar) e retorna a sessão salva, ou null
  /// em caso de erro.
  Future<CompletedWorkout?> finish() async {
    CompletedWorkout? session;
    final ok = await _run(() async {
      if (isCompleting) {
        final original = completingSession;
        if (original == null) {
          throw StateError('Sessão a completar não encontrada.');
        }
        session = await _service.finishCompletion(original);
      } else {
        session = await _service.finish(
          chart,
          day,
          carriedOriginal: carriedSession,
        );
      }
    }, 'Não foi possível finalizar o treino.');
    return ok ? session : null;
  }

  /// Executa [action] marcando a tela como ocupada e guardando o erro.
  Future<bool> _run(Future<void> Function() action, String error) async {
    if (_busy) return false;

    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _service.removeListener(_onChanged);
    _history.removeListener(_onChanged);
    super.dispose();
  }
}
