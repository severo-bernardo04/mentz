import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/screens/create_training_chart_page.dart';
import 'package:mentz/screens/homepage.dart';
import 'package:mentz/services/training_chart_service.dart';

void main() {
  late TrainingChartService service;

  setUp(() {
    service = TrainingChartService();
    service.clearForTest();
  });

  Widget createHomepageUnderTest() {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const Homepage(userName: 'Bernardo'),
    );
  }

  group('Homepage "Nova Planilha" Button Tests', () {
    testWidgets('exibe o botão "Nova Planilha" no cabeçalho da seção e nos atalhos',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHomepageUnderTest());
      await tester.pumpAndSettle();

      // Botão da seção "Planilhas de Treino"
      expect(find.byKey(const Key('home_new_chart_button')), findsOneWidget);

      // Atalho rápido "Nova Planilha" no grid de atalhos
      final newChartTexts = find.text('Nova Planilha');
      // Deve existir exatamente 2 entradas funcionais (seção e atalhos rápidos)
      expect(newChartTexts, findsNWidgets(2));
    });

    testWidgets(
        'o clique no botão "Nova Planilha" da seção abre CreateTrainingChartPage e atualiza a listagem ao salvar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHomepageUnderTest());
      await tester.pumpAndSettle();

      // Estado inicial sem planilhas
      expect(find.text('Nenhuma planilha cadastrada ainda.'), findsOneWidget);

      // Clica no botão "Nova Planilha"
      await tester.tap(find.byKey(const Key('home_new_chart_button')));
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

      // Retornou para a Homepage
      expect(find.byType(CreateTrainingChartPage), findsNothing);
      expect(find.byType(Homepage), findsOneWidget);

      // Confirma que a nova planilha aparece listada reativamente na tela inicial
      expect(find.text('Treino Hipertrofia A/B/C'), findsOneWidget);
      expect(find.text('Nenhuma planilha cadastrada ainda.'), findsNothing);
    });

    testWidgets('o botão de voltar da CreateTrainingChartPage retorna para a Homepage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createHomepageUnderTest());
      await tester.pumpAndSettle();

      // Abre a tela pelo botão
      await tester.tap(find.byKey(const Key('home_new_chart_button')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateTrainingChartPage), findsOneWidget);

      // Clica no botão de voltar
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // Confirma retorno para a Homepage
      expect(find.byType(CreateTrainingChartPage), findsNothing);
      expect(find.byType(Homepage), findsOneWidget);
    });
  });
}
