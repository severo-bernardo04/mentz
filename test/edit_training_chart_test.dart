import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/training/controllers/chart_form_controller.dart';
import 'package:mentz/features/training/create_training_chart_page.dart';
import 'package:mentz/features/training/training_charts_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';
import 'package:mentz/services/workout_session_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TrainingChartService service;
  late TrainingChart chart;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  WorkoutExercise planned(String id) => WorkoutExercise(
        exercise: ExerciseCatalogService().findById(id)!,
        plannedSets: PlannedSet.repeat(3, minReps: 8, maxReps: 10),
      );

  setUp(() async {
    ExerciseCatalogService().setExercisesForTest([
      Exercise(id: 'supino', name: 'Supino', muscle: 'Peito'),
      Exercise(id: 'remada', name: 'Remada', muscle: 'Costas'),
    ]);
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/user-a').set({'name': 'Aluno', 'role': 'student'});
    service = TrainingChartService()..startForTest(firestore, uid: 'user-a');
    WorkoutSessionService().startForTest(firestore, uid: 'user-a');

    chart = TrainingChart(
      id: 'c1',
      name: 'Hipertrofia',
      createdAt: DateTime(2026, 10, 1),
      selectedAt: DateTime(2026, 10, 5),
      frequencyConfig: const WorkoutFrequencyConfig(
        type: WorkoutFrequencyType.intervalDays,
        intervalRestDays: [2, 0],
      ),
      days: [
        TrainingDay(
          id: 'dA',
          name: 'PEITO',
          order: 1,
          exercises: [planned('supino')],
        ),
        TrainingDay(
          id: 'dB',
          name: 'COSTAS',
          order: 2,
          exercises: [planned('remada')],
        ),
      ],
    );
    await service.saveChart(chart);
    await settle();
  });

  tearDown(() {
    WorkoutSessionService().stopWatching('user-a');
    service.stopWatching('user-a');
    ExerciseCatalogService().clearForTest();
  });

  group('Formulário em modo de edição', () {
    test('começa preenchido com os dados da planilha', () {
      final form = ChartFormController(editing: chart);
      addTearDown(form.dispose);

      expect(form.isEditing, isTrue);
      expect(form.nameCtrl.text, 'Hipertrofia');
      expect(form.frequencyType, WorkoutFrequencyType.intervalDays);
      expect(form.days.map((d) => d.nameCtrl.text), ['PEITO', 'COSTAS']);
      expect(form.days.map((d) => d.restDaysAfter), [2, 0]);
      expect(form.days.first.exercises.single.name, 'Supino');
    });

    test('mantém os identificadores, a criação e a marcação de atual', () {
      final form = ChartFormController(editing: chart);
      addTearDown(form.dispose);
      form.nameCtrl.text = 'Hipertrofia 2';
      form.days.first.nameCtrl.text = 'PEITO E OMBRO';

      final saved = form.buildChart();

      expect(saved.id, 'c1');
      expect(saved.name, 'Hipertrofia 2');
      expect(saved.createdAt, DateTime(2026, 10, 1));
      expect(saved.selectedAt, DateTime(2026, 10, 5));
      expect(saved.days.map((d) => d.id), ['dA', 'dB']);
      expect(saved.days.first.name, 'PEITO E OMBRO');
    });

    test('dia novo ganha identificador próprio e dia removido sai', () {
      final form = ChartFormController(editing: chart);
      addTearDown(form.dispose);
      form.removeDay(0);
      form.addDay();

      final saved = form.buildChart();

      expect(saved.days, hasLength(2));
      expect(saved.days.first.id, 'dB');
      expect(saved.days.last.id, isNot(anyOf('dA', 'dB')));
      expect(saved.days.map((d) => d.order), [1, 2]);
    });

    test('salvar atualiza a mesma planilha, sem criar outra', () async {
      final form = ChartFormController(editing: chart);
      addTearDown(form.dispose);
      form.nameCtrl.text = 'Renomeada';

      await form.save(service);
      await settle();

      expect(service.charts, hasLength(1));
      expect(service.charts.single.name, 'Renomeada');
      expect(service.currentChart?.id, 'c1');
    });

    test('sem planilha, continua criando uma nova', () {
      final form = ChartFormController();
      addTearDown(form.dispose);

      expect(form.isEditing, isFalse);
      expect(form.days, hasLength(3));
      expect(form.buildChart().id, startsWith('chart-'));
    });
  });

  group('Telas', () {
    testWidgets('o botão de editar abre o formulário preenchido', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingChartsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_chart_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTrainingChartPage), findsOneWidget);
      expect(find.text('Editar Planilha'), findsOneWidget);
      expect(find.text('Hipertrofia'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
    });

    testWidgets('com treino em andamento, a edição é bloqueada', (
      tester,
    ) async {
      await tester.runAsync(
        () => WorkoutSessionService().start(chart, chart.days.first),
      );

      await tester.pumpWidget(const MaterialApp(home: TrainingChartsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_chart_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTrainingChartPage), findsNothing);
      expect(find.textContaining('Finalize o treino em andamento'), findsOneWidget);
    });
  });
}
