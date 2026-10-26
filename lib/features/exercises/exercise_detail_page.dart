import 'package:flutter/material.dart';
import '../../models/profile_models.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';
import 'widgets/muscle_anatomy_view.dart';

/// Tela de demonstração anatômica e detalhes completos de um exercício.
class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;
  final bool isSelecting;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppPageScaffold(
      title: 'Demonstração Anatômica',
      maxWidth: 620,
      actions: [
        if (isSelecting)
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(exercise),
            icon: const Icon(Icons.check),
            label: const Text('Selecionar'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identificação do Exercício
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: cs.onPrimaryContainer,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (exercise.nameEn != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                exercise.nameEn!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusChip(
                        label: 'Grupo: ${exercise.displayPrimaryMuscle}',
                        icon: Icons.accessibility_new,
                      ),
                      if (exercise.equipment != null)
                        StatusChip(
                          label: exercise.equipment!,
                          icon: Icons.hardware_outlined,
                        ),
                      StatusChip(
                        label: '${exercise.sets} séries × ${exercise.reps}',
                        icon: Icons.repeat,
                        color: cs.primary,
                      ),
                      StatusChip(
                        label: exercise.restLabel,
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Demonstração Anatômica Vetorial
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: SectionCard(
              title: 'Modelo Anatômico de Ativação',
              icon: Icons.accessibility_rounded,
              child: MuscleAnatomyView(exercise: exercise),
            ),
          ),
          const SizedBox(height: 14),

          // Instruções de Execução (se cadastradas)
          if (exercise.instructions != null &&
              exercise.instructions!.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: SectionCard(
                title: 'Instruções de Execução',
                icon: Icons.info_outline_rounded,
                child: Text(
                  exercise.instructions!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (isSelecting) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 250),
              child: AppButton(
                label: 'Incluir este Exercício na Ficha',
                icon: Icons.add_task_rounded,
                onPressed: () => Navigator.of(context).pop(exercise),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
