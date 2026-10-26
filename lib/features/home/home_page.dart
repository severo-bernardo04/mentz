import 'package:flutter/material.dart';

import '../../core/routes/fade_slide_route.dart';
import '../../models/profile_models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/fade_slide_in.dart';
import '../auth/login_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../training/create_training_chart_page.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/role_switcher.dart';
import 'widgets/section_header.dart';
import 'widgets/shortcuts_grid.dart';
import 'widgets/training_chart_list.dart';
import 'widgets/welcome_card.dart';

class HomePage extends StatefulWidget {
  /// Nome do usuário (no Firebase: FirebaseAuth.instance.currentUser?.displayName)
  final String? userName;

  /// E-mail do usuário (no Firebase: FirebaseAuth.instance.currentUser?.email)
  final String? userEmail;

  /// Papel do usuário. TODO: vir do backend (ex: claim/doc do usuário).
  final UserRole role;

  const HomePage({
    super.key,
    this.userName,
    this.userEmail,
    this.role = UserRole.student,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserRole _role = widget.role;

  void _openNewChart() => context.pushFade(const CreateTrainingChartPage());

  void _openSettings() => context.pushFade(const SettingsPage());

  void _openProfile() => context.pushFade(
        ProfilePage(
          role: _role,
          userName: widget.userName,
          userEmail: widget.userEmail,
        ),
      );

  Future<void> _logout() async {
    // TODO: await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    context.pushFadeAndClear(const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HomeAppBar(onSettings: _openSettings, onLogout: _logout),
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  kToolbarHeight + 8,
                  24,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(
                      child: WelcomeCard(
                        userName: widget.userName,
                        userEmail: widget.userEmail,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // TODO: remover — apenas para testar os dois perfis.
                    RoleSwitcher(
                      selected: _role,
                      onChanged: (role) => setState(() => _role = role),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: SectionHeader(
                        title: 'Planilhas de Treino',
                        trailing: FilledButton.tonalIcon(
                          key: const Key('home_new_chart_button'),
                          onPressed: _openNewChart,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nova Planilha'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TrainingChartList(),
                    const SizedBox(height: 24),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 150),
                      child: SectionHeader(title: 'Atalhos'),
                    ),
                    const SizedBox(height: 12),
                    ShortcutsGrid(
                      onNewChart: _openNewChart,
                      onProfile: _openProfile,
                      onSettings: _openSettings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}