import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/info_row.dart';
import 'package:mentz/widgets/simple_bar_chart.dart';
import 'package:mentz/widgets/stat_tile.dart';

/// Progresso na home: alterna entre dados (texto) e gráfico (barras).
class HomeProgressCard extends StatefulWidget {
  const HomeProgressCard({super.key});

  @override
  State<HomeProgressCard> createState() => _HomeProgressCardState();
}

class _HomeProgressCardState extends State<HomeProgressCard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: TrainingHistoryService(),
      builder: (context, _) {
        final stats = _ProgressStats(TrainingHistoryService().sessions);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(235),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SegmentedButton<int>(
                key: const Key('home_progress_selector'),
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.list_alt_rounded),
                    label: Text('Dados'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.bar_chart_rounded),
                    label: Text('Gráfico'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: stats.total == 0
                      ? const EmptyHint('Nenhum treino realizado ainda.')
                      : (_tab == 0 ? _data(stats) : _chart(stats)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _data(_ProgressStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.fitness_center,
                value: '${stats.total}',
                label: 'Treinos realizados',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_month_outlined,
                value: '${stats.thisMonth}',
                label: 'Treinos no mês',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.timer_outlined,
                value: _ProgressStats.duration(stats.totalMinutes),
                label: 'Tempo total',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.av_timer_rounded,
                value: _ProgressStats.duration(stats.averageMinutes),
                label: 'Duração média',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InfoRow(
          icon: Icons.event_available_outlined,
          label: 'Último treino',
          value: formatDate(stats.lastDate!),
        ),
        InfoRow(
          icon: Icons.warning_amber_rounded,
          label: 'Treinos incompletos',
          value: '${stats.incomplete}',
        ),
      ],
    );
  }

  Widget _chart(_ProgressStats stats) {
    final theme = Theme.of(context);
    final months = stats.months;
    final labels = [
      for (final m in months) _ProgressStats.monthNames[m.month - 1],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Treinos por mês',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SimpleBarChart(
          values: [for (final m in months) stats.countIn(m)],
          labels: labels,
        ),
        const SizedBox(height: 16),
        Text(
          'Minutos treinados por mês',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SimpleBarChart(
          values: [for (final m in months) stats.minutesIn(m)],
          labels: labels,
        ),
      ],
    );
  }
}

/// Números calculados do histórico, usados pelas duas visões.
class _ProgressStats {
  static const chartMonths = 6;
  static const monthNames = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  final List<CompletedWorkout> sessions;

  _ProgressStats(this.sessions);

  /// Últimos meses, do mais antigo ao atual.
  List<DateTime> get months {
    final now = DateTime.now();
    return [
      for (var i = chartMonths - 1; i >= 0; i--)
        DateTime(now.year, now.month - i),
    ];
  }

  List<CompletedWorkout> _in(DateTime m) => sessions
      .where((s) => s.date.year == m.year && s.date.month == m.month)
      .toList();

  int countIn(DateTime m) => _in(m).length;

  int minutesIn(DateTime m) => _in(m).fold(0, (sum, s) => sum + s.minutes);

  int get total => sessions.length;
  int get thisMonth => countIn(months.last);
  int get totalMinutes => sessions.fold(0, (sum, s) => sum + s.minutes);
  int get averageMinutes => total == 0 ? 0 : (totalMinutes / total).round();
  int get incomplete => sessions.where((s) => s.isIncomplete).length;

  DateTime? get lastDate => sessions.isEmpty
      ? null
      : sessions.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b);

  static String duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}min' : '$minutes min';
}