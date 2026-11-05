import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentz/models/app_user.dart';
import 'package:mentz/models/profile_models.dart';

/// Lê e grava o perfil do usuário em `users/{uid}`.
class UserProfileService {
  UserProfileService({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  /// Perfil em tempo real. Emite `null` enquanto o documento não existe.
  Stream<AppUser?> watch(String uid) {
    return _doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : AppUser.fromMap(snap.id, data);
    });
  }

  /// Cria o documento do usuário (como aluno) se ainda não existir.
  Future<void> createIfMissing(User user, {String? name}) async {
    final ref = _doc(user.uid);
    if ((await ref.get()).exists) return;

    await ref.set({
      'name': (name ?? user.displayName ?? '').trim(),
      'email': user.email ?? '',
      'role': UserRole.student.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Atualiza só os campos informados (ex: `{'phone': '(55) 99999-0000'}`).
  Future<void> update(String uid, Map<String, dynamic> fields) =>
      _doc(uid).update(fields);
}