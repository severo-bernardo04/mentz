import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import 'muscle_anatomy_painter.dart';

/// Card para exibição de cada exercício no catálogo do Mentz.
class ExerciseCatalogCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onOpenAnatomy;
  final VoidCallback? onSelect;
  final bool isSelecting;

  const ExerciseCatalogCard({
    super.key,
    required this.exercise,
    required this.onOpenAnatomy,
    this.onSelect,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpenAnatomy,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (exercise.nameEn != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              exercise.nameEn!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Seção dos papéis musculares
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Músculo Principal (Vermelho)
                    _MuscleTag(
                      role: MuscleRole.primary,
                      label: 'Principal: ${exercise.displayPrimaryMuscle}',
                    ),
                    // Alta ativação (Laranja)
                    for (final m in exercise.highActivationMuscles)
                      _MuscleTag(
                        role: MuscleRole.highActivation,
                        label: 'Alta: $m',
                      ),
                    // Secundários (Amarelo)
                    for (final m in exercise.secondaryMuscles)
                      _MuscleTag(
                        role: MuscleRole.secondary,
                        label: 'Secundário: $m',
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barra de Ação
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: onOpenAnatomy,
                      icon: const Icon(Icons.accessibility_new_rounded, size: 18),
                      label: const Text('Ver Demonstração Anatômica'),
                    ),
                    if (isSelecting)
                      FilledButton.tonalIcon(
                        onPressed: onSelect ?? onOpenAnatomy,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Selecionar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  final MuscleRole role;
  final String label;

  const _MuscleTag({required this.role, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: role.color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: role.color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: role.color,
        ),
      ),
    );
  }
}
