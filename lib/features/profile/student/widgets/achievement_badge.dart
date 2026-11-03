import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Medalha de conquista (bloqueada fica translúcida com cadeado).
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = achievement;

    return Tooltip(
      message: a.description,
      child: Opacity(
        opacity: a.unlocked ? 1 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: a.unlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.tertiary],
                      )
                    : null,
                color: a.unlocked ? null : cs.surfaceContainerHighest,
              ),
              child: Icon(
                a.unlocked ? a.icon : Icons.lock_outline,
                color: a.unlocked ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}