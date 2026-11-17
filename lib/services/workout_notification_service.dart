import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'workout_session_service.dart';

/// O que a notificação (Android) ou a Live Activity (iOS) deve mostrar.
///
/// A contagem é feita pelo próprio sistema, não pelo app: com o treino
/// rodando, o sistema conta a partir de [baseMs]; com o treino pausado, mostra
/// [elapsedMs] parado. Por isso o tempo segue correndo com o app em segundo
/// plano, com a tela bloqueada e até com o processo do app encerrado.
class WorkoutTimerDisplay {
  /// Treino contando (false = pausado).
  final bool running;

  /// Instante (ms desde 1970) de que o treino teria começado se nunca
  /// houvesse pausa: `agora - tempoDeTreino`. Usado com o treino rodando.
  final int baseMs;

  /// Tempo de treino em ms. Usado com o treino pausado.
  final int elapsedMs;

  const WorkoutTimerDisplay({
    required this.running,
    required this.baseMs,
    required this.elapsedMs,
  });

  Map<String, Object> toMap() => {
    'running': running,
    'baseMs': baseMs,
    'elapsedMs': elapsedMs,
    'title': running ? 'Treino em andamento' : 'Treino pausado',
  };
}

/// Acesso ao recurso nativo. Fica atrás de uma interface para os testes
/// rodarem sem Android nem iOS.
abstract class WorkoutNotificationPlatform {
  /// Android (notificação) e iOS (Live Activity).
  bool get isSupported;

  /// Permissão para exibir (Android 13+: notificações; iOS: Live Activities
  /// ativadas nos Ajustes).
  Future<bool> hasPermission();

  /// Pede a permissão ao sistema. Retorna true se foi concedida.
  Future<bool> requestPermission();

  /// Mostra o cronômetro ou atualiza o que já está na tela.
  Future<void> show(WorkoutTimerDisplay display);

  /// Remove o cronômetro da tela de bloqueio e da barra de notificações.
  Future<void> hide();
}

/// Implementação real: um MethodChannel atendido pelo `MainActivity.kt`
/// (Android) e pelo `WorkoutLiveActivityBridge.swift` (iOS).
class _MethodChannelWorkoutNotification implements WorkoutNotificationPlatform {
  static const _channel = MethodChannel('mentz/workout_timer');

  @override
  bool get isSupported =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<void> show(WorkoutTimerDisplay display) =>
      _channel.invokeMethod<void>('show', display.toMap());

  @override
  Future<void> hide() => _channel.invokeMethod<void>('hide');
}

/// Mantém o cronômetro do treino na barra de notificações e na tela de
/// bloqueio (Android) ou na Live Activity (iOS) enquanto houver um treino
/// em andamento.
///
/// Acompanha o [WorkoutSessionService] e só reage a mudanças reais do
/// cronômetro (início, pausa, retomada, fim). A notificação é publicada assim
/// que o treino começa, com o app aberto, porque um app encerrado pelo
/// sistema não consegue publicar nada: dali em diante o sistema a mantém e a
/// faz contar sozinho.
class WorkoutNotificationService with WidgetsBindingObserver {
  static final WorkoutNotificationService _instance =
  WorkoutNotificationService._internal();
  factory WorkoutNotificationService() => _instance;
  WorkoutNotificationService._internal();

  WorkoutNotificationPlatform _platform = _MethodChannelWorkoutNotification();
  final _session = WorkoutSessionService();

  bool _attached = false;
  bool _permissionAsked = false;

  /// Estado já enviado ao sistema; evita republicar a cada digitação de
  /// série, já que o serviço do treino avisa a cada alteração.
  String? _shownKey;

  /// Sincronizações em fila: cada uma só começa quando a anterior termina.
  Future<void> _queue = Future.value();

  bool get isSupported => _platform.isSupported;

  /// Começa a acompanhar o treino e o ciclo de vida do app.
  /// Chamado uma vez, na inicialização.
  void attach() {
    if (_attached || !isSupported) return;
    _attached = true;

    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_sync);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ao sair do app, publica de novo: se o usuário tiver dispensado a
    // notificação, ela volta, e se a permissão tiver sido dada nas
    // configurações do sistema, ela passa a aparecer.
    if (state == AppLifecycleState.paused) {
      _shownKey = null;
      _sync();
    }
  }

  Future<void> _sync() => _queue = _queue.then((_) => _apply());

  Future<void> _apply() async {
    final active = _session.active;

    try {
      if (active == null) {
        if (_shownKey == null) return;
        _shownKey = null;
        await _platform.hide();
        return;
      }

      final elapsed = _session.elapsed;
      final base = active.effectiveStart.millisecondsSinceEpoch;
      final key = active.isPaused
          ? 'paused/${elapsed.inMilliseconds}'
          : 'running/$base';
      if (_shownKey == key) return;

      // Pede a permissão uma vez por execução, no momento em que ela faz
      // sentido para o usuário: ao iniciar o treino
      if (!_permissionAsked) {
        _permissionAsked = true;
        if (!await _platform.hasPermission()) {
          await _platform.requestPermission();
        }
      }

      _shownKey = key;
      await _platform.show(
        WorkoutTimerDisplay(
          running: !active.isPaused,
          baseMs: base,
          elapsedMs: elapsed.inMilliseconds,
        ),
      );
    } catch (_) {
      // Sem a notificação o cronômetro continua certo dentro do app
      _shownKey = null;
      debugPrint('Não foi possível atualizar a notificação do cronômetro.');
    }
  }

  /// Usa uma plataforma e um relógio de teste e sincroniza uma vez.
  @visibleForTesting
  Future<void> syncForTest({required WorkoutNotificationPlatform platform}) {
    _platform = platform;
    return _sync();
  }

  @visibleForTesting
  void resetForTest() {
    _platform = _MethodChannelWorkoutNotification();
    _shownKey = null;
    _permissionAsked = false;
    _queue = Future.value();
  }
}