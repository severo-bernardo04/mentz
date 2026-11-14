import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/text_fit.dart';
import '../../models/profile_models.dart';
import '../../models/training_chart.dart';
import '../../services/training_chart_service.dart';
import '../../services/training_history_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/status_chip.dart';
import 'widgets/spreadsheet_data_table.dart';

/// Visualização em formato de planilha (estilo Excel) contendo o histórico de execuções anteriores,
/// permitindo alternar entre os dias do ciclo por meio de abas.
class WorkoutSpreadsheetPage extends StatefulWidget {
  final String? initialPlan;
  final TrainingHistoryService? service;
  final TrainingChartService? chartService;
  final TrainingChart? chart;

  const WorkoutSpreadsheetPage({
    super.key,
    this.initialPlan,
    this.service,
    this.chartService,
    this.chart,
  });

  @override
  State<WorkoutSpreadsheetPage> createState() => _WorkoutSpreadsheetPageState();
}

class _SpreadsheetTab {
  final String label;
  final String? chartId;
  final String? dayId;
  final String? chartName;

  const _SpreadsheetTab({
    required this.label,
    this.chartId,
    this.dayId,
    this.chartName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SpreadsheetTab &&
          label == other.label &&
          chartId == other.chartId &&
          dayId == other.dayId &&
          chartName == other.chartName;

  @override
  int get hashCode => Object.hash(label, chartId, dayId, chartName);
}

class _WorkoutSpreadsheetPageState extends State<WorkoutSpreadsheetPage>
    with TickerProviderStateMixin {
  late final TrainingHistoryService _service =
      widget.service ?? TrainingHistoryService();
  late final TrainingChartService _chartService =
      widget.chartService ?? TrainingChartService();
  late List<_SpreadsheetTab> _tabs;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.chart == null) {
      _chartService.addListener(_onChartChanged);
    }
    _tabs = _buildTabs();
    _tabController = _createTabController(initialIndex: _findInitialIndex(_tabs));
  }

  List<_SpreadsheetTab> _buildTabs() {
    final chart = widget.chart ?? _chartService.currentChart;
    if (chart != null && chart.days.isNotEmpty) {
      final days = List<TrainingDay>.from(chart.days)
        ..sort((a, b) => a.order.compareTo(b.order));
      return [
        for (final day in days)
          _SpreadsheetTab(
            label: day.name,
            chartId: chart.id,
            dayId: day.id,
            chartName: chart.name,
          ),
      ];
    }

    final available = _service.getAvailablePlans();
    final plans = available.isEmpty ? ['A', 'B', 'C'] : available;
    return [for (final plan in plans) _SpreadsheetTab(label: plan)];
  }

  int _findInitialIndex(List<_SpreadsheetTab> tabs) {
    if (widget.initialPlan != null) {
      final idx = tabs.indexWhere(
        (t) => t.label.toLowerCase() == widget.initialPlan!.toLowerCase(),
      );
      if (idx >= 0) return idx;
    }
    return 0;
  }

  TabController _createTabController({required int initialIndex}) {
    return TabController(
      length: _tabs.length,
      initialIndex: initialIndex.clamp(0, _tabs.length - 1),
      vsync: this,
    );
  }

  void _onChartChanged() {
    final nextTabs = _buildTabs();
    if (listEquals(nextTabs, _tabs)) return;

    final previousLabel = _tabController != null && _tabController!.index < _tabs.length
        ? _tabs[_tabController!.index].label
        : widget.initialPlan;
    final oldController = _tabController;

    setState(() {
      _tabs = nextTabs;
      final restoredIdx = previousLabel == null
          ? 0
          : _tabs.indexWhere(
              (t) => t.label.toLowerCase() == previousLabel.toLowerCase(),
            );
      _tabController = _createTabController(
        initialIndex: restoredIdx >= 0 ? restoredIdx : 0,
      );
    });
    oldController?.dispose();
  }

  @override
  void dispose() {
    if (widget.chart == null) {
      _chartService.removeListener(_onChartChanged);
    }
    _tabController?.dispose();
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
                          for (final tab in _tabs)
                            _buildPlanSpreadsheet(tab),
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
    final scrollable = _tabs.length > _maxFixedTabs;
    final labels = [for (final tab in _tabs) tab.label];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Largura útil: tela - margens (32) - padding (8) - borda (2)
        final barWidth = constraints.maxWidth - 32 - 8 - 2;
        final labelWidth = scrollable
            ? _scrollableLabelWidth
            : barWidth / _tabs.length - _tabHorizontalPadding * 2;
        final fontSize = fitFontSize(
          labels,
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
              for (final tab in _tabs)
                Tab(
                  height: 48,
                  child: SizedBox(
                    width: scrollable ? _scrollableLabelWidth : null,
                    child: Text(
                      tab.label,
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

  Widget _buildPlanSpreadsheet(_SpreadsheetTab tab) {
    final sessions = _service.getSessionsForWorkout(
      tab.label,
      chartId: tab.chartId,
      dayId: tab.dayId,
      chartName: tab.chartName,
    );
    return _PlanSpreadsheetView(
      sessions: sessions,
      dayName: tab.label,
    );
  }
}

class _PlanSpreadsheetView extends StatefulWidget {
  final List<CompletedWorkout> sessions;
  final String dayName;

  const _PlanSpreadsheetView({
    required this.sessions,
    required this.dayName,
  });

  @override
  State<_PlanSpreadsheetView> createState() => _PlanSpreadsheetViewState();
}

class _PlanSpreadsheetViewState extends State<_PlanSpreadsheetView> {
  bool _showDragHint = false;

  @override
  void didUpdateWidget(covariant _PlanSpreadsheetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessions.isEmpty && _showDragHint) {
      _showDragHint = false;
    }
  }

  bool _onScrollMetrics(ScrollMetricsNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    final canScroll = notification.metrics.maxScrollExtent > 0.5;
    if (canScroll != _showDragHint) {
      setState(() => _showDragHint = canScroll);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra compacta só aparece quando há dados na tabela
        if (widget.sessions.isNotEmpty) ...[
          _buildInfoBar(widget.sessions.length),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _onScrollMetrics,
            child: SpreadsheetDataTable(
              sessions: widget.sessions,
              dayName: widget.dayName,
            ),
          ),
        ),
      ],
    );
  }

  /// Barra compacta acima da tabela: dica de rolagem horizontal à esquerda
  /// (somente quando a tabela ultrapassa a largura da tela) e a quantidade de
  /// execuções em um StatusChip (widget compartilhado do projeto).
  Widget _buildInfoBar(int sessionCount) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (_showDragHint) ...[
          Icon(Icons.swipe_outlined, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          // Expanded evita overflow do texto em telas estreitas
          Expanded(
            child: Text(
              'Arraste para ver mais datas',
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
          ),
        ] else
          const Spacer(),
        StatusChip(
          icon: Icons.event_available_outlined,
          label: sessionCount == 1 ? '1 execução' : '$sessionCount execuções',
        ),
      ],
    );
  }
}
