import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentz/models/profile_models.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final DateTime? createdAt;
  final String? photoBase64;

  // Preferências guardadas no campo `settings` do documento
  final String? themeMode;
  final String? language;
  final String? timerDisplayMode;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.createdAt,
    this.photoBase64,
    this.themeMode,
    this.language,
    this.timerDisplayMode,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final settings = map['settings'] as Map<String, dynamic>? ?? const {};

    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
            (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      phone: map['phone'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      photoBase64: map['photoBase64'] as String?,
      themeMode: settings['themeMode'] as String?,
      language: settings['language'] as String?,
      timerDisplayMode: settings['timerDisplayMode'] as String?,
    );
  }
}