import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/screens/create_training_chart_page.dart';
import 'package:mentz/services/training_chart_service.dart';

void main() {
  late TrainingChartService service;

  setUp(() {
    service = TrainingChartService();
    service.clearForTest();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Scaffold(
        body: CreateTrainingChartPage(service: service),
      ),
    );
  }

  group('CreateTrainingChartPage Tests', () {
    testWidgets('renderiza os elementos principais da tela de nova planilha',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Nova Planilha'), findsOneWidget);
      expect(find.byKey(const Key('chart_name_field')), findsOneWidget);
      expect(find.text('Frequência de Execução'), findsOneWidget);
      expect(find.text('Criar Planilha'), findsOneWidget);
      expect(find.byKey(const Key('add_day_button')), findsOneWidget);

      // Deve iniciar com 3 dias padrões (ABC)
      expect(find.byKey(const Key('day_item_0')), findsOneWidget);
      expect(find.byKey(const Key('day_item_1')), findsOneWidget);
      expect(find.byKey(const Key('day_item_2')), findsOneWidget);
    });

    testWidgets('valida que o nome da planilha é obrigatório',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Limpa o nome da planilha
      await tester.enterText(find.byKey(const Key('chart_name_field')), '');
      await tester.pump();

      // Clica em salvar
      await tester.tap(find.text('Criar Planilha'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome da planilha.'), findsOneWidget);
      expect(service.charts.isEmpty, isTrue);
    });

    testWidgets('permite adicionar, editar e remover dias de treino',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Adiciona um quarto dia (TREINO D)
      await tester.tap(find.byKey(const Key('add_day_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('day_item_3')), findsOneWidget);
      expect(find.text('TREINO D'), findsOneWidget);

      // Edita o nome do dia 0
      await tester.enterText(
        find.byKey(const Key('day_name_field_0')),
        'FULL BODY 1',
      );
      await tester.pump();
      expect(find.text('FULL BODY 1'), findsOneWidget);

      // Remove o dia 3
      await tester.tap(find.byKey(const Key('delete_day_button_3')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('day_item_3')), findsNothing);
    });

    testWidgets('impede remoção quando houver apenas um dia de treino',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Remove dia 2 e dia 1
      await tester.tap(find.byKey(const Key('delete_day_button_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_day_button_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('day_item_0')), findsOneWidget);
      expect(find.byKey(const Key('day_item_1')), findsNothing);

      // Tenta remover o último dia
      await tester.tap(find.byKey(const Key('delete_day_button_0')));
      await tester.pumpAndSettle();

      // O dia ainda deve permanecer
      expect(find.byKey(const Key('day_item_0')), findsOneWidget);
      expect(
        find.text('A planilha deve conter pelo menos um dia de treino.'),
        findsOneWidget,
      );
    });

    testWidgets('valida que o nome de cada dia de treino é obrigatório',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Esvazia o nome do dia 0
      await tester.enterText(find.byKey(const Key('day_name_field_0')), '');
      await tester.pump();

      await tester.tap(find.text('Criar Planilha'));
      await tester.pumpAndSettle();

      expect(find.text('Nome obrigatório'), findsOneWidget);
      expect(service.charts.isEmpty, isTrue);
    });

    testWidgets('alterna entre frequência de dias fixos e por intervalo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verifica exibição de dias fixos inicial
      expect(find.text('Dias da semana em que você treina:'), findsOneWidget);

      // Alterna para 'Por Intervalo'
      await tester.tap(find.text('Por Intervalo'));
      await tester.pumpAndSettle();

      expect(find.text('Ciclo por intervalos variáveis:'), findsOneWidget);
      expect(find.textContaining('Descanso após este treino:'), findsWidgets);
    });

    testWidgets('cria e persiste uma planilha válida com sucesso',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('chart_name_field')),
        'Planilha Força Máxima',
      );
      await tester.enterText(
        find.byKey(const Key('chart_desc_field')),
        'Foco em progressão de carga',
      );

      // Clica em salvar
      await tester.tap(find.text('Criar Planilha'));

      // Processa a animação e operação assíncrona
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Confirma que foi salvo no serviço
      expect(service.charts.length, 1);
      final chart = service.charts.first;
      expect(chart.name, 'Planilha Força Máxima');
      expect(chart.description, 'Foco em progressão de carga');
      expect(chart.days.length, 3);
      expect(chart.days[0].name, 'TREINO A');
      expect(chart.frequencyConfig.type, WorkoutFrequencyType.fixedDays);
    });
  });
}
