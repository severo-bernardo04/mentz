import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/workout_session/workout_session_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/training_history_service.dart';
import 'package:mentz/services/workout_schedule_service.dart';
import 'package:mentz/services/workout_session_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutSessionService service;
  late TrainingHistoryService history;
  late DateTime now;

  const userPath = 'users/user-a';
  const sessionsPath = '$userPath/sessions';

  WorkoutExercise exercise(String id, String name) => WorkoutExercise(
        exercise: Exercise(id: id, name: name),
        plannedSets: const [PlannedSet(minReps: 8, maxReps: 10)],
      );

  final dayA = TrainingDay(
    id: 'dA',
    name: 'FULL BODY 1',
    order: 1,
    exercises: [exercise('supino', 'Supino'), exercise('remada', 'Remada')],
  );
  final dayB = TrainingDay(
    id: 'dB',
    name: 'FULL BODY 2',
    order: 2,
    exercises: [exercise('agachamento', 'Agachamento')],
  );
  final chart = TrainingChart(
    id: 'c1',
    name: 'Hipertrofia',
    createdAt: DateTime(2026, 11, 1),
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.fixedDays,
      fixedWeekdays: [1, 3, 5],
    ),
    days: [dayA, dayB],
  );

  /// FULL BODY 1 de segunda (09/11): supino feito, remada pendente.
  final halfDone = CompletedWorkout(
    DateTime(2026, 11, 9, 18),
    'FULL BODY 1',
    30,
    chartId: 'c1',
    dayId: 'dA',
    chartName: 'Hipertrofia',
    workoutName: 'FULL BODY 1',
    executedExercises: const [
      ExecutedExercise(
        exerciseId: 'supino',
        name: 'Supino',
        sets: [
          ExecutedSet(setNumber: 1, loadKg: 40, reps: 9, minReps: 8, maxReps: 10),
        ],
      ),
      ExecutedExercise(
        exerciseId: 'remada',
        name: 'Remada',
        completed: false,
        sets: [
          ExecutedSet(
            setNumber: 1,
            loadKg: 0,
            reps: 0,
            completed: false,
            minReps: 8,
            maxReps: 10,
          ),
        ],
      ),
    ],
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> saveHalfDone() =>
      firestore.collection(sessionsPath).doc('s1').set(halfDone.toMap());

  CompletedWorkout savedSession() =>
      history.sessions.firstWhere((s) => s.id == 's1');

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc(userPath).set({'name': 'Aluno', 'role': 'student'});
    now = DateTime(2026, 11, 11, 18); // quarta
    service = WorkoutSessionService();
    service.startForTest(firestore, uid: 'user-a', clock: () => now);
    history = TrainingHistoryService();
    history.startForTest(firestore, uid: 'user-a');
    await settle();
  });

  tearDown(() {
    service.stopWatching('user-a');
    history.clearForTest();
  });

  group('Completar pendentes de um treino anterior', () {
    test('a sessão incompleta é oferecida para completar', () async {
      await saveHalfDone();
      await settle();

      expect(history.openPendingSession('c1')?.id, 's1');
      expect(history.openPendingSession('outra'), isNull);
    });

    test('o cronômetro mostra só os exercícios pendentes', () async {
      await saveHalfDone();
      await settle();

      await service.startCompletion(savedSession());

      expect(service.active!.isCompletion, isTrue);
      expect(service.active!.exercises.map((e) => e.name), ['Remada']);
      expect(service.active!.exerciseIndexes, [1]);
    });

    test('finalizar devolve os exercícios para a sessão anterior, sem criar outra', () async {
      await saveHalfDone();
      await settle();
      await service.startCompletion(savedSession());

      final remada = service.active!.exercises.single;
      service.updateExercise(
        0,
        remada.copyWith(
          completed: true,
          sets: [remada.sets.single.copyWith(loadKg: 35, reps: 10)],
        ),
      );
      now = now.add(const Duration(minutes: 12));

      final updated = await service.finishCompletion(savedSession());
      await settle();

      final docs = await firestore.collection(sessionsPath).get();
      final saved = CompletedWorkout.fromMap('s1', docs.docs.single.data());

      expect(docs.docs, hasLength(1));
      expect(saved.isIncomplete, isFalse);
      expect(saved.executedExercises[0].sets.single.loadKg, 40);
      expect(saved.executedExercises[1].sets.single.loadKg, 35);
      expect(saved.minutes, 42);
      expect(saved.completedAt, DateTime(2026, 11, 11, 18, 12));
      expect(updated.minutes, 42);
      expect(service.active, isNull);
      expect(history.openPendingSession('c1'), isNull);
    });

    test('completar hoje empurra o próximo treino para a data seguinte', () {
      final completed = halfDone.copyWith(completedAt: now);

      // Sem completar, o FULL BODY 2 seria hoje (quarta)
      final before = WorkoutScheduleService.nextWorkout(
        chart,
        [halfDone],
        now: now,
      )!;
      final after = WorkoutScheduleService.nextWorkout(
        chart,
        [completed],
        now: now,
      )!;

      expect(before.day.name, 'FULL BODY 2');
      expect(before.date, DateTime(2026, 11, 11));
      expect(after.day.name, 'FULL BODY 2');
      expect(after.date, DateTime(2026, 11, 13));
    });

    test('pendentes feitos dentro do treino atual voltam para a sessão anterior', () async {
      await saveHalfDone();
      await settle();
      await service.start(chart, dayB, carryFrom: savedSession());

      final remada = service.active!.carriedExercises.single;
      service.updateExercise(
        0,
        remada.copyWith(
          completed: true,
          sets: [remada.sets.single.copyWith(loadKg: 35, reps: 10)],
        ),
        carried: true,
      );
      now = now.add(const Duration(minutes: 50));

      final session = await service.finish(
        chart,
        dayB,
        carriedOriginal: savedSession(),
      );
      await settle();

      final previous = savedSession();
      final saved = history.sessions.firstWhere((s) => s.id == session.id);

      // A sessão anterior ficou completa, sem somar o tempo deste treino
      expect(previous.isIncomplete, isFalse);
      expect(previous.minutes, 30);
      expect(previous.executedExercises[1].sets.single.loadKg, 35);
      // A sessão nova indica que o tempo também foi usado para isso
      expect(saved.minutes, 50);
      expect(saved.carriedPending?.sessionId, 's1');
      expect(saved.carriedPending?.exerciseNames, ['Remada']);
      expect(saved.carriedPending?.label, 'FULL BODY 1 de 09/11');
    });

    test('pendentes trazidos e não trabalhados ficam como estavam', () async {
      await saveHalfDone();
      await settle();
      await service.start(chart, dayB, carryFrom: savedSession());

      final session = await service.finish(
        chart,
        dayB,
        carriedOriginal: savedSession(),
      );
      await settle();

      expect(session.carriedPending, isNull);
      expect(savedSession().isIncomplete, isTrue);
      expect(savedSession().completedAt, isNull);
      expect(savedSession().canBeCompleted, isTrue);
    });

    test('ignorar tira a sessão da oferta, mas mantém os pendentes', () async {
      await saveHalfDone();
      await settle();

      await history.ignorePending(savedSession());
      await settle();

      expect(history.openPendingSession('c1'), isNull);
      expect(savedSession().isIncomplete, isTrue);
      expect(savedSession().pendingIgnored, isTrue);
    });
  });

  test('a referência é o último treino em que o exercício foi feito', () async {
    await saveHalfDone();
    await settle();

    expect(history.previousSetsFor('supino').single.loadKg, 40);
    // A remada nunca foi feita: não há referência
    expect(history.previousSetsFor('remada'), isEmpty);
    expect(history.previousSetsFor('supino', excludeSessionId: 's1'), isEmpty);
  });

  group('Tela', () {
    Future<void> openPage(WidgetTester tester, TrainingDay day) async {
      await tester.pumpWidget(
        MaterialApp(home: WorkoutSessionPage(chart: chart, day: day)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('"Feito" só marca com carga (ou BW) e repetições', (
      tester,
    ) async {
      await openPage(tester, dayB);
      await tester.tap(find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar'));
      await tester.pumpAndSettle();

      Future<void> tapDone() async {
        await tester.ensureVisible(find.byKey(const Key('exercise_done_0')));
        await tester.tap(find.byKey(const Key('exercise_done_0')));
        await tester.pump();
      }

      bool done() => service.active!.exercises.single.completed;

      // Nada preenchido
      await tapDone();
      expect(done(), isFalse);
      expect(find.textContaining('Preencha carga (ou BW)'), findsOneWidget);

      // Só repetições: ainda falta a carga
      await tester.enterText(find.byKey(const Key('reps_0_1')), '9');
      await tester.pump();
      await tapDone();
      expect(done(), isFalse);

      // Peso do corpo vale como carga
      await tester.ensureVisible(find.byKey(const Key('body_weight_off')));
      await tester.tap(find.byKey(const Key('body_weight_off')));
      await tester.pump();
      expect(service.active!.exercises.single.sets.single.bodyWeight, isTrue);
      await tapDone();
      expect(done(), isTrue);

      // Voltar para carga, sem informar o valor, desmarca o exercício
      await tester.ensureVisible(find.byKey(const Key('body_weight_on')));
      await tester.tap(find.byKey(const Key('body_weight_on')));
      await tester.pump();
      expect(done(), isFalse);

      await tester.enterText(find.byKey(const Key('load_0_1')), '60');
      await tester.pump();
      await tapDone();
      expect(done(), isTrue);

      // Apagar as repetições desmarca o exercício
      await tester.enterText(find.byKey(const Key('reps_0_1')), '');
      await tester.pump();
      expect(service.active!.exercises.single.completed, isFalse);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('os campos mostram carga e repetições do último treino', (
      tester,
    ) async {
      await tester.runAsync(saveHalfDone);
      await tester.pumpAndSettle();
      await tester.runAsync(() => history.ignorePending(savedSession()));
      await tester.pumpAndSettle();

      await openPage(tester, dayA);
      await tester.tap(find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar'));
      await tester.pumpAndSettle();

      final load = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('load_0_1')),
          matching: find.byType(TextField),
        ),
      );
      final reps = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('reps_0_1')),
          matching: find.byType(TextField),
        ),
      );

      expect(load.decoration?.hintText, '40');
      expect(reps.decoration?.hintText, '9');
    });

    testWidgets('INICIAR com pendentes oferece completar o treino anterior', (
      tester,
    ) async {
      await tester.runAsync(saveHalfDone);
      await tester.pumpAndSettle();

      await openPage(tester, dayB);
      expect(find.byKey(const Key('previous_pending_banner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();
      expect(find.text('Treino anterior incompleto'), findsOneWidget);

      await tester.tap(find.byKey(const Key('choice_complete')));
      await tester.pumpAndSettle();

      // Abriu o FULL BODY 1 só com a remada pendente
      expect(service.active!.isCompletion, isTrue);
      expect(find.text('FULL BODY 1'), findsOneWidget);
      expect(find.textContaining('Completando o FULL BODY 1'), findsOneWidget);
      expect(find.text('Remada'), findsOneWidget);
      expect(find.text('Supino'), findsNothing);
    });

    testWidgets('iniciar o atual traz os pendentes do anterior junto', (
      tester,
    ) async {
      await tester.runAsync(saveHalfDone);
      await tester.pumpAndSettle();

      await openPage(tester, dayB);
      await tester.tap(find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choice_start_current')));
      await tester.pumpAndSettle();

      expect(service.active!.isCompletion, isFalse);
      expect(service.active!.carriedExercises.single.name, 'Remada');
      expect(find.text('Pendentes do FULL BODY 1 de 09/11'), findsOneWidget);
      // Agachamento (do treino) e Remada (trazida) pendentes
      expect(find.text('2 exercícios pendentes'), findsOneWidget);
    });

    testWidgets('ignorar pendentes e iniciar conta o treino atual', (
      tester,
    ) async {
      await tester.runAsync(saveHalfDone);
      await tester.pumpAndSettle();

      await openPage(tester, dayB);
      await tester.tap(find.byKey(const Key('start_workout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choice_ignore')));
      await tester.pumpAndSettle();

      expect(service.active!.isCompletion, isFalse);
      expect(service.active!.dayId, 'dB');
      expect(find.byKey(const Key('previous_pending_banner')), findsNothing);
    });
  });
}
