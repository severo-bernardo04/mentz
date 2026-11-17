import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../core/utils/duration_format.dart';

/// Conteúdo da janela flutuante do Android (cronômetro sobre outros apps).
///
/// Roda em um isolate separado do app, sem acesso aos services nem ao
/// Firebase. Por isso recebe pelo canal do `flutter_overlay_window` só o
/// horário de início do treino (int, em milissegundos) e calcula o tempo
/// sozinho, pelo relógio; ou, com o treino pausado, um mapa
/// `{'frozenMs': tempo}` com o tempo parado.
class TimerOverlayWindow extends StatefulWidget {
  /// Mensagens vindas do app. Por padrão, o canal do pacote; os testes
  /// passam um stream próprio, porque o do pacote só aceita um ouvinte.
  final Stream<dynamic>? messages;

  const TimerOverlayWindow({super.key, this.messages});

  @override
  State<TimerOverlayWindow> createState() => _TimerOverlayWindowState();
}

class _TimerOverlayWindowState extends State<TimerOverlayWindow> {
  StreamSubscription<dynamic>? _subscription;
  Timer? _ticker;
  DateTime? _startedAt;

  /// Tempo parado, quando o treino está pausado.
  Duration? _frozen;

  @override
  void initState() {
    super.initState();
    _subscription = (widget.messages ?? FlutterOverlayWindow.overlayListener)
        .listen(_onData);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Recebe do app o horário de início (rodando) ou o tempo parado (pausado).
  void _onData(dynamic data) {
    if (!mounted) return;

    if (data is int) {
      setState(() {
        _startedAt = DateTime.fromMillisecondsSinceEpoch(data);
        _frozen = null;
      });
    } else if (data is Map && data['frozenMs'] is num) {
      setState(
            () => _frozen = Duration(milliseconds: (data['frozenMs'] as num).toInt()),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = _startedAt;
    final frozen = _frozen;
    final elapsed =
        frozen ??
            (startedAt == null ? null : DateTime.now().difference(startedAt));

    // A pílula ocupa a janela inteira e o conteúdo se ajusta a ela com
    // FittedBox: o tamanho lógico da janela varia conforme o aparelho, e um
    // conteúdo de tamanho fixo estourava a largura.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      frozen != null
                          ? Icons.pause_rounded
                          : Icons.timer_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      elapsed == null || elapsed.isNegative
                          ? '--:--'
                          : formatStopwatch(elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}