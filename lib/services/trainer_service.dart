import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/profile_models.dart';
import 'exercise_catalog_service.dart';

/// Dados do treinador logado: alunos vinculados, fichas e agenda.
///
/// Onde ficam no Firestore:
/// - alunos: documentos de `users` com `trainerId == uid do treinador`;
/// - fichas: `users/{uid}/plans/{planId}`;
/// - agenda: `users/{uid}/appointments/{appointmentId}`;
/// - alunos já vistos como "novos": campo `seenStudentIds` de `users/{uid}`.
///
/// As listas em memória acompanham o Firestore em tempo real, e as telas são
/// avisadas por [notifyListeners] a cada mudança.
class TrainerService extends ChangeNotifier {
  static final TrainerService _instance = TrainerService._internal();
  factory TrainerService() => _instance;
  TrainerService._internal() {
    // Refaz as fichas quando o catálogo chega ou muda
    ExerciseCatalogService().addListener(_rebuildPlans);
  }

  /// Tempo máximo de espera pela confirmação do servidor. Sem internet, a
  /// escrita fica na fila do Firestore e é enviada quando a conexão voltar.
  static const _writeTimeout = Duration(seconds: 8);

  FirebaseFirestore? _firestoreOverride;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _plansSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _appointmentsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studentsSub;
  QuerySnapshot<Map<String, dynamic>>? _lastPlansSnapshot;
  String? _uid;

  List<StudentSummary> _students = [];
  List<WorkoutPlan> _plans = [];
  List<Appointment> _appointments = [];

  bool _studentsReady = false;
  bool _plansReady = false;
  bool _appointmentsReady = false;
  String? _errorMessage;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  List<StudentSummary> get students => List.unmodifiable(_students);
  List<WorkoutPlan> get plans => List.unmodifiable(_plans);
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  /// Verdadeiro até a primeira leitura de alunos, fichas e agenda terminar.
  bool get loading =>
      _uid != null && !(_studentsReady && _plansReady && _appointmentsReady);

  String? get errorMessage => _errorMessage;

  /// Documento do treinador logado. Falha se ninguém estiver sendo acompanhado.
  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    if (uid == null) throw StateError('Nenhum treinador acompanhado.');
    return _db.collection('users').doc(uid);
  }

  /// Começa a acompanhar os dados do treinador [uid].
  void watchUser(String uid) {
    if (_uid == uid) return;

    _cancelSubscriptions();
    _clear();
    _uid = uid;

    final doc = _db.collection('users').doc(uid);

    _studentsSub = _db
        .collection('users')
        .where('trainerId', isEqualTo: uid)
        .snapshots()
        .listen(_onStudents, onError: (Object _) {
      _studentsReady = true;
      _onLoadError();
    });

    _plansSub = doc.collection('plans').snapshots().listen(_onPlans,
        onError: (Object _) {
          _plansReady = true;
          _onLoadError();
        });

    _appointmentsSub = doc.collection('appointments').snapshots().listen(
      _onAppointments,
      onError: (Object _) {
        _appointmentsReady = true;
        _onLoadError();
      },
    );
  }

  /// Para de acompanhar [uid] e limpa os dados dele da memória.
  /// Ignora a chamada se outro treinador já estiver sendo acompanhado.
  void stopWatching(String uid) {
    if (_uid != uid) return;

    _cancelSubscriptions();
    _clear();
  }

  void _cancelSubscriptions() {
    _studentsSub?.cancel();
    _plansSub?.cancel();
    _appointmentsSub?.cancel();
    _studentsSub = _plansSub = _appointmentsSub = null;
  }

  void _clear() {
    _uid = null;
    _lastPlansSnapshot = null;
    _students = [];
    _plans = [];
    _appointments = [];
    _studentsReady = _plansReady = _appointmentsReady = false;
    _errorMessage = null;
  }

  void _onStudents(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      _students = [
        for (final doc in snapshot.docs)
          StudentSummary.fromMap(doc.id, doc.data()),
      ]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _studentsReady = true;
      notifyListeners();
    } catch (_) {
      _studentsReady = true;
      _onLoadError();
    }
  }

  void _onPlans(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _lastPlansSnapshot = snapshot;
    _rebuildPlans();
  }

  /// Monta as fichas com os dados do catálogo, assim que ele estiver pronto.
  void _rebuildPlans() {
    final snapshot = _lastPlansSnapshot;
    final catalog = ExerciseCatalogService();
    if (snapshot == null || !catalog.isLoaded) return;

    try {
      _plans = [
        for (final doc in snapshot.docs)
          WorkoutPlan.fromMap(
            doc.id,
            doc.data(),
            findExercise: catalog.findById,
          ),
      ]..sort((a, b) => a.name.compareTo(b.name));
      _plansReady = true;
      notifyListeners();
    } catch (_) {
      _plansReady = true;
      _onLoadError();
    }
  }

  void _onAppointments(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      _appointments = [
        for (final doc in snapshot.docs)
          Appointment.fromMap(doc.id, doc.data()),
      ];
      _appointmentsReady = true;
      notifyListeners();
    } catch (_) {
      _appointmentsReady = true;
      _onLoadError();
    }
  }

  void _onLoadError() {
    _errorMessage = 'Não foi possível carregar todos os seus dados.';
    notifyListeners();
  }

  /// Salva uma nova ficha ou atualiza uma existente.
  Future<void> savePlan(WorkoutPlan plan) {
    return _userDoc
        .collection('plans')
        .doc(plan.id)
        .set(plan.toMap())
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Remove uma ficha pelo ID.
  Future<void> deletePlan(String id) {
    return _userDoc
        .collection('plans')
        .doc(id)
        .delete()
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Salva um novo compromisso ou atualiza um existente.
  Future<void> saveAppointment(Appointment appointment) {
    return _userDoc
        .collection('appointments')
        .doc(appointment.id)
        .set(appointment.toMap())
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Muda só a situação do compromisso (realizado, falta ou agendado),
  /// sem tocar no restante dele.
  Future<void> setAppointmentStatus(String id, AppointmentStatus status) {
    return _userDoc
        .collection('appointments')
        .doc(id)
        .update({'status': status.name})
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Marca o aluno como já visto, para sair do aviso de novos alunos.
  Future<void> markStudentSeen(String studentId) {
    return _userDoc
        .update({
      'seenStudentIds': FieldValue.arrayUnion([studentId]),
    })
        .timeout(_writeTimeout, onTimeout: () {});
  }

  /// Passa a usar um Firestore de teste, acompanhando [uid].
  @visibleForTesting
  void startForTest(FirebaseFirestore firestore, {required String uid}) {
    resetForTest();
    _firestoreOverride = firestore;
    watchUser(uid);
  }

  /// Para tudo e volta ao Firestore real.
  @visibleForTesting
  void resetForTest() {
    _cancelSubscriptions();
    _clear();
    _firestoreOverride = null;
  }
}