import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/active_workout.dart';
import '../models/app_user.dart';
import '../models/profile_models.dart';
import '../models/training_chart.dart';
import 'user_profile_service.dart';

/// Inicia, acompanha e finaliza o treino em andamento do usuário logado.
///
/// O treino ativo fica em `users/{uid}.activeSession` e é acompanhado em tempo
/// real. Ao finalizar, a sessão é criada em `users/{uid}/sessions` e o treino
/// ativo é apagado no mesmo lote (batch), então nunca sobra um sem o outro.
class WorkoutSessionService extends ChangeNotifier {
  static final WorkoutSessionService _instance =
      WorkoutSessionService._internal();
  factory WorkoutSessionService() => _instance;
  WorkoutSessionService._internal();

  /// Tempo máximo de espera pela confirmação do servidor. Sem internet, a
  /// escrita fica na fila do Firestore e é enviada quando a conexão voltar.
  static const _writeTimeout = Duration(seconds: 8);

  /// Espera após a última digitação antes de gravar as séries, para não
  /// gerar uma escrita no Firestore a cada tecla.
  static const _saveDelay = Duration(milliseconds: 800);

  static const _field = 'activeSession';

  FirebaseFirestore? _firestoreOverride;
  DateTime Function() _clock = DateTime.now;
  StreamSubscription<AppUser?>? _subscription;
  String? _uid;
  ActiveWorkout? _active;

  /// Gravação das séries agendada e ainda não enviada.
  Timer? _pendingSave;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    if (uid == null) throw StateError('Nenhum usuário autenticado.');
    return _db.collection('users').doc(uid);
  }

  /// Treino em andamento, ou null se nenhum foi iniciado.
  ActiveWorkout? get active => _active;

  /// Tempo decorrido desde o início, calculado pelo relógio a cada leitura.
  Duration get elapsed {
    final active = _active;
    if (active == null) return Duration.zero;

    final elapsed = _clock().difference(active.startedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// Começa a acompanhar o treino em andamento de [uid].
  void watchUser(String uid) {
    if (_uid == uid) return;

    _subscription?.cancel();
    _cancelPendingSave();
    _uid = uid;
    _active = null;
    _subscription = UserProfileService(firestore: _firestoreOverride)
        .watch(uid)
        .listen(_applyUser, onError: (Object _) {});
  }

  /// Para de acompanhar [uid] e limpa o treino da memória.
  /// Ignora a chamada se outro usuário já estiver sendo acompanhado.
  void stopWatching(String uid) {
    if (_uid != uid) return;

    // Envia o que foi digitado antes de sair, sem esperar a resposta
    _flushPendingSave();
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _active = null;

    // Chamado durante o descarte de widgets, quando a árvore não pode mudar
    scheduleMicrotask(notifyListeners);
  }

  /// Aplica o treino vindo do Firestore. Enquanto houver séries digitadas
  /// aqui e ainda não gravadas, a versão local vale mais que a do servidor.
  void _applyUser(AppUser? user) {
    final remote = user?.activeWorkout;
    final local = _active;

    if (remote == null) {
      if (local == null) return;
      _cancelPendingSave();
      _active = null;
    } else if (local != null &&
        local.isSameWorkout(remote) &&
        _pendingSave != null) {
      return;
    } else {
      _active = remote;
    }
    notifyListeners();
  }

  /// Inicia o treino [day] de [chart], registrando o horário de início.
  /// Com [carryFrom], os pendentes dessa sessão anterior vêm junto para serem
  /// feitos no mesmo tempo. Falha se já houver um treino em andamento.
  Future<void> start(
    TrainingChart chart,
    TrainingDay day, {
    CompletedWorkout? carryFrom,
  }) {
    final carry = carryFrom != null && carryFrom.canBeCompleted ? carryFrom : null;
    final carriedIndexes = carry?.pendingIndexes ?? const <int>[];

    return _begin(
      ActiveWorkout(
        chartId: chart.id,
        dayId: day.id,
        startedAt: _clock(),
        exercises: [
          for (final exercise in day.exercises)
            ExecutedExercise.fromPlanned(exercise),
        ],
        carriedSessionId: carry?.id,
        carriedIndexes: carriedIndexes,
        carriedExercises: [
          for (final i in carriedIndexes) carry!.executedExercises[i],
        ],
      ),
    );
  }

  /// Inicia o cronômetro só para completar os pendentes de [session].
  /// O treino atual não é contado: ao finalizar, os exercícios voltam para
  /// [session] (veja [finishCompletion]).
  Future<void> startCompletion(CompletedWorkout session) {
    if (!session.canBeCompleted) {
      throw StateError('Esta sessão não tem pendentes para completar.');
    }

    final indexes = session.pendingIndexes;
    return _begin(
      ActiveWorkout(
        chartId: session.chartId!,
        dayId: session.dayId!,
        startedAt: _clock(),
        completingSessionId: session.id,
        exerciseIndexes: indexes,
        exercises: [for (final i in indexes) session.executedExercises[i]],
      ),
    );
  }

  /// Grava [active] como o treino em andamento.
  Future<void> _begin(ActiveWorkout active) async {
    if (_active != null) {
      throw StateError('Já existe um treino em andamento.');
    }

    // Mostra o cronômetro na hora; o Firestore confirma em seguida
    _active = active;
    notifyListeners();

    try {
      await _userDoc
          .update({_field: active.toMap()})
          .timeout(_writeTimeout, onTimeout: () {});
    } catch (_) {
      _active = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Troca o exercício da posição [index] pela versão com os novos valores.
  /// Com [carried], a posição é na lista de pendentes trazidos.
  /// A tela muda na hora e a gravação no Firestore é agrupada.
  void updateExercise(
    int index,
    ExecutedExercise exercise, {
    bool carried = false,
  }) {
    final active = _active;
    if (active == null) return;

    final list = carried ? active.carriedExercises : active.exercises;
    if (index < 0 || index >= list.length) return;

    final updated = [...list]..[index] = exercise;
    _active = carried
        ? active.copyWith(carriedExercises: updated)
        : active.copyWith(exercises: updated);
    notifyListeners();

    _pendingSave?.cancel();
    _pendingSave = Timer(_saveDelay, _flushPendingSave);
  }

  /// Grava agora as séries que estavam esperando.
  void _flushPendingSave() {
    final pending = _pendingSave;
    final active = _active;
    if (pending == null || active == null || _uid == null) return;

    pending.cancel();
    _pendingSave = null;

    _userDoc
        .update({
          '$_field.exercises': active.exercises.map((e) => e.toMap()).toList(),
          if (active.hasCarried)
            '$_field.carriedExercises':
                active.carriedExercises.map((e) => e.toMap()).toList(),
        })
        .timeout(_writeTimeout, onTimeout: () {})
        .catchError((Object _) {
          debugPrint('Não foi possível salvar as séries do treino.');
        });
  }

  void _cancelPendingSave() {
    _pendingSave?.cancel();
    _pendingSave = null;
  }

  /// Finaliza o modo completar: devolve os exercícios para [original] (a
  /// sessão que estava incompleta), soma o tempo e registra a data em que foi
  /// completada. Nenhuma sessão nova é criada. Retorna a sessão atualizada.
  Future<CompletedWorkout> finishCompletion(CompletedWorkout original) async {
    final active = _active;
    if (active == null || active.completingSessionId != original.id) {
      throw StateError('Esta sessão não está sendo completada.');
    }

    _cancelPendingSave();

    final exercises = [...original.executedExercises];
    for (var i = 0; i < active.exerciseIndexes.length; i++) {
      final index = active.exerciseIndexes[i];
      if (index < 0 || index >= exercises.length) continue;
      exercises[index] = _withCompletedSets(active.exercises[i]);
    }

    final updated = original.copyWith(
      executedExercises: exercises,
      minutes: original.minutes + (elapsed.inSeconds / 60).round(),
      completedAt: _clock(),
    );

    // Só os campos que o modo completar pode mudar (as regras exigem isso)
    final sessionRef = _userDoc.collection('sessions').doc(original.id);
    final batch = _db.batch()
      ..update(sessionRef, {
        'executedExercises': exercises.map((e) => e.toMap()).toList(),
        'minutes': updated.minutes,
        'completedAt': Timestamp.fromDate(updated.completedAt!),
      })
      ..update(_userDoc, {_field: FieldValue.delete()});
    await batch.commit().timeout(_writeTimeout, onTimeout: () {});

    _active = null;
    notifyListeners();
    return updated;
  }

  /// Série com carga (ou BW) e repetições informadas conta como realizada.
  static ExecutedExercise _withCompletedSets(ExecutedExercise exercise) {
    return exercise.copyWith(
      sets: [
        for (final set in exercise.sets) set.copyWith(completed: set.isFilled),
      ],
    );
  }

  /// Finaliza o treino em andamento e salva a sessão no histórico.
  ///
  /// Se o treino trouxe pendentes de [carriedOriginal], eles voltam para essa
  /// sessão no mesmo lote, e a sessão nova ganha a marca [CarriedPending]
  /// quando algum deles foi trabalhado. Retorna a sessão salva.
  Future<CompletedWorkout> finish(
    TrainingChart chart,
    TrainingDay day, {
    CompletedWorkout? carriedOriginal,
  }) async {
    final active = _active;
    if (active == null || !active.isFor(chart.id, day.id) || active.isCompletion) {
      throw StateError('Este treino não está em andamento.');
    }

    // As séries vão junto com a sessão; não há mais o que gravar depois
    _cancelPendingSave();

    final now = _clock();
    final batch = _db.batch();

    // Pendentes trazidos: só conta o que foi trabalhado de fato
    CarriedPending? carried;
    if (active.hasCarried && carriedOriginal?.id == active.carriedSessionId) {
      final original = carriedOriginal!;
      final worked = [
        for (var i = 0; i < active.carriedExercises.length; i++)
          if (active.carriedExercises[i].wasStarted) i,
      ];

      if (worked.isNotEmpty) {
        final exercises = [...original.executedExercises];
        for (final i in worked) {
          final index = active.carriedIndexes[i];
          if (index < 0 || index >= exercises.length) continue;
          exercises[index] = _withCompletedSets(active.carriedExercises[i]);
        }

        batch.update(_userDoc.collection('sessions').doc(original.id), {
          'executedExercises': exercises.map((e) => e.toMap()).toList(),
          'completedAt': Timestamp.fromDate(now),
        });
        carried = CarriedPending(
          sessionId: original.id!,
          workoutName: original.workoutName ?? original.plan,
          date: original.date,
          exerciseNames: [for (final i in worked) active.carriedExercises[i].name],
        );
      }
    }

    final sessionRef = _userDoc.collection('sessions').doc();
    final session = CompletedWorkout(
      active.startedAt,
      day.name,
      (elapsed.inSeconds / 60).round(),
      id: sessionRef.id,
      chartId: chart.id,
      dayId: day.id,
      chartName: chart.name,
      workoutName: day.name,
      executedExercises: [
        for (final exercise in active.exercises) _withCompletedSets(exercise),
      ],
      carriedPending: carried,
    );

    // Sessão criada, anterior atualizada e treino ativo apagado juntos
    batch
      ..set(sessionRef, session.toMap())
      ..update(_userDoc, {_field: FieldValue.delete()});
    await batch.commit().timeout(_writeTimeout, onTimeout: () {});

    _active = null;
    notifyListeners();
    return session;
  }

  /// Descarta o treino em andamento sem salvar nada no histórico.
  Future<void> discard() async {
    if (_active == null) return;

    _cancelPendingSave();
    await _userDoc
        .update({_field: FieldValue.delete()})
        .timeout(_writeTimeout, onTimeout: () {});

    _active = null;
    notifyListeners();
  }

  /// Passa a usar um Firestore e um relógio de teste, acompanhando [uid].
  @visibleForTesting
  void startForTest(
    FirebaseFirestore firestore, {
    required String uid,
    DateTime Function()? clock,
  }) {
    _subscription?.cancel();
    _cancelPendingSave();
    _uid = null;
    _active = null;
    _firestoreOverride = firestore;
    _clock = clock ?? DateTime.now;
    watchUser(uid);
  }

  /// Envia já a gravação agendada, sem esperar o atraso.
  @visibleForTesting
  void flushForTest() => _flushPendingSave();
}
