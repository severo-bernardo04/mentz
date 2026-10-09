import 'package:flutter/material.dart';

import '../models/profile_models.dart';
import 'auth_widgets.dart';
import 'loginpage.dart';
import 'profiles/profile_page.dart';

class Homepage extends StatefulWidget {
  /// Nome do usuário (no Firebase: FirebaseAuth.instance.currentUser?.displayName)
  final String? userName;

  /// E-mail do usuário (no Firebase: FirebaseAuth.instance.currentUser?.email)
  final String? userEmail;

  /// Papel do usuário. TODO: vir do backend (ex: claim/doc do usuário).
  final UserRole role;

  const Homepage({
    super.key,
    this.userName,
    this.userEmail,
    this.role = UserRole.student,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late UserRole _role = widget.role;

  String? get userName => widget.userName;
  String? get userEmail => widget.userEmail;

  void _openProfile() {
    Navigator.of(context).push(
      fadeSlideRoute(
        ProfilePage(role: _role, userName: userName, userEmail: userEmail),
      ),
    );
  }

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
                    const SizedBox(height: 16),
                    // TODO: remover — apenas para testar os dois perfis.
                    SegmentedButton<UserRole>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: UserRole.student,
                          icon: Icon(Icons.person_outline),
                          label: Text('Aluno'),
                        ),
                        ButtonSegment(
                          value: UserRole.trainer,
                          icon: Icon(Icons.sports_gymnastics),
                          label: Text('Treinador'),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (v) =>
                          setState(() => _role = v.first),
                    ),
                    const SizedBox(height: 28),
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
                          delay: Duration(milliseconds: 250),
                          child: _ShortcutCard(
                            icon: Icons.person_outline,
                            label: 'Perfil',
                            onTap: _openProfile,
                          ),
                        ),
                        FadeSlideIn(
                          delay: Duration(milliseconds: 330),
                          child: _ShortcutCard(
                            icon: Icons.explore_outlined,
                            label: 'Explorar',
                          ),
                        ),
                        FadeSlideIn(
                          delay: Duration(milliseconds: 410),
                          child: _ShortcutCard(
                            icon: Icons.notifications_none_rounded,
                            label: 'Avisos',
                          ),
                        ),
                        FadeSlideIn(
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