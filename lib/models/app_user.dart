import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentz/models/active_workout.dart';
import 'package:mentz/models/profile_models.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final DateTime? createdAt;
  final String? photoBase64;
  final DateTime? birthDate;
  final String? sex;

  // Medidas corporais (estudante / usuário)
  final double? heightCm;
  final List<WeightEntry> weightHistory;

  // Preferências guardadas no campo `settings` do documento
  final String? themeMode;
  final String? language;
  final String? timerDisplayMode;

  /// Aceite dos Termos de Uso, guardado no campo `termsAcceptance`.
  /// Fica nulo em contas criadas antes dos termos existirem.
  final String? termsVersion;
  final DateTime? termsAcceptedAt;

  /// Treino em andamento, guardado no campo `activeSession`.
  final ActiveWorkout? activeWorkout;

  // Dados profissionais, guardados no campo `trainer` do documento.
  // Só existem para treinadores e só aparecem se tiverem sido cadastrados.
  final TrainerRole? trainerRole;
  final String? cref;
  final List<String> specialties;
  final List<String> qualifications;
  final int? experienceYears;
  final Map<String, String> availability; // dia → horário
  final bool? employmentActive;
  final bool canViewBilling;

  /// uids dos alunos vinculados que o treinador já viu como "novos",
  /// guardados no campo `seenStudentIds`.
  final List<String> seenStudentIds;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.createdAt,
    this.photoBase64,
    this.birthDate,
    this.sex,
    this.heightCm,
    this.weightHistory = const [],
    this.themeMode,
    this.language,
    this.timerDisplayMode,
    this.termsVersion,
    this.termsAcceptedAt,
    this.activeWorkout,
    this.trainerRole,
    this.cref,
    this.specialties = const [],
    this.qualifications = const [],
    this.experienceYears,
    this.availability = const {},
    this.employmentActive,
    this.canViewBilling = false,
    this.seenStudentIds = const [],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final settings = map['settings'] as Map<String, dynamic>? ?? const {};
    final trainer =
    Map<String, dynamic>.from(map['trainer'] as Map? ?? const {});
    final terms = Map<String, dynamic>.from(
      map['termsAcceptance'] as Map? ?? const {},
    );

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
      birthDate: (map['birthDate'] as Timestamp?)?.toDate() ??
          (map['birthDate'] is String
              ? DateTime.tryParse(map['birthDate'] as String)
              : null),
      sex: map['sex'] as String?,
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightHistory: _parseWeightHistory(map['weightHistory'], map['weight']),
      themeMode: settings['themeMode'] as String?,
      language: settings['language'] as String?,
      timerDisplayMode: settings['timerDisplayMode'] as String?,
      termsVersion: terms['version'] as String?,
      termsAcceptedAt: (terms['acceptedAt'] as Timestamp?)?.toDate(),
      activeWorkout: ActiveWorkout.tryFromMap(map['activeSession']),
      trainerRole: TrainerRole.values
          .where((r) => r.name == trainer['role'])
          .firstOrNull,
      cref: trainer['cref'] as String?,
      specialties: _strings(trainer['specialties']),
      qualifications: _strings(trainer['qualifications']),
      experienceYears: (trainer['experienceYears'] as num?)?.toInt(),
      availability: {
        for (final e in Map<String, dynamic>.from(
          trainer['availability'] as Map? ?? const {},
        ).entries)
          e.key: e.value.toString(),
      },
      employmentActive: trainer['employmentActive'] as bool?,
      canViewBilling: trainer['canViewBilling'] as bool? ?? false,
      seenStudentIds: _strings(map['seenStudentIds']),
    );
  }

  static List<String> _strings(Object? value) =>
      [for (final v in (value as List?) ?? const []) v.toString()];

  static List<WeightEntry> _parseWeightHistory(Object? raw, Object? singleWeight) {
    final list = <WeightEntry>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final dateRaw = item['date'];
          final date = dateRaw is Timestamp
              ? dateRaw.toDate()
              : (dateRaw is String ? DateTime.tryParse(dateRaw) ?? DateTime.now() : DateTime.now());
          final kg = (item['kg'] as num?)?.toDouble() ?? 0.0;
          if (kg > 0) list.add(WeightEntry(date, kg));
        }
      }
    }
    if (list.isEmpty && singleWeight is num && singleWeight > 0) {
      list.add(WeightEntry(DateTime.now(), singleWeight.toDouble()));
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}