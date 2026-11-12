import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/widgets/timer_overlay_window.dart';

void main() {
  // A janela do Android pode ter qualquer tamanho lógico, inclusive bem
  // pequeno: o conteúdo precisa se ajustar sem estourar.
  for (final size in const [Size(132, 56), Size(60, 24), Size(300, 120)]) {
    testWidgets('cabe em uma janela de ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final messages = StreamController<dynamic>();
      addTearDown(messages.close);

      await tester.pumpWidget(
        MaterialApp(home: TimerOverlayWindow(messages: messages.stream)),
      );
      expect(find.text('--:--'), findsOneWidget);

      // Recebe o horário de início e passa a mostrar o tempo
      messages.add(
        DateTime.now()
            .subtract(const Duration(minutes: 75))
            .millisecondsSinceEpoch,
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('1:15:'), findsOneWidget);
    });
  }
}
