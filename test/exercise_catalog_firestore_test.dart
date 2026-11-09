import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/models/training_chart.dart';

Map<String, dynamic> benchFields() => {
  'name': 'Supino reto',
  'nameEn': 'Bench Press',
  'muscle': 'Peito',
  'primaryMuscle': 'Peitoral maior',
  'highActivationMuscles': ['Tríceps'],
  'secondaryMuscles': <String>[],
};

void main() {
  late FakeFirebaseFirestore firestore;
  late ExerciseCatalogService catalog;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    catalog = ExerciseCatalogService();
    catalog.startForTest(firestore, uid: 'user-a');
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('lê os exercícios usando o id do documento', () async {
    await firestore.doc('exercises/supino-reto').set(benchFields());

    final exercises = await catalog.loadExercises();
    await settle();

    expect(exercises.single.id, 'supino-reto');
    expect(catalog.findById('supino-reto')?.nameEn, 'Bench Press');
    expect(catalog.findById('supino-reto')?.highActivationMuscles, ['Tríceps']);
  });

  test('ordena os exercícios pelo nome', () async {
    await firestore.doc('exercises/b').set({...benchFields(), 'name': 'Remada'});
    await firestore.doc('exercises/a').set({...benchFields(), 'name': 'Agachamento'});
    await settle();

    expect(catalog.exercises.map((e) => e.name), ['Agachamento', 'Remada']);
  });

  test('sem documentos, o catálogo fica vazio e carregado', () async {
    expect(await catalog.loadExercises(), isEmpty);
    await settle();

    expect(catalog.isLoaded, isTrue);
  });

  test('a planilha mostra o nome real quando o catálogo chega depois', () async {
    final charts = TrainingChartService();
    charts.startForTest(firestore, uid: 'user-a');
    catalog.startForTest(firestore, uid: 'user-b');

    await charts.saveChart(
      TrainingChart(
        id: 'c1',
        name: 'Planilha',
        createdAt: DateTime(2026, 11, 1),
        frequencyConfig: const WorkoutFrequencyConfig(
          type: WorkoutFrequencyType.fixedDays,
          fixedWeekdays: [1],
        ),
        days: [
          TrainingDay(
            id: 'd1',
            name: 'TREINO A',
            order: 1,
            exercises: [
              WorkoutExercise(
                exercise: Exercise(id: 'supino-reto', name: 'Provisório'),
              ),
            ],
          ),
        ],
      ),
    );
    await settle();
    await firestore.doc('exercises/supino-reto').set(benchFields());
    await settle();

    expect(charts.charts.single.days.single.exercises.single.name, 'Supino reto');
  });

  test('a lista oficial pode ser lida pelo modelo do app', () {
    final raw = File('tools/exercises.json').readAsStringSync();
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    final exercises = [
      for (final item in list) Exercise.fromMap(item['id'] as String, item),
    ];

    expect(exercises, hasLength(18));
    expect(exercises.map((e) => e.id).toSet(), hasLength(18));
    expect(exercises.every((e) => e.name.isNotEmpty), isTrue);
  });
}
