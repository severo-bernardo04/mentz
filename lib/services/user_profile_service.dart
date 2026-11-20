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
  Future<void> createIfMissing(
    User user, {
    String? name,
    DateTime? birthDate,
    String? sex,
    double? heightCm,
    double? weight,
  }) async {
    final ref = _doc(user.uid);
    if ((await ref.get()).exists) return;

    final data = <String, dynamic>{
      'name': (name ?? user.displayName ?? '').trim(),
      'email': user.email ?? '',
      'role': UserRole.student.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (birthDate != null) data['birthDate'] = Timestamp.fromDate(birthDate);
    if (sex != null && sex.isNotEmpty) data['sex'] = sex;
    if (heightCm != null && heightCm > 0) data['heightCm'] = heightCm;
    if (weight != null && weight > 0) {
      data['weight'] = weight;
      data['weightHistory'] = [
        {'date': Timestamp.now(), 'kg': weight}
      ];
    }

    await ref.set(data);
  }

  /// Atualiza só os campos informados (ex: `{'phone': '(55) 99999-0000'}`).
  Future<void> update(String uid, Map<String, dynamic> fields) =>
      _doc(uid).update(fields);

  /// Atualiza medidas físicas (altura, peso, nascimento, sexo) do usuário.
  /// Se [weightKg] for informado, também adiciona ao [weightHistory].
  Future<void> updatePhysicalMeasures(
    String uid, {
    double? heightCm,
    double? weightKg,
    DateTime? birthDate,
    String? sex,
    List<WeightEntry>? existingHistory,
  }) async {
    final fields = <String, dynamic>{};
    if (birthDate != null) {
      fields['birthDate'] = Timestamp.fromDate(birthDate);
    }
    if (sex != null && sex.isNotEmpty) {
      fields['sex'] = sex;
    }
    if (heightCm != null && heightCm > 0) {
      fields['heightCm'] = heightCm;
    }
    if (weightKg != null && weightKg > 0) {
      fields['weight'] = weightKg;
      final history = [
        ...?existingHistory,
        WeightEntry(DateTime.now(), weightKg),
      ];
      fields['weightHistory'] = [
        for (final w in history)
          {
            'date': Timestamp.fromDate(w.date),
            'kg': w.kg,
          }
      ];
    }
    if (fields.isNotEmpty) {
      await update(uid, fields);
    }
  }
}