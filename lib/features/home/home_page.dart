import 'package:flutter/material.dart';

import '../../core/routes/fade_slide_route.dart';
import '../../models/profile_models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/fade_slide_in.dart';
import '../auth/login_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../exercises/exercises_catalog_page.dart';
import '../training/create_training_chart_page.dart';
import '../training_history/training_history_page.dart';
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

  void _openHistory() => context.pushFade(const TrainingHistoryPage());

  void _openExercises() => context.pushFade(const ExercisesCatalogPage());

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
      appBar: HomeAppBar(
        onSettings: _openSettings,
        onLogout: _logout,
        onExercises: _openExercises,
      ),
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
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withAlpha(235),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            key: const Key('home_exercises_banner_card'),
                            borderRadius: BorderRadius.circular(22),
                            onTap: _openExercises,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                    ),
                                    child: Icon(
                                      Icons.accessibility_new_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Catálogo & Anatomia',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Consulte exercícios e sua ativação muscular',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 150),
                      child: SectionHeader(title: 'Atalhos'),
                    ),
                    const SizedBox(height: 12),
                    ShortcutsGrid(
                      onNewChart: _openNewChart,
                      onProfile: _openProfile,
                      onHistory: _openHistory,
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