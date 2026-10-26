import 'package:flutter/material.dart';

import '../../../widgets/app_card.dart';

/// Cartão de boas-vindas com avatar, nome e e-mail.
class WelcomeCard extends StatelessWidget {
  final String? userName;
  final String? userEmail;

  const WelcomeCard({super.key, this.userName, this.userEmail});

  String get _displayName {
    final name = userName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final emailName = (userEmail ?? '').split('@').first.trim();
    if (emailName.isNotEmpty) return emailName;

    return 'visitante';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = _displayName;

    return AppCard(
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (userEmail != null && userEmail!.isNotEmpty)
                  Text(
                    userEmail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}