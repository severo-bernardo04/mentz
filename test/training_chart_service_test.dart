import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/training/controllers/chart_form_controller.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';

TrainingChart buildChart(String id, {DateTime? createdAt}) {
  final bench = ExerciseCatalogService().findById('supino-reto')!;

  return TrainingChart(
    id: id,
    name: 'Planilha $id',
    createdAt: createdAt ?? DateTime(2026, 11, 1),
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.fixedDays,
      fixedWeekdays: [1, 3, 5],
    ),
    days: [
      TrainingDay(
        id: 'day-1',
        name: 'TREINO A',
        order: 1,
        exercises: [
          WorkoutExercise(
            exercise: bench,
            plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
            restSeconds: 90,
          ),
        ],
      ),
    ],
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late TrainingChartService service;

  setUp(() {
    ExerciseCatalogService().setExercisesForTest([
      Exercise(id: 'supino-reto', name: 'Supino reto', muscle: 'Peito'),
    ]);
    firestore = FakeFirebaseFirestore();
    service = TrainingChartService();
    service.startForTest(firestore, uid: 'user-a');
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('salva a planilha na coleção do usuário', () async {
    await service.saveChart(buildChart('c1'));

    final doc = await firestore
        .collection('users')
        .doc('user-a')
        .collection('charts')
        .doc('c1')
        .get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Planilha c1');
  });

  test('guarda só o exerciseId, sem copiar o catálogo', () async {
    await service.saveChart(buildChart('c1'));

    final doc = await firestore.doc('users/user-a/charts/c1').get();
    final days = doc.data()!['days'] as List;
    final exercise = (days.first as Map)['exercises'].first as Map;

    expect(exercise['exerciseId'], 'supino-reto');
    expect(exercise.containsKey('name'), isFalse);
    expect(exercise.containsKey('exercise'), isFalse);
    expect(exercise['restSeconds'], 90);
  });

  test('recarrega a planilha com os dados do catálogo', () async {
    await service.saveChart(buildChart('c1'));
    await settle();

    final exercise = service.charts.single.days.single.exercises.single;

    expect(exercise.name, 'Supino reto');
    expect(exercise.setsLabel, '4 × 8–10');
    expect(exercise.restSeconds, 90);
  });

  test('mantém a mais recente primeiro', () async {
    await service.saveChart(buildChart('antiga', createdAt: DateTime(2026, 1, 1)));
    await service.saveChart(buildChart('nova', createdAt: DateTime(2026, 6, 1)));
    await settle();

    expect(service.charts.map((c) => c.id), ['nova', 'antiga']);
  });

  test('um usuário não vê as planilhas de outro', () async {
    await service.saveChart(buildChart('c1'));
    await settle();
    expect(service.charts, hasLength(1));

    service.startForTest(firestore, uid: 'user-b');
    await settle();

    expect(service.charts, isEmpty);
  });

  test('remove a planilha', () async {
    await service.saveChart(buildChart('c1'));
    await settle();

    await service.deleteChart('c1');
    await settle();

    expect(service.charts, isEmpty);
  });

  test('parar de acompanhar outro usuário não afeta o atual', () async {
    await service.saveChart(buildChart('c1'));
    await settle();

    service.stopWatching('user-b');

    expect(service.charts, hasLength(1));
  });

  test('exercício fora do catálogo não apaga a planilha', () {
    final chart = TrainingChart.fromMap(
      'c1',
      buildChart('c1').toMap(),
      findExercise: (_) => null,
    );

    expect(chart.days.single.exercises.single.name, 'Exercício indisponível');
  });

  test('não permite passar de 15 dias', () {
    final form = ChartFormController();
    addTearDown(form.dispose);

    while (form.addDay()) {}

    expect(form.days, hasLength(TrainingChart.maxDays));
    expect(form.addDay(), isFalse);
  });
}
