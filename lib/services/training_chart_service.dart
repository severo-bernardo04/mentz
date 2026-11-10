import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/training_chart.dart';
import 'exercise_catalog_service.dart';

/// Planilhas do usuário logado, salvas em `users/{uid}/charts/{chartId}`.
/// A lista em memória acompanha o Firestore em tempo real, e as telas são
/// avisadas por [notifyListeners] a cada mudança.
class TrainingChartService extends ChangeNotifier {
  static final TrainingChartService _instance = TrainingChartService._internal();
  factory TrainingChartService() => _instance;
  TrainingChartService._internal() {
    // Refaz as planilhas quando o catálogo chega ou muda
    ExerciseCatalogService().addListener(_rebuildCharts);
  }

  /// Tempo máximo de espera pela confirmação do servidor. Sem internet, a
  /// escrita fica na fila do Firestore e é enviada quando a conexão voltar.
  static const _writeTimeout = Duration(seconds: 8);

  FirebaseFirestore? _firestoreOverride;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  QuerySnapshot<Map<String, dynamic>>? _lastSnapshot;
  String? _uid;
  List<TrainingChart> _charts = [];
  bool _loading = false;
  String? _errorMessage;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  List<TrainingChart> get charts => List.unmodifiable(_charts);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// Coleção do usuário logado. Falha se ninguém estiver autenticado.
  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _uid;
    if (uid == null) throw StateError('Nenhum usuário autenticado.');
    return _db.collection('users').doc(uid).collection('charts');
  }

  /// Começa a acompanhar as planilhas de [uid], da mais recente para a mais antiga.
  void watchUser(String uid) {
    if (_uid == uid) return;

    _subscription?.cancel();
    _uid = uid;
    _lastSnapshot = null;
    _charts = [];
    _loading = true;
    _errorMessage = null;

    _subscription = _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (Object _) => _onLoadError());
  }

  /// Para de acompanhar [uid] e limpa os dados dele da memória.
  /// Ignora a chamada se outro usuário já estiver sendo acompanhado.
  void stopWatching(String uid) {
    if (_uid != uid) return;

    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _lastSnapshot = null;
    _charts = [];
    _loading = false;
    _errorMessage = null;
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _lastSnapshot = snapshot;
    _rebuildCharts();
  }

  /// Monta as planilhas com os dados do catálogo, assim que ele estiver pronto.
  void _rebuildCharts() {
    final snapshot = _lastSnapshot;
    final catalog = ExerciseCatalogService();
    if (snapshot == null || !catalog.isLoaded) return;

    try {
      _charts = [
        for (final doc in snapshot.docs)
          TrainingChart.fromMap(
            doc.id,
            doc.data(),
            findExercise: catalog.findById,
          ),
      ];
      _loading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _onLoadError();
    }
  }

  void _onLoadError() {
    _loading = false;
    _errorMessage = 'Não foi possível carregar suas planilhas.';
    notifyListeners();
  }

  /// Salva uma nova planilha ou atualiza uma existente.
  Future<void> saveChart(TrainingChart chart) {
    return _collection
        .doc(chart.id)
        .set(chart.toMap())
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Remove uma planilha pelo ID.
  Future<void> deleteChart(String id) {
    return _collection.doc(id).delete().timeout(_writeTimeout, onTimeout: () {});
  }

  /// Passa a usar um Firestore de teste, acompanhando [uid].
  @visibleForTesting
  void startForTest(FirebaseFirestore firestore, {required String uid}) {
    _subscription?.cancel();
    _uid = null;
    _firestoreOverride = firestore;
    watchUser(uid);
  }
}
