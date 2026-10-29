import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mentz/main.dart';

void main() {
  testWidgets('App smoke test - exibe a tela de login inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Mentz'), findsWidgets);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
