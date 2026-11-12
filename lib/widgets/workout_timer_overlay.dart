import 'dart:async';

import 'package:flutter/material.dart';

import '../core/routes/app_navigation.dart';
import '../core/utils/duration_format.dart';
import '../features/workout_session/workout_session_page.dart';
import '../models/active_workout.dart';
import '../models/training_chart.dart';
import '../services/training_chart_service.dart';
import '../services/workout_session_service.dart';

/// Cronômetro flutuante do treino em andamento, visível sobre qualquer tela.
///
/// Fica no `builder` do MaterialApp, acima do Navigator. Só aparece com um
/// treino em andamento e se esconde quando a tela desse treino já está
/// visível. Tocar volta para o treino; arrastar muda a posição.
class WorkoutTimerOverlay extends StatefulWidget {
  final Widget child;

  const WorkoutTimerOverlay({super.key, required this.child});

  @override
  State<WorkoutTimerOverlay> createState() => _WorkoutTimerOverlayState();
}

class _WorkoutTimerOverlayState extends State<WorkoutTimerOverlay> {
  final _service = WorkoutSessionService();

  /// Redesenha a cada segundo enquanto houver treino em andamento.
  Timer? _ticker;

  /// Distância do cronômetro até a borda direita e a inferior da tela.
  Offset _margin = const Offset(16, 96);

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    visibleWorkoutRoute.addListener(_onChanged);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _service.removeListener(_onChanged);
    visibleWorkoutRoute.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    _syncTicker();
    if (mounted) setState(() {});
  }

  void _syncTicker() {
    if (_service.active != null) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// Volta para a tela do treino em andamento: reaproveita a que já estiver
  /// aberta na pilha ou abre uma nova por cima da tela atual.
  void _openWorkout(ActiveWorkout active) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final name = workoutRouteName(active.chartId, active.dayId);
    if (openWorkoutRoutes.contains(name)) {
      navigator.popUntil((route) => route.settings.name == name || route.isFirst);
      return;
    }

    // Planilha do treino em andamento, buscada nas planilhas carregadas
    TrainingChart? chart;
    for (final c in TrainingChartService().charts) {
      if (c.id == active.chartId) chart = c;
    }
    if (chart == null) return;

    final day = chart.days.firstWhere(
      (d) => d.id == active.dayId,
      // Dia removido da planilha: a tela usa só os exercícios registrados
      orElse: () => TrainingDay(id: active.dayId, name: 'Treino', order: 0),
    );
    navigator.push(WorkoutSessionPage.route(chart, day));
  }

  @override
  Widget build(BuildContext context) {
    final active = _service.active;
    final hidden =
        active == null ||
        visibleWorkoutRoute.value ==
            workoutRouteName(active.chartId, active.dayId);

    // Mantém o cronômetro dentro da tela, mesmo após girar o aparelho
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final right = _margin.dx.clamp(8.0, size.width - 110);
    final bottom = _margin.dy.clamp(
      8.0 + padding.bottom,
      size.height - padding.top - 64,
    );

    return Stack(
      children: [
        widget.child,
        if (!hidden)
          Positioned(
            right: right,
            bottom: bottom,
            child: GestureDetector(
              onPanUpdate: (details) => setState(() {
                _margin = Offset(
                  right - details.delta.dx,
                  bottom - details.delta.dy,
                );
              }),
              child: _TimerPill(
                text: formatStopwatch(_service.elapsed),
                onTap: () => _openWorkout(active),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pílula com o tempo do treino.
class _TimerPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _TimerPill({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);

    return Semantics(
      button: true,
      label: 'Voltar ao treino em andamento',
      child: Material(
        key: const Key('workout_timer_overlay'),
        color: cs.primary,
        elevation: 6,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, size: 18, color: cs.onPrimary),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    // Números de largura fixa: o texto não "pula" a cada segundo
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
