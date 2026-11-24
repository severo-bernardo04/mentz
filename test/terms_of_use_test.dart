import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/auth/terms_of_use_page.dart';
import 'package:mentz/features/auth/widgets/terms_checkbox_field.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, GlobalKey<FormState> key) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(key: key, child: TermsCheckboxField()),
        ),
      ),
    );
  }

  testWidgets('a página exibe o conteúdo e as seções dos termos', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TermsOfUsePage()));

    expect(find.text('Termos de Uso'), findsOneWidget);
    expect(find.text('Termos de Uso do Mentz'), findsOneWidget);
    expect(find.text('1. Definições'), findsOneWidget);
    expect(find.byKey(const Key('terms_accept_button')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('7. Privacidade e proteção de dados (LGPD)'),
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('terms_scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.text('7. Privacidade e proteção de dados (LGPD)'),
      findsOneWidget,
    );
  });

  testWidgets('abrir os termos e aceitar marca o checkbox', (tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpField(tester, formKey);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Aceite os termos para continuar.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('terms_link')));
    await tester.pumpAndSettle();
    expect(find.text('Termos de Uso do Mentz'), findsOneWidget);

    await tester.tap(find.byKey(const Key('terms_accept_button')));
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('voltar sem aceitar mantém o checkbox desmarcado', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await pumpField(tester, formKey);

    await tester.tap(find.byKey(const Key('terms_link')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });
}
