import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/home/widgets/current_training_chart.dart';
import 'package:mentz/features/workout_session/workout_session_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/services/workout_schedule_service.dart';
import 'package:mentz/services/workout_session_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  final history = TrainingHistoryService();

  const dayA = TrainingDay(id: 'dA', name: 'TREINO A', order: 1);
  const dayB = TrainingDay(id: 'dB', name: 'TREINO B', order: 2);

  // Intervalo com 1 dia de descanso: sem histórico, o TREINO A é para hoje;
  // feito hoje, o TREINO B fica para depois de amanhã.
  final chart = TrainingChart(
    id: 'c1',
    name: 'Hipertrofia',
    createdAt: DateTime(2026, 11, 1),
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.intervalDays,
      intervalRestDays: [1, 1],
    ),
    days: const [dayA, dayB],
  );

  CompletedWorkout doneToday(TrainingDay day) => CompletedWorkout(
        DateTime.now(),
        day.name,
        40,
        id: 's-${day.id}',
        chartId: 'c1',
        dayId: day.id,
      );

  Widget home() => const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CurrentTrainingChart()),
        ),
      );

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(home());
    // Espera o atraso da animação de entrada do cartão
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Finder inNextTag(String text) => find.descendant(
        of: find.byKey(const Key('next_day_tag')),
        matching: find.text(text),
      );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/user-a').set({'name': 'Aluno', 'role': 'student'});
    await firestore.doc('users/user-a/charts/c1').set(chart.toMap());

    ExerciseCatalogService().setExercisesForTest([]);
    TrainingChartService().startForTest(firestore, uid: 'user-a');
    WorkoutSessionService().startForTest(firestore, uid: 'user-a');
    history.setSessionsForTest([]);
  });

  tearDown(() {
    WorkoutSessionService().stopWatching('user-a');
    TrainingChartService().stopWatching('user-a');
    ExerciseCatalogService().clearForTest();
    history.clearForTest();
  });

  group('Tela inicial', () {
    testWidgets('destaca o próximo treino e avisa quando é para hoje', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(inNextTag('TREINO A'), findsOneWidget);
      expect(find.byKey(const Key('today_workout_banner')), findsOneWidget);
      expect(find.text('Treino de hoje'), findsOneWidget);
    });

    testWidgets('com o treino de hoje feito, destaca o seguinte sem o aviso', (
      tester,
    ) async {
      history.setSessionsForTest([doneToday(dayA)]);

      await pumpHome(tester);

      expect(inNextTag('TREINO B'), findsOneWidget);
      expect(find.byKey(const Key('today_workout_banner')), findsNothing);
    });

    testWidgets('tocar no aviso de hoje abre o treino', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(const Key('today_workout_banner')));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutSessionPage), findsOneWidget);
      expect(find.text('Programado para hoje'), findsOneWidget);
    });
  });

  group('Tela do treino', () {
    Future<void> openDay(WidgetTester tester, TrainingDay day) async {
      await tester.pumpWidget(
        MaterialApp(home: WorkoutSessionPage(chart: chart, day: day)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('o próximo treino mostra a data programada', (tester) async {
      await openDay(tester, dayA);

      expect(find.text('Programado para hoje'), findsOneWidget);
    });

    testWidgets('outro dia mostra qual é o próximo treino programado', (
      tester,
    ) async {
      await openDay(tester, dayB);

      expect(
        find.text('Próximo treino programado: TREINO A • hoje'),
        findsOneWidget,
      );
    });

    testWidgets('data futura aparece por extenso', (tester) async {
      history.setSessionsForTest([doneToday(dayA)]);
      final date = DateTime.now().add(const Duration(days: 2));

      await openDay(tester, dayB);

      expect(
        find.text('Programado para ${WorkoutScheduleService.whenLabel(date)}'),
        findsOneWidget,
      );
    });
  });
}
