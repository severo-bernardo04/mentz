import 'package:flutter/material.dart';
import '../../core/routes/fade_slide_route.dart';
import '../../models/profile_models.dart';
import '../../services/training_history_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/empty_hint.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/stat_tile.dart';
import 'controllers/training_history_controller.dart';
import 'widgets/workout_session_card.dart';
import 'workout_session_detail_page.dart';
import 'workout_spreadsheet_page.dart';

/// Tela principal do Histórico de Treinos do aplicativo Mentz.
class TrainingHistoryPage extends StatefulWidget {
  final TrainingHistoryService? service;

  const TrainingHistoryPage({super.key, this.service});

  @override
  State<TrainingHistoryPage> createState() => _TrainingHistoryPageState();
}

class _TrainingHistoryPageState extends State<TrainingHistoryPage> {
  late final TrainingHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TrainingHistoryController(service: widget.service);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetail(CompletedWorkout session) {
    context.pushFade(WorkoutSessionDetailPage(session: session));
  }

  void _openSpreadsheet() {
    context.pushFade(const WorkoutSpreadsheetPage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppPageScaffold(
      title: 'Histórico de Treinos',
      maxWidth: 600,
      actions: [
        IconButton(
          tooltip: 'Ver Planilha Completa',
          icon: const Icon(Icons.table_chart_outlined),
          onPressed: _openSpreadsheet,
        ),
      ],
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

          final allSessions = _controller.sessions;
          final filtered = _controller.filteredSessions;

          if (allSessions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant.withAlpha(120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum treino realizado ainda',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const EmptyHint(
                    'Conclua seus treinos para que o histórico e a progressão de cargas apareçam aqui.',
                  ),
                ],
              ),
            );
          }

          final totalMinutes = allSessions.fold<int>(
            0,
            (sum, s) => sum + s.minutes,
          );
          final plans = _controller.availablePlans;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha de estatísticas gerais
              FadeSlideIn(
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.fitness_center_outlined,
                        value: '${allSessions.length}',
                        label: 'Sessões',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.timer_outlined,
                        value: '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                        label: 'Tempo total',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.table_chart_outlined,
                        value: '${plans.length - 1}',
                        label: 'Divisões',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Barra de filtros por plano/dia
              if (plans.length > 2)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final p in plans)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(p == 'Todos' ? 'Todos os treinos' : 'Treino $p'),
                              selected: (_controller.selectedPlanFilter == null && p == 'Todos') ||
                                  _controller.selectedPlanFilter == p,
                              onSelected: (_) => _controller.setFilter(p),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Lista das sessões filtradas
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: EmptyHint('Nenhum treino encontrado para este filtro.'),
                )
              else
                for (var i = 0; i < filtered.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 120 + i * 50),
                    child: WorkoutSessionCard(
                      session: filtered[i],
                      onTap: () => _openDetail(filtered[i]),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
