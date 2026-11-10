import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/student_profile_page.dart';
import 'package:mentz/features/profile/trainer/trainer_profile_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentz/models/app_user.dart';
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
          UserRole.trainer => TrainerProfilePage(
            trainer: TrainerProfile(
              name: name,
              email: email,
              phone: phone,
              photoUrl: photo,
            ),
          ),
        };
      },
    );
  }
}