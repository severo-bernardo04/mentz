import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/training/controllers/chart_form_controller.dart';
import 'package:mentz/features/training/controllers/planned_set_draft.dart';
import 'package:mentz/features/training/widgets/rest_time_picker.dart';
import 'package:mentz/features/training/widgets/exercise_sheet.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/features/training/create_training_chart_page.dart';
import 'package:mentz/services/training_chart_service.dart';

/// Abre o dia [index] no acordeão, caso ele esteja fechado.
Future<void> expandDay(WidgetTester tester, int index) async {
  if (find.byKey(Key('day_name_field_$index')).evaluate().isNotEmpty) return;

  await tester.tap(find.byKey(Key('day_header_$index')));
  await tester.pumpAndSettle();
}

void main() {
  late TrainingChartService service;

  setUp(() {
    service = TrainingChartService();
    service.startForTest(FakeFirebaseFirestore(), uid: 'test-user');
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
      expect(find.text('TREINO D'), findsWidgets);

      // Edita o nome do dia 0
      await expandDay(tester, 0);
      await tester.enterText(
        find.byKey(const Key('day_name_field_0')),
        'FULL BODY 1',
      );
      await tester.pump();
      expect(find.text('FULL BODY 1'), findsWidgets);

      // Remove o dia 3
      await expandDay(tester, 3);
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
      await expandDay(tester, 2);
      await tester.tap(find.byKey(const Key('delete_day_button_2')));
      await tester.pumpAndSettle();
      await expandDay(tester, 1);
      await tester.tap(find.byKey(const Key('delete_day_button_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('day_item_0')), findsOneWidget);
      expect(find.byKey(const Key('day_item_1')), findsNothing);

      // Tenta remover o último dia
      await expandDay(tester, 0);
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
      expect(find.byKey(const Key('weekday_chip_1')), findsOneWidget);

      // Alterna para 'Por Intervalo'
      await tester.tap(find.text('Por Intervalo'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weekday_chip_1')), findsNothing);
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

      // Mantém um único dia e adiciona um exercício do catálogo a ele
      await expandDay(tester, 2);
      await tester.tap(find.byKey(const Key('delete_day_button_2')));
      await tester.pumpAndSettle();
      await expandDay(tester, 1);
      await tester.tap(find.byKey(const Key('delete_day_button_1')));
      await tester.pumpAndSettle();
      await expandDay(tester, 0);
      await tester.tap(find.byKey(const Key('add_exercise_button_0')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('exercise_sheet_choose_from_catalog_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

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
      expect(chart.days.length, 1);
      expect(chart.days[0].name, 'TREINO A');
      expect(chart.days[0].exercises.length, 1);
      expect(chart.frequencyConfig.type, WorkoutFrequencyType.fixedDays);
    });

    testWidgets('não permite salvar um dia sem exercícios', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar Planilha'));
      await tester.pumpAndSettle();

      expect(
        find.text('Adicione ao menos um exercício em TREINO A.'),
        findsOneWidget,
      );
      expect(service.charts, isEmpty);
    });

    testWidgets('o formulário do dia exige um exercício do catálogo', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ExerciseSheet(catalogOnly: true))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exercício'), findsNothing);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione um exercício do catálogo.'), findsOneWidget);
    });
  });

  group('Formulário do exercício do dia', () {
    Future<void> pumpSheet(WidgetTester tester, {WorkoutExercise? exercise}) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseSheet(exercise: exercise, catalogOnly: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('não pede carga e mostra uma linha por série', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Carga inicial'), findsNothing);
      expect(find.byKey(const Key('set_range_field_2')), findsOneWidget);
      expect(find.byKey(const Key('set_range_field_3')), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('set_range_field_3')), findsOneWidget);
    });

    testWidgets('destaca o exercício já escolhido', (tester) async {
      await pumpSheet(
        tester,
        exercise: WorkoutExercise(exercise: Exercise(name: 'Supino reto')),
      );

      expect(
        find.byKey(const Key('exercise_sheet_selected_card')),
        findsOneWidget,
      );
      expect(find.text('Supino reto'), findsOneWidget);
      expect(find.text('Trocar'), findsOneWidget);
    });

    testWidgets('o descanso é opcional e só aparece ao ser ligado', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.byKey(const Key('rest_minutes_picker')), findsNothing);

      await tester.tap(find.byKey(const Key('rest_switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rest_minutes_picker')), findsOneWidget);
    });

    test('série de Reconhecimento aceita valor único no formulário', () {
      final draft = PlannedSetDraft(range: '1', type: SetType.feeder);
      addTearDown(draft.dispose);

      final set = draft.toPlannedSet();

      expect(set.type, SetType.feeder);
      expect(set.minReps, 1);
      expect(set.maxReps, 1);
    });

    test('mudar para Reconhecimento desmarca o drop set', () {
      final draft = PlannedSetDraft(range: '8-10', isDropSet: true);
      addTearDown(draft.dispose);

      draft.changeType(SetType.feeder);

      expect(draft.isDropSet, isFalse);
      expect(draft.allowsDropSet, isFalse);
      expect(draft.toPlannedSet().type, SetType.feeder);
      expect(draft.toPlannedSet().repsLabel, '8–10');
    });

    testWidgets('o carrossel devolve o descanso em segundos', (tester) async {
      var seconds = 95;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestTimePicker(
              initialSeconds: seconds,
              onChanged: (value) => seconds = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('rest_seconds_picker')),
        const Offset(0, -40),
      );
      await tester.pumpAndSettle();

      expect(seconds, greaterThan(95));
      expect(seconds ~/ 60, 1);
    });

    test('o descanso aparece em minutos e segundos', () {
      String? label(int s) => WorkoutExercise(
        exercise: Exercise(name: 'Supino reto'),
        restSeconds: s,
      ).restLabel;

      expect(label(45), '45s');
      expect(label(120), '2 min');
      expect(label(95), '1 min 35s');
    });

    test('sem descanso sugerido, o exercício não mostra descanso', () {
      final exercise = WorkoutExercise(
        exercise: Exercise(id: 'supino-reto', name: 'Supino reto'),
      );

      expect(exercise.restSeconds, isNull);
      expect(exercise.restLabel, isNull);
      expect(exercise.toMap().containsKey('restSeconds'), isFalse);
    });
  });

  group('Exercícios por dia da planilha', () {
    WorkoutExercise build(Exercise exercise) =>
        WorkoutExercise(exercise: exercise);

    test('mantém a ordem de execução ao reordenar e remover', () {
      final form = ChartFormController();
      addTearDown(form.dispose);
      final day = form.days.first;
      final a = build(Exercise(name: 'A'));
      final b = build(Exercise(name: 'B'));
      final c = build(Exercise(name: 'C'));

      form.saveExercise(day, a);
      form.saveExercise(day, b);
      form.saveExercise(day, c);
      form.reorderExercise(day, 2, 0);
      form.removeExercise(day, 1);

      final saved = form.buildChart().days.first.exercises;
      expect(saved.map((e) => e.name), ['C', 'B']);
    });

    test('o mesmo exercício do catálogo pode estar em vários dias', () {
      final form = ChartFormController();
      addTearDown(form.dispose);
      final bench = Exercise(name: 'Supino reto');

      form.saveExercise(form.days[0], build(bench));
      form.saveExercise(form.days[1], build(bench));

      final days = form.buildChart().days;
      expect(identical(days[0].exercises.first.exercise, bench), isTrue);
      expect(identical(days[1].exercises.first.exercise, bench), isTrue);
    });

    test('toMap e fromMap preservam os exercícios do dia', () {
      final bench = Exercise(id: 'supino-reto', name: 'Supino reto');
      final day = TrainingDay(
        id: 'day-1',
        name: 'TREINO A',
        order: 1,
        exercises: [
          WorkoutExercise(
            exercise: bench,
            plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
          ),
        ],
      );

      final restored = TrainingDay.fromMap(
        day.toMap(),
        findExercise: (id) => id == bench.id ? bench : null,
      );

      expect(restored.exercises.single.name, 'Supino reto');
      expect(restored.exercises.single.setsLabel, '4 × 8–10');
    });
  });
}
