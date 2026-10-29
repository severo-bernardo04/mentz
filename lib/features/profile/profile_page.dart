import 'package:flutter/material.dart';
import 'package:mentz/features/profile/student/student_profile_page.dart';
import 'package:mentz/features/profile/trainer/trainer_profile_page.dart';
import 'package:mentz/models/profile_models.dart';

/// Escolhe o perfil certo de acordo com o papel do usuário logado.
///
/// Por enquanto usa dados de exemplo. Quando houver backend, troque
/// `StudentProfile.sample` / `TrainerProfile.sample` pelos dados reais.
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
    return switch (role) {
      UserRole.student => StudentProfilePage(
          student: StudentProfile.sample(name: userName, email: userEmail),
        ),
      UserRole.trainer => TrainerProfilePage(
          trainer: TrainerProfile.sample(name: userName, email: userEmail),
        ),
    };
  }
}