import 'package:flutter/material.dart';
import '../../core/utils/text_fit.dart';
import '../../services/training_history_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/status_chip.dart';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Título maior (22px) para destacar a tela
        title: Text(
          'Planilha de Execuções',
          style: theme.textTheme.titleLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          // Layout estilo Excel: planilha ocupa o espaço disponível e as abas ficam no rodapé
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: ListenableBuilder(
                    listenable: _service,
                    builder: (context, _) {
                      return TabBarView(
                        controller: _tabController,
                        // Como no Excel, a aba só muda tocando nas abas do rodapé:
                        // o arrasto lateral fica só para rolar a tabela, sem trocar de treino
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final plan in _plans)
                            _buildPlanSpreadsheet(plan),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _buildPlanTabs(cs),
            ],
          ),
        ),
      ),
    );
  }

  /// Até este número de abas, elas dividem a largura; acima, a barra rola.
  static const _maxFixedTabs = 4;

  /// Largura do texto de cada aba quando a barra rola.
  static const _scrollableLabelWidth = 110.0;

  /// Espaço lateral de cada aba, entre o texto e a borda da pílula.
  static const _tabHorizontalPadding = 8.0;

  /// Abas dos dias do ciclo no rodapé da tela, como as abas de planilha do Excel.
  /// Cada aba mostra só o nome dado ao treino (ex: "FULL BODY 1").
  ///
  /// Para caber nomes longos, todas as abas usam o mesmo tamanho de fonte: o
  /// maior (até 16) em que todos os nomes cabem em até 2 linhas sem quebrar
  /// palavras, nunca menor que 11 ([fitFontSize]). Assim o conjunto fica
  /// homogêneo, sem uma aba com letra diferente das outras.
  Widget _buildPlanTabs(ColorScheme cs) {
    final scrollable = _plans.length > _maxFixedTabs;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Largura útil: tela - margens (32) - padding (8) - borda (2)
        final barWidth = constraints.maxWidth - 32 - 8 - 2;
        final labelWidth = scrollable
            ? _scrollableLabelWidth
            : barWidth / _plans.length - _tabHorizontalPadding * 2;
        final fontSize = fitFontSize(
          _plans,
          maxWidth: labelWidth,
          // Mede com o peso da aba selecionada, o mais largo
          style: const TextStyle(fontWeight: FontWeight.w800, height: 1.15),
          textScaler: MediaQuery.textScalerOf(context),
        );

        return Container(
          height: 56,
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(220),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withAlpha(90)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: scrollable,
            tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: _tabHorizontalPadding,
            ),
            // Indicador ocupa a aba inteira, como um botão selecionado
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            dividerColor: Colors.transparent,
            labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              for (final plan in _plans)
                Tab(
                  height: 48,
                  child: SizedBox(
                    width: scrollable ? _scrollableLabelWidth : null,
                    child: Text(
                      plan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: fontSize, height: 1.15),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanSpreadsheet(String plan) {
    final sessions = _service.getSessionsForWorkout(plan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra compacta só aparece quando há dados na tabela
        if (sessions.isNotEmpty) ...[
          _buildInfoBar(sessions.length),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: SpreadsheetDataTable(
            sessions: sessions,
            dayName: plan,
          ),
        ),
      ],
    );
  }

  /// Barra compacta acima da tabela: dica de rolagem horizontal à esquerda
  /// e a quantidade de execuções em um StatusChip (widget compartilhado do projeto).
  Widget _buildInfoBar(int sessionCount) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.swipe_outlined, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        // Expanded evita overflow do texto em telas estreitas
        Expanded(
          child: Text(
            'Arraste para ver mais datas',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
        ),
        StatusChip(
          icon: Icons.event_available_outlined,
          label: sessionCount == 1 ? '1 execução' : '$sessionCount execuções',
        ),
      ],
    );
  }
}
