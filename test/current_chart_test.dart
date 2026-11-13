import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/home/widgets/current_training_chart.dart';
import 'package:mentz/features/training/training_charts_page.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/training_chart_service.dart';

TrainingChart buildChart(String id, String name, DateTime createdAt) {
  return TrainingChart(
    id: id,
    name: name,
    createdAt: createdAt,
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.fixedDays,
      fixedWeekdays: [1, 3, 5],
    ),
    days: const [TrainingDay(id: 'd1', name: 'TREINO A', order: 1)],
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late TrainingChartService service;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    ExerciseCatalogService().setExercisesForTest([]);
    firestore = FakeFirebaseFirestore();
    service = TrainingChartService();
    service.startForTest(firestore, uid: 'user-a');
  });

  tearDown(() {
    service.stopWatching('user-a');
    ExerciseCatalogService().clearForTest();
  });

  /// Salva a planilha antiga e a nova, nessa ordem de criação.
  Future<void> saveTwoCharts() async {
    await service.saveChart(buildChart('old', 'Antiga', DateTime(2026, 10, 1)));
    await service.saveChart(buildChart('new', 'Nova', DateTime(2026, 11, 1)));
    await settle();
  }

  group('Planilha atual', () {
    test('sem planilhas, não há planilha atual', () async {
      await settle();

      expect(service.currentChart, isNull);
    });

    test('sem marcação, vale a planilha mais recente', () async {
      await saveTwoCharts();

      expect(service.currentChart?.id, 'new');
    });

    test('a planilha escolhida no menu passa a ser a atual', () async {
      await saveTwoCharts();

      await service.selectChart('old');
      await settle();

      expect(service.currentChart?.id, 'old');
    });

    test('vale a escolha mais recente', () async {
      await saveTwoCharts();

      await service.selectChart('old');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.selectChart('new');
      await settle();

      expect(service.currentChart?.id, 'new');
    });

    test('escolher a atual não altera o restante da planilha', () async {
      await saveTwoCharts();

      await service.selectChart('old');
      await settle();

      final data = (await firestore.doc('users/user-a/charts/old').get()).data()!;
      expect(data['name'], 'Antiga');
      expect((data['days'] as List), hasLength(1));
    });

    test('se a planilha atual for removida, volta a valer a mais recente', () async {
      await saveTwoCharts();
      await service.selectChart('old');
      await settle();

      await service.deleteChart('old');
      await settle();

      expect(service.currentChart?.id, 'new');
    });
  });

  group('Telas', () {
    testWidgets('a tela inicial mostra só a planilha atual', (tester) async {
      await tester.runAsync(saveTwoCharts);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CurrentTrainingChart()),
          ),
        ),
      );
      // Espera o atraso da animação de entrada do cartão
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Antiga'), findsNothing);
    });

    testWidgets('o menu lista todas, destaca a atual e troca a atual', (
      tester,
    ) async {
      await tester.runAsync(saveTwoCharts);

      await tester.pumpWidget(const MaterialApp(home: TrainingChartsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Antiga'), findsOneWidget);
      // Só a atual tem a etiqueta, e só a outra tem o botão de escolher
      expect(
        find.descendant(
          of: find.byKey(const Key('chart_card_new')),
          matching: find.text('Atual'),
        ),
        findsOneWidget,
      );
      expect(find.text('Definir como atual'), findsOneWidget);

      await tester.tap(find.text('Definir como atual'));
      await tester.runAsync(settle);
      await tester.pumpAndSettle();

      expect(service.currentChart?.id, 'old');
      expect(
        find.descendant(
          of: find.byKey(const Key('chart_card_old')),
          matching: find.text('Atual'),
        ),
        findsOneWidget,
      );
    });
  });
}
