import 'package:flutter/material.dart';
 
import '../../models/profile_models.dart';
import 'student_profile_page.dart';
import 'trainer_profile_page.dart';
 
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
    switch (role) {
      case UserRole.student:
        return StudentProfilePage(
          student: StudentProfile.sample(name: userName, email: userEmail),
        );
      case UserRole.trainer:
        return TrainerProfilePage(
          trainer: TrainerProfile.sample(name: userName, email: userEmail),
        );
    }
  }
}
 