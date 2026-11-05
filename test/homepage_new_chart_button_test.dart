import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/training/create_training_chart_page.dart';
import 'package:mentz/features/home/home_page.dart';
import 'package:mentz/services/training_chart_service.dart';

void main() {
  late TrainingChartService service;

  setUp(() {
    service = TrainingChartService();
    service.clearForTest();
  });

  Widget createHomePageUnderTest() {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomePage(userName: 'Bernardo'),
    );
  }

  group('HomePage "Nova Planilha" Button Tests', () {
    testWidgets('exibe o atalho "Nova Planilha" nos atalhos rápidos',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHomePageUnderTest());
      await tester.pumpAndSettle();

      // Atalho rápido "Nova Planilha" no grid de atalhos
      expect(find.byKey(const Key('home_new_chart_shortcut_card')), findsOneWidget);
      expect(find.text('Nova Planilha'), findsOneWidget);
    });

    testWidgets(
        'o clique no atalho "Nova Planilha" abre CreateTrainingChartPage e atualiza a listagem ao salvar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHomePageUnderTest());
      await tester.pumpAndSettle();

      // Estado inicial sem planilhas
      expect(find.text('Nenhuma planilha cadastrada ainda.'), findsOneWidget);

      // Clica no atalho "Nova Planilha"
      await tester.tap(find.byKey(const Key('home_new_chart_shortcut_card')));
      await tester.pumpAndSettle();

      // Verifica que abriu a tela CreateTrainingChartPage
      expect(find.byType(CreateTrainingChartPage), findsOneWidget);
      expect(find.text('Nova Planilha'), findsOneWidget);

      // Preenche os dados
      await tester.enterText(
        find.byKey(const Key('chart_name_field')),
        'Treino Hipertrofia A/B/C',
      );
      await tester.pump();

      // Salva
      await tester.tap(find.text('Criar Planilha'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Retornou para a HomePage
      expect(find.byType(CreateTrainingChartPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);

      // Confirma que a nova planilha aparece listada reativamente na tela inicial
      expect(find.text('Treino Hipertrofia A/B/C'), findsOneWidget);
      expect(find.text('Nenhuma planilha cadastrada ainda.'), findsNothing);
    });

    testWidgets('o botão de voltar da CreateTrainingChartPage retorna para a HomePage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHomePageUnderTest());
      await tester.pumpAndSettle();

      // Abre a tela pelo atalho
      await tester.tap(find.byKey(const Key('home_new_chart_shortcut_card')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateTrainingChartPage), findsOneWidget);

      // Clica no botão de voltar
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // Confirma retorno para a HomePage
      expect(find.byType(CreateTrainingChartPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
