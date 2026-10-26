import 'package:flutter/material.dart';
import 'package:mentz/features/settings/widgets/icon_badge.dart';

/// Linha de ajuste: ícone colorido, título, descrição e controle à direita.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final BadgeTone tone;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.tone = BadgeTone.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: IconBadge(icon: icon, tone: tone),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
    );
  }
}