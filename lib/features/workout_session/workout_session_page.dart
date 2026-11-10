import 'package:flutter/material.dart';

import '../../core/routes/fade_slide_route.dart';
import '../../core/utils/snackbars.dart';
import '../../models/profile_models.dart';
import '../../models/training_chart.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_hint.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/section_card.dart';
import '../training_history/workout_spreadsheet_page.dart';
import 'controllers/workout_session_controller.dart';
import 'widgets/pending_exercises_sheet.dart';
import 'widgets/session_exercise_card.dart';
import 'widgets/session_timer_card.dart';

/// Escolha ao iniciar quando um treino anterior ficou com pendentes.
enum _PendingChoice { complete, startCurrent, ignoreAndStart }

/// Tela de um dia da planilha: mostra os exercícios, permite iniciar e
/// finalizar o treino com cronômetro e registrar carga e repetições.
///
/// Se um treino anterior da planilha ficou incompleto, oferece completá-lo
/// (o cronômetro roda sem contar um treino novo) ou ignorar os pendentes.
class WorkoutSessionPage extends StatefulWidget {
  final TrainingChart chart;
  final TrainingDay day;

  const WorkoutSessionPage({super.key, required this.chart, required this.day});

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  late final _controller = WorkoutSessionController(
    chart: widget.chart,
    day: widget.day,
  );

  /// Uma chave por exercício exibido, para rolar até ele ao tocar em COMPLETAR.
  final _exerciseKeys = <int, GlobalKey>{};

  GlobalKey _keyFor(int index) => _exerciseKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Nome curto de uma sessão anterior (ex: "FULL BODY 2 de 10/11").
  static String _sessionName(CompletedWorkout session) =>
      '${session.workoutName ?? session.plan} de ${formatShort(session.date)}';

  // ─────────────── Iniciar ───────────────

  Future<void> _start() async {
    final previous = _controller.previousPending;
    if (previous != null) return _startWithPrevious(previous);

    final confirmed = await showConfirmDialog(
      context,
      title: 'Iniciar ${widget.day.name}?',
      message: 'O cronômetro começa agora e continua mesmo se você sair desta tela.',
      confirmLabel: 'Iniciar',
    );
    if (!confirmed) return;

    await _controller.start();
  }

  /// Com pendentes de um treino anterior: completar, iniciar este ou ignorar.
  Future<void> _startWithPrevious(CompletedWorkout previous) async {
    final choice = await showDialog<_PendingChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Treino anterior incompleto'),
        content: Text(
          'O ${_sessionName(previous)} ficou com '
          '${previous.pendingIndexes.length} exercício(s) pendente(s).\n\n'
          '• Completar o anterior: só registra o que faltou. Este treino não '
          'é contado e passa para a próxima data.\n'
          '• Iniciar ${widget.day.name}: os pendentes aparecem junto e podem '
          'ser feitos no mesmo tempo.',
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 4,
        actions: [
          FilledButton(
            key: const Key('choice_complete'),
            onPressed: () => Navigator.of(context).pop(_PendingChoice.complete),
            child: const Text('Completar o anterior'),
          ),
          OutlinedButton(
            key: const Key('choice_start_current'),
            onPressed: () =>
                Navigator.of(context).pop(_PendingChoice.startCurrent),
            child: Text('Iniciar ${widget.day.name}'),
          ),
          TextButton(
            key: const Key('choice_ignore'),
            onPressed: () =>
                Navigator.of(context).pop(_PendingChoice.ignoreAndStart),
            child: const Text('Ignorar pendentes e iniciar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    switch (choice) {
      case _PendingChoice.complete:
        await _startCompletion(previous);
      case _PendingChoice.startCurrent:
        await _controller.start(carryFrom: previous);
      case _PendingChoice.ignoreAndStart:
        if (await _controller.ignorePending(previous)) await _controller.start();
      case null:
        break;
    }
  }

  /// Inicia o modo completar e abre a tela do dia da sessão anterior, que é
  /// onde os exercícios pendentes aparecem.
  Future<void> _startCompletion(CompletedWorkout previous) async {
    if (!await _controller.startCompletion(previous) || !mounted) return;
    if (previous.dayId == widget.day.id) return;

    final day = widget.chart.days.firstWhere(
      (d) => d.id == previous.dayId,
      // Dia removido da planilha: a tela usa só os exercícios pendentes
      orElse: () => TrainingDay(
        id: previous.dayId!,
        name: previous.workoutName ?? previous.plan,
        order: 0,
      ),
    );
    Navigator.of(context).pushReplacement(
      fadeSlideRoute<void>(WorkoutSessionPage(chart: widget.chart, day: day)),
    );
  }

  /// Pendentes do treino anterior, com COMPLETAR e IGNORAR.
  void _showPreviousPending(CompletedWorkout previous) {
    final indexes = previous.pendingIndexes;

    showPendingExercisesSheet(
      context,
      names: [for (final i in indexes) previous.executedExercises[i].name],
      indexes: indexes,
      subtitle: '${_sessionName(previous)}. COMPLETAR inicia o cronômetro '
          'sem contar um treino novo.',
      onCompleteAll: () => _startCompletion(previous),
      onIgnore: () => _ignore(previous),
    );
  }

  Future<void> _ignore(CompletedWorkout previous) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Ignorar pendentes?',
      message: 'O ${_sessionName(previous)} não será mais oferecido para '
          'completar. No histórico, os exercícios continuam como não realizados.',
      confirmLabel: 'Ignorar',
    );
    if (confirmed) await _controller.ignorePending(previous);
  }

  // ─────────────── Finalizar ───────────────

  Future<void> _finish() async {
    final c = _controller;
    final pending = c.pendingIndexes.length;
    final completing = c.completingSession;
    final carried = c.carriedSession;

    final confirmed = await showConfirmDialog(
      context,
      title: completing == null ? 'Finalizar treino?' : 'Finalizar complemento?',
      message: [
        if (pending > 0)
          pending == 1
              ? '1 exercício não foi marcado como feito.'
              : '$pending exercícios não foram marcados como feitos.',
        if (carried != null)
          'Os pendentes trabalhados voltam para o ${_sessionName(carried)}; '
              'os demais continuam pendentes.',
        completing == null
            ? 'O cronômetro para e o treino é salvo no histórico.'
            : 'O cronômetro para e os exercícios são adicionados ao '
                  '${_sessionName(completing)}.',
      ].join('\n\n'),
      confirmLabel: 'Finalizar',
    );
    if (!confirmed) return;

    final session = await c.finish();
    if (session == null || !mounted) return;

    context.showSnack(
      completing == null
          ? 'Treino salvo no histórico (${session.minutes} min).'
          : '${_sessionName(completing)} atualizado.',
    );
    Navigator.of(context).pop();
  }

  Future<void> _discard() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Descartar?',
      message: 'O cronômetro para e nada do que foi registrado agora é salvo.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (!confirmed) return;

    await _controller.discard();
  }

  /// Pendentes do treino em andamento; COMPLETAR rola até o exercício.
  void _showPending() {
    final indexes = _controller.pendingIndexes;
    final executed = _controller.allExercises;

    showPendingExercisesSheet(
      context,
      names: [for (final i in indexes) executed[i].name],
      indexes: indexes,
      // COMPLETAR só existe com o cronômetro rodando
      onComplete: _controller.isRunning ? _scrollToExercise : null,
    );
  }

  void _scrollToExercise(int index) {
    final target = _exerciseKeys[index]?.currentContext;
    if (target == null) return;

    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  // ─────────────── Tela ───────────────

  /// Cartões dos exercícios: com campos quando o cronômetro roda, ou as
  /// séries planejadas antes de iniciar.
  Widget _exerciseList() {
    final c = _controller;
    final executed = c.executed;

    if (executed == null) {
      final planned = widget.day.exercises;
      if (planned.isEmpty) {
        return const EmptyHint('Este treino ainda não tem exercícios.');
      }
      return Column(
        children: [
          for (var i = 0; i < planned.length; i++)
            SessionExerciseCard(key: _keyFor(i), index: i, planned: planned[i]),
        ],
      );
    }

    final all = c.allExercises;
    final carried = c.carriedSession;
    if (all.isEmpty) {
      return const EmptyHint('Este treino ainda não tem exercícios.');
    }

    Widget card(int i) => SessionExerciseCard(
          key: _keyFor(i),
          index: i,
          planned: c.plannedAt(i),
          executed: all[i],
          previousSets: c.previousSetsFor(all[i].exerciseId),
          onChanged: (exercise) => c.updateExercise(i, exercise),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < c.ownCount; i++) card(i),
        // Pendentes de um treino anterior, feitos no tempo deste
        if (all.length > c.ownCount) ...[
          _CarriedHeader(
            carried == null ? 'treino anterior' : _sessionName(carried),
          ),
          for (var i = c.ownCount; i < all.length; i++) card(i),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final pending = c.pendingIndexes;
        final previous = c.previousPending;
        final completing = c.completingSession;

        return AppPageScaffold(
          title: day.name,
          actions: [
            // Atalho discreto para o histórico completo deste treino em planilha
            IconButton(
              key: const Key('open_full_history_button'),
              tooltip: 'Histórico completo',
              icon: const Icon(Icons.table_chart_outlined),
              onPressed: () => context.pushFade(
                WorkoutSpreadsheetPage(initialPlan: day.name),
              ),
            ),
            if (c.isRunning)
              PopupMenuButton<void>(
                tooltip: 'Mais opções',
                itemBuilder: (context) => [
                  PopupMenuItem(onTap: _discard, child: const Text('Descartar')),
                ],
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [widget.chart.name, ?day.focusOrDescription].join('  •  '),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              SessionTimerCard(elapsed: c.elapsed, startedAt: c.startedAt),
              const SizedBox(height: 16),
              if (completing != null) ...[
                _CompletingNotice(_sessionName(completing)),
                const SizedBox(height: 12),
              ],
              if (c.errorMessage != null) ...[
                ErrorBanner(c.errorMessage!),
                const SizedBox(height: 12),
              ],
              if (c.otherIsRunning) ...[
                ErrorBanner(
                  'O ${c.otherWorkoutName ?? 'outro treino'} está em andamento. '
                  'Finalize-o antes de iniciar este.',
                ),
                const SizedBox(height: 12),
              ],
              if (previous != null) ...[
                IncompleteWorkoutBanner(
                  tapKey: const Key('previous_pending_banner'),
                  title: '${_sessionName(previous)} ficou incompleto',
                  pendingCount: previous.pendingIndexes.length,
                  onTap: () => _showPreviousPending(previous),
                ),
                const SizedBox(height: 12),
              ],
              if (c.isRunning && pending.isNotEmpty) ...[
                IncompleteWorkoutBanner(
                  pendingCount: pending.length,
                  onTap: _showPending,
                ),
                const SizedBox(height: 12),
              ],
              if (c.isRunning)
                AppButton(
                  key: const Key('finish_workout_button'),
                  label: 'FINALIZAR',
                  icon: Icons.stop_rounded,
                  loading: c.busy,
                  onPressed: _finish,
                )
              else if (!c.otherIsRunning)
                AppButton(
                  key: const Key('start_workout_button'),
                  label: 'INICIAR',
                  icon: Icons.play_arrow_rounded,
                  loading: c.busy,
                  onPressed: _start,
                ),
              const SizedBox(height: 20),
              SectionCard(
                title: completing == null ? 'Exercícios' : 'Exercícios pendentes',
                icon: Icons.fitness_center_rounded,
                child: _exerciseList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Título da seção de pendentes trazidos de um treino anterior.
class _CarriedHeader extends StatelessWidget {
  final String sessionName;

  const _CarriedHeader(this.sessionName);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 18, color: incompleteColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pendentes do $sessionName',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: incompleteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso do modo completar: o cronômetro não conta um treino novo.
class _CompletingNotice extends StatelessWidget {
  final String sessionName;

  const _CompletingNotice(this.sessionName);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.playlist_add_check_rounded, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Completando o $sessionName. Este treino não é contado como novo.',
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
