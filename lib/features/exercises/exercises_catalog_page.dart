import 'package:flutter/material.dart';
import '../../core/routes/fade_slide_route.dart';
import '../../models/profile_models.dart';
import '../../services/exercise_catalog_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_hint.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/fade_slide_in.dart';
import 'controllers/exercise_catalog_controller.dart';
import 'exercise_detail_page.dart';
import 'widgets/exercise_catalog_card.dart';

/// Página principal do Catálogo de Exercícios com demonstração anatômica.
class ExercisesCatalogPage extends StatefulWidget {
  final ExerciseCatalogService? service;
  final bool isSelecting;

  const ExercisesCatalogPage({
    super.key,
    this.service,
    this.isSelecting = false,
  });

  @override
  State<ExercisesCatalogPage> createState() => _ExercisesCatalogPageState();
}

class _ExercisesCatalogPageState extends State<ExercisesCatalogPage> {
  late final ExerciseCatalogController _controller;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _controller = ExerciseCatalogController(service: widget.service);
    _searchCtrl = TextEditingController();
    _controller.load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openExercise(Exercise exercise) async {
    final result = await Navigator.of(context).push<Exercise>(
      fadeSlideRoute(
        ExerciseDetailPage(
          exercise: exercise,
          isSelecting: widget.isSelecting,
        ),
      ),
    );

    if (widget.isSelecting && result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _selectExercise(Exercise exercise) {
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppPageScaffold(
      title: widget.isSelecting ? 'Selecionar Exercício' : 'Catálogo de Exercícios',
      maxWidth: 640,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final error = _controller.errorMessage;
          if (error != null) {
            return Column(
              children: [
                ErrorBanner(error),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            );
          }

          final groups = _controller.availableMuscleGroups;
          final exercises = _controller.filteredExercises;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de pesquisa
              FadeSlideIn(
                child: AppTextField(
                  controller: _searchCtrl,
                  label: 'Buscar exercício por nome (PT ou EN)...',
                  icon: Icons.search,
                  onChanged: _controller.setQuery,
                ),
              ),
              const SizedBox(height: 12),

              // Filtro por grupo muscular
              if (groups.length > 2)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final g in groups)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(g),
                              selected: _controller.selectedMuscle == g,
                              onSelected: (_) => _controller.setMuscleGroup(g),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Contagem
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '${exercises.length} exercícios encontrados',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (widget.isSelecting)
                    Text(
                      'Toque para visualizar ou selecionar',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Lista de exercícios
              if (exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 56,
                        color: cs.onSurfaceVariant.withAlpha(120),
                      ),
                      const SizedBox(height: 12),
                      const EmptyHint(
                        'Nenhum exercício encontrado para os critérios pesquisados.',
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < exercises.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 100 + i * 40),
                    child: ExerciseCatalogCard(
                      exercise: exercises[i],
                      isSelecting: widget.isSelecting,
                      onOpenAnatomy: () => _openExercise(exercises[i]),
                      onSelect: () => _selectExercise(exercises[i]),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
