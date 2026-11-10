import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/workout_session_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutSessionService service;
  late DateTime now;

  const userPath = 'users/user-a';

  final dayA = const TrainingDay(id: 'd0', name: 'TREINO A', order: 1);
  final dayB = const TrainingDay(id: 'd1', name: 'TREINO B', order: 2);
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

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc(userPath).set({'name': 'Aluno', 'role': 'student'});
    now = DateTime(2026, 11, 10, 14, 0);
    service = WorkoutSessionService();
    service.startForTest(firestore, uid: 'user-a', clock: () => now);
    await settle();
  });

  tearDown(() => service.stopWatching('user-a'));

  test('iniciar registra o início no perfil do usuário', () async {
    await service.start(chart, dayA);

    final data = (await firestore.doc(userPath).get()).data()!;
    final active = data['activeSession'] as Map<String, dynamic>;

    expect(active['chartId'], 'c1');
    expect(active['dayId'], 'd0');
    expect(service.active!.startedAt, DateTime(2026, 11, 10, 14, 0));
  });

  test('o tempo é calculado pelo horário de início', () async {
    await service.start(chart, dayA);

    now = now.add(const Duration(minutes: 3, seconds: 20));

    expect(service.elapsed, const Duration(minutes: 3, seconds: 20));
  });

  test('não inicia um segundo treino com outro em andamento', () async {
    await service.start(chart, dayA);

    expect(() => service.start(chart, dayB), throwsStateError);
  });

  test('finalizar salva a sessão e encerra o treino em andamento', () async {
    await service.start(chart, dayA);
    now = now.add(const Duration(minutes: 52, seconds: 40));

    final session = await service.finish(chart, dayA);

    final saved = await firestore
        .collection('$userPath/sessions')
        .doc(session.id)
        .get();
    final user = (await firestore.doc(userPath).get()).data()!;

    expect(saved.data()!['minutes'], 53);
    expect(saved.data()!['chartId'], 'c1');
    expect(saved.data()!['dayId'], 'd0');
    expect(saved.data()!['plan'], 'TREINO A');
    expect(saved.data()!['chartName'], 'Hipertrofia');
    expect(user.containsKey('activeSession'), isFalse);
    expect(service.active, isNull);
  });

  test('não finaliza um treino que não está em andamento', () async {
    await service.start(chart, dayA);

    expect(() => service.finish(chart, dayB), throwsStateError);
  });

  test('descartar encerra o treino sem salvar no histórico', () async {
    await service.start(chart, dayA);

    await service.discard();

    final sessions = await firestore.collection('$userPath/sessions').get();
    final user = (await firestore.doc(userPath).get()).data()!;

    expect(sessions.docs, isEmpty);
    expect(user.containsKey('activeSession'), isFalse);
    expect(service.active, isNull);
  });

  test('recupera o treino em andamento ao abrir o app de novo', () async {
    await service.start(chart, dayA);

    // Simula o app sendo aberto de novo (ou em outro aparelho) mais tarde
    service.stopWatching('user-a');
    await settle();
    now = now.add(const Duration(minutes: 30));
    service.startForTest(firestore, uid: 'user-a', clock: () => now);
    await settle();

    expect(service.active!.isFor('c1', 'd0'), isTrue);
    expect(service.elapsed, const Duration(minutes: 30));
  });

  test('sair da conta limpa o treino da memória', () async {
    await service.start(chart, dayA);

    service.stopWatching('user-a');

    expect(service.active, isNull);
    expect(service.elapsed, Duration.zero);
  });

  group('Registro de carga e repetições', () {
    final squat = WorkoutExercise(
      exercise: Exercise(id: 'agachamento', name: 'Agachamento', muscle: 'Pernas'),
      plannedSets: const [
        PlannedSet(minReps: 8, maxReps: 10),
        PlannedSet(minReps: 8, maxReps: 10),
      ],
    );
    final legDay = TrainingDay(
      id: 'd2',
      name: 'TREINO C',
      order: 3,
      exercises: [squat],
    );
    final legChart = TrainingChart(
      id: 'c2',
      name: 'Pernas',
      createdAt: DateTime(2026, 11, 1),
      frequencyConfig: const WorkoutFrequencyConfig(
        type: WorkoutFrequencyType.intervalDays,
        intervalRestDays: [1],
      ),
      days: [legDay],
    );

    /// Agachamento com a primeira série feita (100 kg x 9).
    ExecutedExercise firstSetDone() {
      final exercise = service.active!.exercises.single;
      return exercise.copyWith(
        sets: [
          exercise.sets[0].copyWith(loadKg: 100, reps: 9),
          exercise.sets[1],
        ],
      );
    }

    test('iniciar já prepara as séries planejadas, vazias', () async {
      await service.start(legChart, legDay);

      final sets = service.active!.exercises.single.sets;

      expect(sets, hasLength(2));
      expect(sets.every((s) => s.reps == 0 && s.minReps == 8), isTrue);
    });

    test('as séries digitadas ficam salvas no treino em andamento', () async {
      await service.start(legChart, legDay);

      service.updateExercise(0, firstSetDone());
      service.flushForTest();
      await settle();

      final data = (await firestore.doc(userPath).get()).data()!;
      final sets = (data['activeSession']['exercises'] as List).single['sets']
          as List;

      expect(sets.first['loadKg'], 100);
      expect(sets.first['reps'], 9);
    });

    test('o que foi digitado não é desfeito pela resposta do servidor', () async {
      await service.start(legChart, legDay);
      await settle();

      // Digitação ainda não gravada e o servidor reenvia a versão antiga
      service.updateExercise(0, firstSetDone());
      await firestore.doc(userPath).update({'name': 'Aluno 2'});
      await settle();

      expect(service.active!.exercises.single.sets.first.reps, 9);
    });

    test('finalizar salva as séries e o exercício marcado como feito', () async {
      await service.start(legChart, legDay);
      service.updateExercise(0, firstSetDone().copyWith(completed: true));

      final session = await service.finish(legChart, legDay);

      final saved = CompletedWorkout.fromMap(
        session.id!,
        (await firestore.collection('$userPath/sessions').doc(session.id).get())
            .data()!,
      );
      final sets = saved.executedExercises.single.sets;

      expect(saved.executedExercises.single.completed, isTrue);
      expect(sets.first.loadKg, 100);
      expect(sets.first.completed, isTrue);
      // Série sem repetições informadas não conta como feita
      expect(sets.last.completed, isFalse);
      expect(sets.first.rangeLabel, '8–10');
    });
  });
}
