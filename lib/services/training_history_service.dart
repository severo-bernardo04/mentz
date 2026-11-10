import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/profile_models.dart';

/// Histórico de treinos do usuário logado, salvo em
/// `users/{uid}/sessions/{sessionId}`. A lista em memória acompanha o
/// Firestore em tempo real, e as telas são avisadas a cada mudança.
class TrainingHistoryService extends ChangeNotifier {
  static final TrainingHistoryService _instance =
      TrainingHistoryService._internal();
  factory TrainingHistoryService() => _instance;

  TrainingHistoryService._internal();

  /// Tempo máximo de espera pela confirmação do servidor. Sem internet, a
  /// escrita fica na fila do Firestore e é enviada quando a conexão voltar.
  static const _writeTimeout = Duration(seconds: 8);

  FirebaseFirestore? _firestoreOverride;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;
  List<CompletedWorkout> _sessions = [];

  /// Concluído quando a primeira leitura termina, com sucesso ou erro.
  Completer<void> _firstLoad = Completer<void>()..complete();

  /// Último erro de leitura, repassado a quem pedir as sessões.
  Object? _loadError;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  /// Coleção do usuário logado. Falha se ninguém estiver autenticado.
  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _uid;
    if (uid == null) throw StateError('Nenhum usuário autenticado.');
    return _db.collection('users').doc(uid).collection('sessions');
  }

  /// Retorna as sessões ordenadas do mais recente para o mais antigo.
  List<CompletedWorkout> get sessions {
    final list = List<CompletedWorkout>.from(_sessions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(list);
  }

  /// Começa a acompanhar o histórico de [uid].
  void watchUser(String uid) {
    if (_uid == uid) return;

    _subscription?.cancel();
    _uid = uid;
    _sessions = [];
    _loadError = null;
    _firstLoad = Completer<void>();

    _subscription = _collection.snapshots().listen(
      _onSnapshot,
      onError: _onLoadError,
    );
  }

  /// Para de acompanhar [uid] e limpa os dados dele da memória.
  /// Ignora a chamada se outro usuário já estiver sendo acompanhado.
  void stopWatching(String uid) {
    if (_uid != uid) return;

    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _sessions = [];
    _loadError = null;
    if (!_firstLoad.isCompleted) _firstLoad.complete();
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      _sessions = [
        for (final doc in snapshot.docs)
          CompletedWorkout.fromMap(doc.id, doc.data()),
      ];
      _loadError = null;
      if (!_firstLoad.isCompleted) _firstLoad.complete();
      notifyListeners();
    } catch (error) {
      _onLoadError(error);
    }
  }

  void _onLoadError(Object error) {
    _loadError = error;
    if (!_firstLoad.isCompleted) _firstLoad.complete();
  }

  /// Carrega as sessões, esperando a primeira leitura do Firestore.
  Future<List<CompletedWorkout>> loadSessions() async {
    if (!_firstLoad.isCompleted) await _firstLoad.future;

    final error = _loadError;
    if (error != null) throw error;

    return sessions;
  }

  /// Adiciona uma nova sessão concluída ao histórico.
  Future<void> addSession(CompletedWorkout session) {
    return _collection
        .doc(session.id)
        .set(session.toMap())
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Sessão mais recente de [chartId] com exercícios pendentes que ainda
  /// podem ser completados, ou null se não houver.
  CompletedWorkout? openPendingSession(String chartId) {
    for (final session in sessions) {
      if (session.chartId == chartId && session.canBeCompleted) return session;
    }
    return null;
  }

  /// Séries do último treino em que o exercício [exerciseId] foi feito, para
  /// servir de referência de carga e repetições. Ignora a sessão
  /// [excludeSessionId] (a que está sendo completada). Retorna lista vazia
  /// se o exercício nunca foi feito.
  List<ExecutedSet> previousSetsFor(
    String? exerciseId, {
    String? excludeSessionId,
  }) {
    if (exerciseId == null) return const [];

    for (final session in sessions) {
      if (session.id != null && session.id == excludeSessionId) continue;

      for (final exercise in session.executedExercises) {
        if (exercise.exerciseId != exerciseId) continue;
        if (exercise.sets.any((s) => s.reps > 0)) return exercise.sets;
      }
    }
    return const [];
  }

  /// Ignora os pendentes de [session]: ela deixa de ser oferecida para
  /// completar, mas os exercícios continuam como não realizados.
  Future<void> ignorePending(CompletedWorkout session) {
    final id = session.id;
    if (id == null) throw StateError('Sessão sem identificador.');

    return _collection
        .doc(id)
        .update({'pendingIgnored': true})
        .timeout(_writeTimeout, onTimeout: () {});
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

  /// Passa a usar um Firestore de teste, acompanhando [uid].
  @visibleForTesting
  void startForTest(FirebaseFirestore firestore, {required String uid}) {
    _subscription?.cancel();
    _uid = null;
    _firestoreOverride = firestore;
    watchUser(uid);
  }

  @visibleForTesting
  void clearForTest() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _sessions = [];
    _loadError = null;
    _firstLoad = Completer<void>()..complete();
    notifyListeners();
  }

  @visibleForTesting
  void setSessionsForTest(List<CompletedWorkout> list) {
    _sessions = List.of(list);
    notifyListeners();
  }
}
