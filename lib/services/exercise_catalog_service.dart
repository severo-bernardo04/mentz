import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/profile_models.dart';

/// Catálogo oficial de exercícios, lido da coleção `exercises` do Firestore.
/// É somente leitura no app: o conteúdo vem de `tools/import_catalog.js`.
class ExerciseCatalogService extends ChangeNotifier {
  static final ExerciseCatalogService _instance =
      ExerciseCatalogService._internal();
  factory ExerciseCatalogService() => _instance;

  ExerciseCatalogService._internal();

  FirebaseFirestore? _firestoreOverride;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;
  List<Exercise> _exercises = [];
  bool _isLoaded = false;
  Object? _loadError;

  /// Concluído quando a primeira leitura termina, com sucesso ou erro.
  Completer<void> _firstLoad = Completer<void>()..complete();

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  List<Exercise> get exercises => List.unmodifiable(_exercises);

  /// Indica que a primeira leitura terminou, mesmo que tenha falhado.
  bool get isLoaded => _isLoaded;

  /// Começa a acompanhar o catálogo enquanto [uid] estiver logado,
  /// porque as regras do Firestore exigem um usuário autenticado.
  void watchUser(String uid) {
    if (_uid == uid) return;

    _subscription?.cancel();
    _uid = uid;
    _exercises = [];
    _isLoaded = false;
    _loadError = null;
    _firstLoad = Completer<void>();

    _subscription = _db.collection('exercises').snapshots().listen(
      _onSnapshot,
      onError: _onLoadError,
    );
  }

  /// Para de acompanhar o catálogo ao sair da conta de [uid].
  /// Ignora a chamada se outro usuário já estiver logado.
  void stopWatching(String uid) {
    if (_uid != uid) return;

    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _exercises = [];
    _isLoaded = false;
    _loadError = null;
    if (!_firstLoad.isCompleted) _firstLoad.complete();
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      _exercises = [
        for (final doc in snapshot.docs) Exercise.fromMap(doc.id, doc.data()),
      ]..sort((a, b) => a.name.compareTo(b.name));
      _loadError = null;
      _finishLoad();
    } catch (error) {
      _onLoadError(error);
    }
  }

  void _onLoadError(Object error) {
    _loadError = error;
    _finishLoad();
  }

  void _finishLoad() {
    _isLoaded = true;
    if (!_firstLoad.isCompleted) _firstLoad.complete();
    notifyListeners();
  }

  /// Carrega os exercícios, esperando a primeira leitura do Firestore.
  Future<List<Exercise>> loadExercises() async {
    if (!_firstLoad.isCompleted) await _firstLoad.future;

    final error = _loadError;
    if (error != null) throw error;

    return exercises;
  }

  /// Busca um exercício pelo identificador fixo; null se não existir.
  Exercise? findById(String id) {
    for (final exercise in _exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  List<Exercise> search({String? query, String? muscleGroup}) {
    return _exercises.where((e) {
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          e.name.toLowerCase().contains(query.trim().toLowerCase()) ||
          (e.nameEn?.toLowerCase().contains(query.trim().toLowerCase()) ?? false);

      final matchesMuscle = muscleGroup == null ||
          muscleGroup.isEmpty ||
          muscleGroup == 'Todos' ||
          e.muscle.toLowerCase() == muscleGroup.toLowerCase() ||
          (e.primaryMuscle?.toLowerCase().contains(muscleGroup.toLowerCase()) ??
              false);

      return matchesQuery && matchesMuscle;
    }).toList();
  }

  List<String> getAvailableMuscleGroups() {
    final groups = <String>{'Todos'};
    for (final e in _exercises) {
      if (e.muscle.isNotEmpty) {
        groups.add(e.muscle);
      }
    }
    return groups.toList();
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
  void clearForTest() => setExercisesForTest([]);

  /// Define o catálogo diretamente, sem usar o Firestore.
  @visibleForTesting
  void setExercisesForTest(List<Exercise> list) {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _exercises = List.of(list);
    _loadError = null;
    _isLoaded = true;
    _firstLoad = Completer<void>()..complete();
    notifyListeners();
  }
}
