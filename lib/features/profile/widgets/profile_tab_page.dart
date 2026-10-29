import 'package:flutter/material.dart';

/// Lista rolável padrão de cada aba do perfil.
class ProfileTabPage extends StatelessWidget {
  final List<Widget> children;

  const ProfileTabPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: children,
    );
  }
}