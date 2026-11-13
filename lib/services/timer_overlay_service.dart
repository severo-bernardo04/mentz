import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'settings_service.dart';
import 'workout_session_service.dart';

/// Acesso à janela flutuante do sistema. Fica atrás de uma interface para
/// os testes rodarem sem o Android.
abstract class TimerOverlayPlatform {
  /// A plataforma permite janelas sobre outros apps (hoje, só o Android).
  bool get isSupported;

  Future<bool> isPermissionGranted();

  /// Abre a tela de permissão do sistema. Retorna true se foi concedida.
  Future<bool> requestPermission();

  /// Mostra o cronômetro, contando a partir de [startedAt].
  Future<void> show(DateTime startedAt);

  Future<void> close();
}

/// Implementação real, com o pacote `flutter_overlay_window`.
class _AndroidTimerOverlay implements TimerOverlayPlatform {
  /// Reenvios do horário de início: a janela roda em outro isolate e pode
  /// ainda não estar ouvindo quando o primeiro envio chega.
  static const _resendDelays = [
    Duration(milliseconds: 300),
    Duration(seconds: 1),
    Duration(milliseconds: 2500),
  ];

  /// Tamanho da janela, em dp.
  static const _windowWidthDp = 124.0;
  static const _windowHeightDp = 52.0;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> isPermissionGranted() =>
      FlutterOverlayWindow.isPermissionGranted();

  @override
  Future<bool> requestPermission() async =>
      await FlutterOverlayWindow.requestPermission() ?? false;

  @override
  Future<void> show(DateTime startedAt) async {
    final startedAtMs = startedAt.millisecondsSinceEpoch;

    if (!await FlutterOverlayWindow.isActive()) {
      // O pacote usa o tamanho inicial em pixels físicos, não em dp: sem
      // converter pela densidade, a janela sai com um terço do tamanho
      final ratio = WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .devicePixelRatio;

      await FlutterOverlayWindow.showOverlay(
        height: (_windowHeightDp * ratio).round(),
        width: (_windowWidthDp * ratio).round(),
        alignment: OverlayAlignment.centerRight,
        enableDrag: true,
        positionGravity: PositionGravity.auto,
        overlayTitle: 'Treino em andamento',
        overlayContent: 'Toque para voltar ao Mentz',
      );
    }

    await FlutterOverlayWindow.shareData(startedAtMs);
    for (final delay in _resendDelays) {
      Timer(delay, () async {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.shareData(startedAtMs);
        }
      });
    }
  }

  @override
  Future<void> close() async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }
}

/// Mostra o cronômetro sobre outros apps quando o Mentz sai da frente.
///
/// A janela só aparece com as três condições juntas: modo "overlay" nas
/// configurações, treino em andamento e app em segundo plano. Com o app
/// aberto, vale o cronômetro flutuante interno. No modo "App aberto", a
/// janela nunca aparece.
class TimerOverlayService with WidgetsBindingObserver {
  static final TimerOverlayService _instance = TimerOverlayService._internal();
  factory TimerOverlayService() => _instance;
  TimerOverlayService._internal();

  TimerOverlayPlatform _platform = _AndroidTimerOverlay();
  final _settings = SettingsService();
  final _session = WorkoutSessionService();

  bool _attached = false;
  bool _inBackground = false;

  /// Evita reabrir ou refechar a janela a cada notificação dos services.
  DateTime? _shownFor;

  bool get isSupported => _platform.isSupported;

  /// Começa a acompanhar o ciclo de vida do app, o treino e as configurações.
  /// Chamado uma vez, na inicialização.
  void attach() {
    if (_attached || !isSupported) return;
    _attached = true;

    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_sync);
    _session.addListener(_sync);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // "inactive" é passageiro (ex: puxar a barra de notificações): ignora
    if (state == AppLifecycleState.inactive) return;

    _inBackground = state != AppLifecycleState.resumed;
    _sync();
  }

  /// Ativa o modo overlay, pedindo a permissão de sobreposição se faltar.
  /// Retorna false (e mantém o modo atual) se a plataforma não tiver o
  /// recurso ou se o usuário recusar a permissão.
  Future<bool> enableOverlayMode() async {
    if (!isSupported) return false;

    final granted =
        await _platform.isPermissionGranted() ||
        await _platform.requestPermission();
    if (!granted) return false;

    await _settings.setTimerDisplayMode('overlay');
    return true;
  }

  /// Sincronizações em fila: cada uma só começa quando a anterior termina.
  Future<void> _queue = Future.value();

  /// Abre ou fecha a janela conforme o estado atual.
  ///
  /// As chamadas são enfileiradas porque ao sair do app o sistema avisa duas
  /// vezes seguidas ("hidden" e "paused"). Sem a fila, as duas pediam a
  /// janela ao mesmo tempo, e o segundo pedido derrubava o serviço do Android.
  Future<void> _sync() => _queue = _queue.then((_) => _applyState());

  Future<void> _applyState() async {
    final startedAt = _session.active?.startedAt;
    final wanted =
        _inBackground &&
        startedAt != null &&
        _settings.timerDisplayMode == 'overlay';

    try {
      if (!wanted) {
        if (_shownFor == null) return;
        _shownFor = null;
        await _platform.close();
        return;
      }

      if (_shownFor == startedAt) return;
      // A permissão pode ter sido retirada nas configurações do sistema
      if (!await _platform.isPermissionGranted()) return;

      _shownFor = startedAt;
      await _platform.show(startedAt);
    } catch (_) {
      _shownFor = null;
      debugPrint('Não foi possível atualizar o cronômetro em overlay.');
    }
  }

  /// Usa uma plataforma falsa e simula o app indo para segundo plano.
  @visibleForTesting
  Future<void> syncForTest({
    required TimerOverlayPlatform platform,
    required bool inBackground,
  }) {
    _platform = platform;
    _inBackground = inBackground;
    return _sync();
  }

  @visibleForTesting
  void resetForTest() {
    _platform = _AndroidTimerOverlay();
    _inBackground = false;
    _shownFor = null;
    _queue = Future.value();
  }
}
