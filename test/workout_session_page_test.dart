import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/training_history/workout_spreadsheet_page.dart';
import 'package:mentz/features/workout_session/workout_session_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/workout_session_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutSessionService service;
  late DateTime now;

  const dayA = TrainingDay(id: 'd0', name: 'TREINO A', order: 1);
  const dayB = TrainingDay(id: 'd1', name: 'TREINO B', order: 2);
  final chart = TrainingChart(
    id: 'c1',
    name: 'Hipertrofia',
    createdAt: DateTime(2026, 11, 1),
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.fixedDays,
      fixedWeekdays: [1, 3, 5],
    ),
    days: const [dayA, dayB],
  );

  Widget page(TrainingDay day) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutSessionPage(chart: chart, day: day),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

  /// Abre a tela do treino a partir de uma tela anterior.
  Future<void> openPage(WidgetTester tester, TrainingDay day) async {
    await tester.pumpWidget(page(day));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, String label) async {
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, label).last);
    await tester.pump();
    await tester.pump();
  }

  String timerText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('session_timer_text'))).data!;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/user-a').set({'name': 'Aluno', 'role': 'student'});
    now = DateTime(2026, 11, 10, 14, 0);
    service = WorkoutSessionService();
    service.startForTest(firestore, uid: 'user-a', clock: () => now);
  });

  tearDown(() => service.stopWatching('user-a'));

  testWidgets('INICIAR pede confirmação e inicia o cronômetro', (tester) async {
    await openPage(tester, dayA);

    await tester.tap(find.byKey(const Key('start_workout_button')));
    await confirm(tester, 'Iniciar');

    expect(find.byKey(const Key('finish_workout_button')), findsOneWidget);
    expect(find.textContaining('10/11/2026 (Terça-feira)'), findsOneWidget);

    now = now.add(const Duration(minutes: 1, seconds: 5));
    await tester.pump(const Duration(seconds: 1));

    expect(timerText(tester), '01:05');
  });

  testWidgets('cancelar a confirmação não inicia o treino', (tester) async {
    await openPage(tester, dayA);

    await tester.tap(find.byKey(const Key('start_workout_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(service.active, isNull);
    expect(find.byKey(const Key('start_workout_button')), findsOneWidget);
  });

  testWidgets('o cronômetro segue correto ao sair e voltar à tela', (
    tester,
  ) async {
    await openPage(tester, dayA);
    await tester.tap(find.byKey(const Key('start_workout_button')));
    await confirm(tester, 'Iniciar');

    // Sai da tela e volta 10 minutos depois
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 10));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(timerText(tester), '10:00');
  });

  testWidgets('FINALIZAR pede confirmação e salva a sessão', (tester) async {
    await openPage(tester, dayA);
    await tester.tap(find.byKey(const Key('start_workout_button')));
    await confirm(tester, 'Iniciar');

    now = now.add(const Duration(minutes: 45));
    await tester.tap(find.byKey(const Key('finish_workout_button')));
    await confirm(tester, 'Finalizar');
    await tester.pumpAndSettle();

    final sessions = await firestore.collection('users/user-a/sessions').get();

    expect(sessions.docs.single.data()['minutes'], 45);
    expect(service.active, isNull);
    expect(find.byType(WorkoutSessionPage), findsNothing);
  });

  group('Com exercícios', () {
    final day = TrainingDay(
      id: 'd0',
      name: 'TREINO A',
      order: 1,
      exercises: [
        WorkoutExercise(
          exercise: Exercise(id: 'supino', name: 'Supino reto'),
          plannedSets: const [PlannedSet(minReps: 8, maxReps: 10)],
        ),
        WorkoutExercise(
          exercise: Exercise(id: 'crucifixo', name: 'Crucifixo'),
          plannedSets: const [PlannedSet(minReps: 10, maxReps: 12)],
        ),
      ],
    );

    Future<void> startWorkout(WidgetTester tester) async {
      await openPage(tester, day);
      await tester.tap(find.byKey(const Key('start_workout_button')));
      await confirm(tester, 'Iniciar');
    }

    Color? repsColor(WidgetTester tester) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('reps_0_1')),
            matching: find.byType(TextField),
          ),
        )
        .style
        ?.color;

    testWidgets('registra a carga e colore as repetições pela faixa', (
      tester,
    ) async {
      await startWorkout(tester);

      await tester.enterText(find.byKey(const Key('load_0_1')), '40');
      await tester.enterText(find.byKey(const Key('reps_0_1')), '7');
      await tester.pump();
      expect(repsColor(tester), RepsPerformance.below.color);

      await tester.enterText(find.byKey(const Key('reps_0_1')), '9');
      await tester.pump();
      expect(repsColor(tester), isNull);

      await tester.enterText(find.byKey(const Key('reps_0_1')), '10');
      await tester.pump();
      expect(repsColor(tester), RepsPerformance.top.color);

      final set = service.active!.exercises.first.sets.single;
      expect(set.loadKg, 40);
      expect(set.reps, 10);

      // Deixa a gravação agrupada terminar
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('indica pendentes e COMPLETAR aparece com o cronômetro rodando', (
      tester,
    ) async {
      await startWorkout(tester);

      expect(find.text('2 exercícios pendentes'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('load_0_1')), '40');
      await tester.enterText(find.byKey(const Key('reps_0_1')), '8');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('exercise_done_0')));
      await tester.tap(find.byKey(const Key('exercise_done_0')));
      await tester.pump();
      expect(find.text('1 exercício pendente'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('incomplete_workout_banner')),
      );
      await tester.tap(find.byKey(const Key('incomplete_workout_banner')));
      await tester.pumpAndSettle();

      expect(find.text('Crucifixo'), findsWidgets);
      expect(find.text('COMPLETAR'), findsOneWidget);

      await tester.tap(find.text('COMPLETAR'));
      await tester.pumpAndSettle();
      expect(find.text('COMPLETAR'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('antes de iniciar não há indicação de pendentes', (
      tester,
    ) async {
      await openPage(tester, day);

      expect(find.byKey(const Key('incomplete_workout_banner')), findsNothing);
      expect(find.byKey(const Key('reps_0_1')), findsNothing);
    });
  });

  testWidgets('o botão do topo abre o histórico completo deste treino', (
    tester,
  ) async {
    await openPage(tester, dayA);

    await tester.tap(find.byKey(const Key('open_full_history_button')));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutSpreadsheetPage), findsOneWidget);
  });

  testWidgets('com outro treino em andamento, não deixa iniciar', (
    tester,
  ) async {
    await service.start(chart, dayA);

    await openPage(tester, dayB);

    expect(find.byKey(const Key('start_workout_button')), findsNothing);
    expect(find.textContaining('em andamento'), findsOneWidget);
  });
}
