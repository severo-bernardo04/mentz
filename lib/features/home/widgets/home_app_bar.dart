import 'package:flutter/material.dart';

/// AppBar transparente da home: marca + ajustes + sair.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const HomeAppBar({
    super.key,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Mentz',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          key: const Key('home_settings_appbar_button'),
          tooltip: 'Ajustes',
          icon: const Icon(Icons.settings_outlined),
          onPressed: onSettings,
        ),
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout_rounded),
          onPressed: onLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}