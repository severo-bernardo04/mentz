import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentz/features/auth/login_page.dart';
import 'package:mentz/features/home/home_page.dart';
import 'package:mentz/models/app_user.dart';
import 'package:mentz/services/auth_service.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/services/user_profile_service.dart';

/// Mostra o login ou a home conforme a sessão do Firebase.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authChanges = AuthService().authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();

        return _SignedInGate(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

/// Com usuário logado: espera o perfil do Firestore e abre a home.
class _SignedInGate extends StatefulWidget {
  final String uid;

  const _SignedInGate({super.key, required this.uid});

  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  late final Stream<AppUser?> _profile = UserProfileService().watch(widget.uid);

  @override
  void initState() {
    super.initState();
    // Carrega catálogo, planilhas e histórico enquanto este usuário estiver logado
    ExerciseCatalogService().watchUser(widget.uid);
    TrainingChartService().watchUser(widget.uid);
    TrainingHistoryService().watchUser(widget.uid);
  }

  @override
  void dispose() {
    ExerciseCatalogService().stopWatching(widget.uid);
    TrainingChartService().stopWatching(widget.uid);
    TrainingHistoryService().stopWatching(widget.uid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _ProfileError();

        final profile = snapshot.data;
        if (profile == null) return const _Splash();

        return HomePage(
          userName: profile.name,
          userEmail: profile.email,
          role: profile.role,
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível carregar seu perfil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => AuthService().signOut(),
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}