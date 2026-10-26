import 'package:flutter/material.dart';
import 'package:mentz/widgets/app_card.dart';

/// Cabeçalho do perfil: avatar, nome, subtítulo e chips.
class ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? photoUrl;
  final List<Widget> chips;
  final VoidCallback? onEditPhoto;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    this.chips = const [],
    this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(
                name: name,
                photoUrl: photoUrl,
                onEdit: onEditPhoto,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback? onEdit;

  const _ProfileAvatar({required this.name, this.photoUrl, this.onEdit});

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: cs.primary,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                )
              : null,
        ),
        if (onEdit != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Material(
              color: cs.secondaryContainer,
              shape: CircleBorder(side: BorderSide(color: cs.surface, width: 2)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 16,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}