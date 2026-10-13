import 'package:flutter/material.dart';

import 'auth_widgets.dart';
import 'loginpage.dart';
import 'create_training_chart_page.dart';
import '../models/training_chart.dart';
import '../services/training_chart_service.dart';

class Homepage extends StatelessWidget {
  /// Nome do usuário (no Firebase: FirebaseAuth.instance.currentUser?.displayName)
  final String? userName;

  /// E-mail do usuário (no Firebase: FirebaseAuth.instance.currentUser?.email)
  final String? userEmail;

  const Homepage({super.key, this.userName, this.userEmail});

  String get _displayName {
    final name = userName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final emailName = (userEmail ?? '').split('@').first.trim();
    if (emailName.isNotEmpty) return emailName;

    return 'visitante';
  }

  Future<void> _logout(BuildContext context) async {
    // TODO: await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      fadeSlideRoute(const Loginpage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = _displayName;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Mentz',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AuthBackground(
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
                      child: AuthCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: cs.primary,
                              child: Text(
                                name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olá, $name!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (userEmail != null &&
                                      userEmail!.isNotEmpty)
                                    Text(
                                      userEmail!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Planilhas de Treino',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            key: const Key('home_new_chart_button'),
                            onPressed: () {
                              Navigator.of(context).push(
                                fadeSlideRoute(const CreateTrainingChartPage()),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nova Planilha'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: TrainingChartService(),
                      builder: (context, _) {
                        final charts = TrainingChartService().charts;
                        if (charts.isEmpty) {
                          return FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: AuthCard(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.fitness_center_outlined,
                                        size: 40,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nenhuma planilha cadastrada ainda.',
                                        style: TextStyle(color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (int i = 0; i < charts.length; i++)
                              FadeSlideIn(
                                delay: Duration(milliseconds: 200 + (i * 60)),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: AuthCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: cs.primaryContainer,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.table_chart_rounded,
                                                color: cs.onPrimaryContainer,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    charts[i].name,
                                                    style: theme.textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  if (charts[i].description != null)
                                                    Text(
                                                      charts[i].description!,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: cs.onSurfaceVariant,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                charts[i].frequencyConfig.type == WorkoutFrequencyType.fixedDays
                                                    ? 'Dias Fixos'
                                                    : 'Intervalo',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                              backgroundColor: cs.surfaceContainerHighest,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            for (final day in charts[i].days)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: cs.primary.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: cs.primary.withAlpha(50)),
                                                ),
                                                child: Text(
                                                  day.name,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.primary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: Text(
                        'Atalhos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: _ShortcutCard(
                            icon: Icons.add_task_rounded,
                            label: 'Nova Planilha',
                            onTap: () {
                              Navigator.of(context).push(
                                fadeSlideRoute(const CreateTrainingChartPage()),
                              );
                            },
                          ),
                        ),
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 330),
                          child: _ShortcutCard(
                            icon: Icons.person_outline,
                            label: 'Perfil',
                          ),
                        ),
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 410),
                          child: _ShortcutCard(
                            icon: Icons.explore_outlined,
                            label: 'Explorar',
                          ),
                        ),
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 490),
                          child: _ShortcutCard(
                            icon: Icons.settings_outlined,
                            label: 'Ajustes',
                          ),
                        ),
                      ],
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

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface.withAlpha(235),
      elevation: 3,
      shadowColor: Colors.black.withAlpha(60),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}