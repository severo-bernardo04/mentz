import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/core/routes/app_navigation.dart';
import 'package:mentz/features/workout_session/workout_session_page.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/services/workout_session_service.dart';
import 'package:mentz/widgets/workout_timer_overlay.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutSessionService service;
  late DateTime now;

  const day = TrainingDay(id: 'd0', name: 'TREINO A', order: 1);
  final chart = TrainingChart(
    id: 'c1',
    name: 'Hipertrofia',
    createdAt: DateTime(2026, 11, 1),
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.fixedDays,
      fixedWeekdays: [1, 3, 5],
    ),
    days: const [day],
  );

  final pill = find.byKey(const Key('workout_timer_overlay'));

  /// App montado como no main.dart, com uma tela inicial e outra qualquer.
  Widget app() => MaterialApp(
        navigatorKey: appNavigatorKey,
        navigatorObservers: [appRouteObserver],
        builder: (context, child) => WorkoutTimerOverlay(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    WorkoutSessionPage.route(chart, day),
                  ),
                  child: const Text('abrir treino'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('outra tela')),
                    ),
                  ),
                  child: const Text('abrir outra'),
                ),
              ],
            ),
          ),
        ),
      );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/user-a').set({'name': 'Aluno', 'role': 'student'});
    await firestore.doc('users/user-a/charts/c1').set(chart.toMap());
    now = DateTime(2026, 11, 10, 14, 0);

    ExerciseCatalogService().setExercisesForTest([]);
    TrainingChartService().startForTest(firestore, uid: 'user-a');
    service = WorkoutSessionService();
    service.startForTest(firestore, uid: 'user-a', clock: () => now);
  });

  tearDown(() {
    service.stopWatching('user-a');
    TrainingChartService().stopWatching('user-a');
    ExerciseCatalogService().clearForTest();
    visibleWorkoutRoute.value = null;
    openWorkoutRoutes.clear();
  });

  testWidgets('sem treino em andamento, o cronômetro não aparece', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(pill, findsNothing);
  });

  testWidgets('com treino em andamento, aparece sobre as outras telas', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.runAsync(() => service.start(chart, day));
    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));

    expect(pill, findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    await tester.tap(find.text('abrir outra'));
    await tester.pumpAndSettle();

    expect(find.text('outra tela'), findsOneWidget);
    expect(pill, findsOneWidget);
  });

  testWidgets('tocar no cronômetro abre o treino, e nele o cronômetro some', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.runAsync(() => service.start(chart, day));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(pill);
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutSessionPage), findsOneWidget);
    expect(pill, findsNothing);

    // Ao sair da tela do treino, o cronômetro volta
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(pill, findsOneWidget);
  });

  testWidgets('com o treino já aberto por baixo, volta para ele sem duplicar', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.runAsync(() => service.start(chart, day));
    await tester.tap(find.text('abrir treino'));
    await tester.pumpAndSettle();

    // Abre o histórico por cima do treino: o cronômetro reaparece
    await tester.tap(find.byKey(const Key('open_full_history_button')));
    await tester.pumpAndSettle();
    expect(pill, findsOneWidget);

    await tester.tap(pill);
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutSessionPage), findsOneWidget);
    expect(pill, findsNothing);
  });

  testWidgets('ao finalizar o treino, o cronômetro some', (tester) async {
    await tester.pumpWidget(app());
    await tester.runAsync(() => service.start(chart, day));
    await tester.pump(const Duration(seconds: 1));
    expect(pill, findsOneWidget);

    await tester.runAsync(() => service.finish(chart, day));
    await tester.pump();

    expect(pill, findsNothing);
  });
}
