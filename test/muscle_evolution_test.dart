import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/home/widgets/muscle_evolution_chart.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/muscle_evolution_service.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/widgets/simple_line_chart.dart';

void main() {
  // Supino: Peito principal (3) e Tríceps em alta ativação (2)
  final bench = Exercise(
    id: 'supino',
    name: 'Supino',
    muscle: 'Peito',
    primaryMuscle: 'Peitoral maior',
    highActivationMuscles: ['Tríceps'],
  );
  // Tríceps corda: só Tríceps, como principal (3)
  final pushdown = Exercise(
    id: 'corda',
    name: 'Tríceps corda',
    muscle: 'Tríceps',
    primaryMuscle: 'Tríceps',
  );

  Exercise? lookup(String id) =>
      {'supino': bench, 'corda': pushdown}[id];

  ExecutedSet set(
    double load,
    double reps, {
    SetType type = SetType.working,
    bool bodyWeight = false,
    List<DropStage> drop = const [],
  }) => ExecutedSet(
        setNumber: 1,
        type: type,
        loadKg: load,
        reps: reps,
        bodyWeight: bodyWeight,
        isDropSet: drop.isNotEmpty,
        dropStages: drop,
      );

  ExecutedExercise done(Exercise e, List<ExecutedSet> sets) =>
      ExecutedExercise(exerciseId: e.id, name: e.name, sets: sets);

  CompletedWorkout session(
    int day,
    List<ExecutedExercise> exercises, {
    String chartId = 'c1',
  }) => CompletedWorkout(
        DateTime(2026, 11, day, 18),
        'TREINO A',
        50,
        id: 's$day-$chartId',
        chartId: chartId,
        dayId: 'dA',
        executedExercises: exercises,
      );

  MuscleEvolution evolve(List<CompletedWorkout> sessions) =>
      MuscleEvolutionService.evolutionOf('c1', sessions, findExercise: lookup);

  group('1RM', () {
    test('é carga × (1 + repetições / 30)', () {
      expect(MuscleEvolutionService.oneRepMax(60, 10), closeTo(80, 0.001));
      expect(MuscleEvolutionService.oneRepMax(90, 15), closeTo(135, 0.001));
    });

    test('com 1 repetição, é a própria carga', () {
      expect(MuscleEvolutionService.oneRepMax(100, 1), 100);
    });

    test('sem carga ou sem repetições, não há 1RM', () {
      expect(MuscleEvolutionService.oneRepMax(0, 10), 0);
      expect(MuscleEvolutionService.oneRepMax(50, 0), 0);
    });

    test('só séries de Trabalho entram no cálculo', () {
      final exercise = done(bench, [
        set(200, 10, type: SetType.warmup),
        set(150, 3, type: SetType.feeder),
        set(60, 10),
      ]);

      expect(MuscleEvolutionService.bestOneRepMax(exercise), closeTo(80, 0.001));
    });

    test('em drop set, conta só a primeira etapa', () {
      final exercise = done(bench, [
        set(60, 10, drop: const [DropStage(loadKg: 300, reps: 30)]),
      ]);

      expect(MuscleEvolutionService.bestOneRepMax(exercise), closeTo(80, 0.001));
    });

    test('vale a melhor série do treino', () {
      final exercise = done(bench, [set(60, 10), set(70, 6), set(50, 12)]);

      // 60×(1+10/30)=80; 70×(1+6/30)=84; 50×(1+12/30)=70
      expect(MuscleEvolutionService.bestOneRepMax(exercise), closeTo(84, 0.001));
    });

    test('séries com peso do corpo ficam de fora por enquanto', () {
      final exercise = done(bench, [set(0, 12, bodyWeight: true)]);

      expect(MuscleEvolutionService.bestOneRepMax(exercise), isNull);
    });
  });

  group('Evolução', () {
    test('é a variação da 1RM desde o primeiro treino do exercício', () {
      final evolution = evolve([
        session(2, [done(bench, [set(60, 10)])]), // 1RM 80
        session(9, [done(bench, [set(66, 10)])]), // 1RM 88 → +10%
      ]);

      final chest = evolution.byGroup['Peito']!;
      expect(chest.map((p) => p.percent), [0, closeTo(10, 0.001)]);
      expect(chest.last.date, DateTime(2026, 11, 9, 18));
    });

    test('a evolução do músculo é ponderada pela pontuação no exercício', () {
      final evolution = evolve([
        session(2, [
          done(bench, [set(60, 10)]),
          done(pushdown, [set(30, 10)]),
        ]),
        session(9, [
          done(bench, [set(66, 10)]), // +10%
          done(pushdown, [set(36, 10)]), // +20%
        ]),
      ]);

      // Tríceps: supino +10% com peso 2 e corda +20% com peso 3
      // (10×2 + 20×3) / 5 = 16
      expect(evolution.byGroup['Tríceps']!.last.percent, closeTo(16, 0.001));
      // Peito: só o supino
      expect(evolution.byGroup['Peito']!.last.percent, closeTo(10, 0.001));
    });

    test('a visão geral é a média dos grupamentos', () {
      final evolution = evolve([
        session(2, [
          done(bench, [set(60, 10)]),
          done(pushdown, [set(30, 10)]),
        ]),
        session(9, [
          done(bench, [set(66, 10)]),
          done(pushdown, [set(36, 10)]),
        ]),
      ]);

      // (Peito 10 + Tríceps 16) / 2
      expect(evolution.overall.last.percent, closeTo(13, 0.001));
      expect(evolution.groups, ['Peito', 'Tríceps']);
    });

    test('não mistura sessões de outras planilhas', () {
      final evolution = evolve([
        session(2, [done(bench, [set(60, 10)])]),
        session(5, [done(bench, [set(120, 10)])], chartId: 'outra'),
        session(9, [done(bench, [set(66, 10)])]),
      ]);

      expect(evolution.overall, hasLength(2));
      expect(evolution.overall.last.percent, closeTo(10, 0.001));
    });

    test('exercício não feito no treino mantém a última evolução', () {
      final evolution = evolve([
        session(2, [done(bench, [set(60, 10)])]),
        session(9, [done(bench, [set(66, 10)])]),
        // Treino só de tríceps: o peito continua em +10%
        session(11, [done(pushdown, [set(30, 10)])]),
      ]);

      expect(evolution.byGroup['Peito']!.last.percent, closeTo(10, 0.001));
    });

    test('queda de carga aparece como evolução negativa', () {
      final evolution = evolve([
        session(2, [done(bench, [set(60, 10)])]),
        session(9, [done(bench, [set(54, 10)])]),
      ]);

      expect(evolution.overall.last.percent, closeTo(-10, 0.001));
    });

    test('com menos de dois treinos, não há dados suficientes', () {
      expect(evolve([]).hasData, isFalse);
      expect(evolve([session(2, [done(bench, [set(60, 10)])])]).hasData, isFalse);
    });
  });

  group('Gráfico na tela inicial', () {
    late FakeFirebaseFirestore firestore;
    final history = TrainingHistoryService();

    TrainingChart chartOf(String id, String name, DateTime createdAt) =>
        TrainingChart(
          id: id,
          name: name,
          createdAt: createdAt,
          frequencyConfig: const WorkoutFrequencyConfig(
            type: WorkoutFrequencyType.fixedDays,
            fixedWeekdays: [1, 3, 5],
          ),
          days: const [TrainingDay(id: 'dA', name: 'TREINO A', order: 1)],
        );

    Future<void> pumpChart(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MuscleEvolutionChart()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      ExerciseCatalogService().setExercisesForTest([bench, pushdown]);
      TrainingChartService().startForTest(firestore, uid: 'user-a');
      await TrainingChartService().saveChart(
        chartOf('outra', 'Antiga', DateTime(2026, 9, 1)),
      );
      await TrainingChartService().saveChart(
        chartOf('c1', 'Hipertrofia', DateTime(2026, 10, 1)),
      );
      history.setSessionsForTest([
        session(2, [
          done(bench, [set(60, 10)]),
          done(pushdown, [set(30, 10)]),
        ]),
        session(9, [
          done(bench, [set(66, 10)]),
          done(pushdown, [set(36, 10)]),
        ]),
      ]);
    });

    tearDown(() {
      TrainingChartService().stopWatching('user-a');
      ExerciseCatalogService().clearForTest();
      history.clearForTest();
    });

    testWidgets('mostra a evolução da planilha atual', (tester) async {
      await pumpChart(tester);

      expect(find.text('Hipertrofia'), findsOneWidget);
      expect(find.byType(SimpleLineChart), findsOneWidget);
      expect(
        tester.widget<SimpleLineChart>(find.byType(SimpleLineChart)).values.last,
        closeTo(13, 0.001),
      );
    });

    testWidgets('alterna entre a visão geral e um grupamento', (tester) async {
      await pumpChart(tester);

      await tester.tap(find.byKey(const Key('evolution_group_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tríceps').last);
      await tester.pumpAndSettle();

      expect(
        tester.widget<SimpleLineChart>(find.byType(SimpleLineChart)).values.last,
        closeTo(16, 0.001),
      );
    });

    testWidgets('tocar no gráfico seleciona um treino', (tester) async {
      await pumpChart(tester);

      // Toque perto da borda esquerda: primeiro treino
      final area = find.byKey(const Key('line_chart_touch_area'));
      await tester.tapAt(tester.getTopLeft(area) + const Offset(16, 40));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ao trocar a planilha atual, mostra a evolução dela', (
      tester,
    ) async {
      await pumpChart(tester);

      // A planilha antiga não tem treinos: estado vazio
      await tester.runAsync(() => TrainingChartService().selectChart('outra'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleLineChart), findsNothing);
      expect(find.textContaining('Registre ao menos dois treinos de "Antiga"'), findsOneWidget);
    });

    testWidgets('sem dados suficientes, mostra o estado vazio', (tester) async {
      history.setSessionsForTest([]);

      await pumpChart(tester);

      expect(find.byType(SimpleLineChart), findsNothing);
      expect(find.textContaining('Registre ao menos dois treinos'), findsOneWidget);
    });
  });
}
