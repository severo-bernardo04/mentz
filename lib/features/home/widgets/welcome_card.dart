import 'package:flutter/material.dart';

import '../../../widgets/app_card.dart';
import 'dart:convert';

/// Cartão de boas-vindas com avatar, nome e e-mail.
/// Ao clicar, navega para o perfil do usuário.
class WelcomeCard extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? photoBase64;
  final VoidCallback? onTap;

  const WelcomeCard({
    super.key,
    this.userName,
    this.userEmail,
    this.photoBase64,
    this.onTap,
  });

  String get _displayName {
    final name = userName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final emailName = (userEmail ?? '').split('@').first.trim();
    if (emailName.isNotEmpty) return emailName;

    return 'visitante';
  }

  ImageProvider? get _photo {
    final p = photoBase64;
    if (p == null || p.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(p));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = _displayName;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: cs.primary,
            backgroundImage: _photo,
            child: _photo != null ? null
            :Text(
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
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
