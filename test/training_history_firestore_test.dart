import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';

CompletedWorkout buildSession(String id, DateTime date) {
  return CompletedWorkout(
    date,
    'A',
    60,
    id: id,
    chartName: 'Planilha 1',
    executedExercises: const [
      ExecutedExercise(
        exerciseId: 'supino-reto',
        name: 'Supino reto',
        muscle: 'Peito',
        sets: [
          ExecutedSet(
            setNumber: 1,
            loadKg: 57.5,
            reps: 8.5,
            isDropSet: true,
            dropStages: [DropStage(loadKg: 40, reps: 6)],
          ),
        ],
      ),
    ],
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late TrainingHistoryService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = TrainingHistoryService();
    service.startForTest(firestore, uid: 'user-a');
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('salva a sessão na coleção do usuário', () async {
    await service.addSession(buildSession('s1', DateTime(2026, 11, 1)));

    final doc = await firestore.doc('users/user-a/sessions/s1').get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['plan'], 'A');
    expect(doc.data()!.containsKey('id'), isFalse);
  });

  test('recarrega a sessão com exercícios, séries e etapas', () async {
    await service.addSession(buildSession('s1', DateTime(2026, 11, 1)));
    final loaded = await service.loadSessions();
    await settle();

    final session = service.sessions.single;
    final exercise = session.executedExercises.single;

    expect(loaded, hasLength(1));
    expect(session.id, 's1');
    expect(session.date, DateTime(2026, 11, 1));
    expect(exercise.exerciseId, 'supino-reto');
    expect(exercise.name, 'Supino reto');
    expect(exercise.sets.single.loadLabel, '57.5 kg / 40 kg');
    expect(exercise.sets.single.repsLabel, '8.5 + 6');
  });

  test('sem treinos, o histórico fica vazio e sem dados de exemplo', () async {
    expect(await service.loadSessions(), isEmpty);
  });

  test('ordena da sessão mais recente para a mais antiga', () async {
    await service.addSession(buildSession('antiga', DateTime(2026, 1, 1)));
    await service.addSession(buildSession('nova', DateTime(2026, 6, 1)));
    await settle();

    expect(service.sessions.map((s) => s.id), ['nova', 'antiga']);
  });

  test('um usuário não vê o histórico de outro', () async {
    await service.addSession(buildSession('s1', DateTime(2026, 11, 1)));
    await settle();

    service.startForTest(firestore, uid: 'user-b');

    expect(await service.loadSessions(), isEmpty);
  });

  test('cria um identificador quando a sessão ainda não tem', () async {
    await service.addSession(CompletedWorkout(DateTime(2026, 11, 1), 'B', 40));
    await settle();

    expect(service.sessions.single.id, isNotEmpty);
  });
}
