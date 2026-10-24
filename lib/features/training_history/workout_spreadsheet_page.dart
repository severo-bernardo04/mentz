import 'package:flutter/material.dart';
import '../../services/training_history_service.dart';
import '../../widgets/app_background.dart';
import 'widgets/spreadsheet_data_table.dart';

/// Visualização em formato de planilha (estilo Excel) contendo o histórico de execuções anteriores,
/// permitindo alternar entre os dias do ciclo por meio de abas.
class WorkoutSpreadsheetPage extends StatefulWidget {
  final String? initialPlan;
  final TrainingHistoryService? service;

  const WorkoutSpreadsheetPage({
    super.key,
    this.initialPlan,
    this.service,
  });

  @override
  State<WorkoutSpreadsheetPage> createState() => _WorkoutSpreadsheetPageState();
}

class _WorkoutSpreadsheetPageState extends State<WorkoutSpreadsheetPage>
    with SingleTickerProviderStateMixin {
  late final TrainingHistoryService _service =
      widget.service ?? TrainingHistoryService();
  late List<String> _plans;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initPlans();
  }

  void _initPlans() {
    final available = _service.getAvailablePlans();
    _plans = available.isEmpty ? ['A', 'B', 'C'] : available;

    int initialIndex = 0;
    if (widget.initialPlan != null) {
      final idx = _plans.indexWhere(
        (p) => p.toLowerCase() == widget.initialPlan!.toLowerCase(),
      );
      if (idx >= 0) initialIndex = idx;
    }

    _tabController = TabController(
      length: _plans.length,
      initialIndex: initialIndex,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Planilha de Execuções',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: _plans.length > 4,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              tabs: [
                for (final plan in _plans)
                  Tab(
                    text: 'Treino $plan',
                  ),
              ],
            ),
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (final plan in _plans)
                      _buildPlanSpreadsheet(plan),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSpreadsheet(String plan) {
    final sessions = _service.getSessionsForWorkout(plan);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_toggle_off, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Histórico de progressão — Treino $plan',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${sessions.length} execuções registradas',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SpreadsheetDataTable(
              sessions: sessions,
              dayName: 'Treino $plan',
            ),
          ),
        ],
      ),
    );
  }
}
