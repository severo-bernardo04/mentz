import 'package:flutter/material.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/profile/student/student_profile_page.dart';
import 'package:mentz/features/profile/trainer/trainer_profile_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentz/models/app_user.dart';
import 'package:mentz/services/trainer_service.dart';
import 'package:mentz/services/user_profile_service.dart';

/// Escolhe o perfil certo de acordo com o papel do usuário logado,
/// exibindo os dados reais de `users/{uid}`.
class ProfilePage extends StatelessWidget {
  final UserRole role;
  final String? userName;
  final String? userEmail;

  const ProfilePage({
    super.key,
    required this.role,
    this.userName,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if(uid == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: UserProfileService().watch(uid),
      builder: (context, snap){
        final u = snap.data;
        final name = u?.name ?? userName ?? '';
        final email = u?.email ?? userEmail ?? '';
        final phone = u?.phone;
        final photo = u?.photoBase64;

        return switch (role) {
          UserRole.student => StudentProfilePage(
            student: StudentProfile(
              name: name,
              email: email,
              phone: phone,
              photoUrl: photo,
            ),
          ),
          UserRole.trainer => _TrainerProfileLoader(
            uid: uid,
            user: u,
            name: name,
            email: email,
          ),
        };
      },
    );
  }
}

/// Carrega alunos, fichas e agenda do treinador enquanto o perfil estiver
/// aberto e entrega o [TrainerProfile] completo à página.
class _TrainerProfileLoader extends StatefulWidget {
  final String uid;
  final AppUser? user;
  final String name;
  final String email;

  const _TrainerProfileLoader({
    required this.uid,
    required this.user,
    required this.name,
    required this.email,
  });

  @override
  State<_TrainerProfileLoader> createState() => _TrainerProfileLoaderState();
}

class _TrainerProfileLoaderState extends State<_TrainerProfileLoader> {
  final _service = TrainerService();
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _service.watchUser(widget.uid);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.stopWatching(widget.uid);
    super.dispose();
  }

  /// Avisa uma única vez se alguma leitura falhar.
  void _onServiceChanged() {
    final error = _service.errorMessage;
    if (error == null || _errorShown || !mounted) return;

    _errorShown = true;
    context.showSnack(error);
  }

  TrainerProfile _buildTrainer() {
    final u = widget.user;
    final students = _service.students;
    final seen = {...?u?.seenStudentIds};

    return TrainerProfile(
      name: widget.name,
      email: widget.email,
      phone: u?.phone,
      photoUrl: u?.photoBase64,
      role: u?.trainerRole,
      cref: u?.cref,
      specialties: u?.specialties ?? const [],
      qualifications: u?.qualifications ?? const [],
      experienceYears: u?.experienceYears,
      availability: u?.availability ?? const {},
      employmentActive: u?.employmentActive,
      canViewBilling: u?.canViewBilling ?? false,
      students: students,
      plans: _service.plans,
      appointments: _service.appointments,
      newStudents: [
        for (final s in students)
          if (!seen.contains(s.id)) s.name,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        if (_service.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meu perfil')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return TrainerProfilePage(trainer: _buildTrainer());
      },
    );
  }
}