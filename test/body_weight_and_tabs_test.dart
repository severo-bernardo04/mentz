import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/core/utils/text_fit.dart';
import 'package:mentz/features/training_history/workout_spreadsheet_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';

void main() {
  group('Peso do corpo (BW)', () {
    test('a série precisa de carga ou BW, além das repetições', () {
      const empty = ExecutedSet(setNumber: 1, loadKg: 0, reps: 0);

      expect(empty.copyWith(reps: 10).isFilled, isFalse);
      expect(empty.copyWith(reps: 10, loadKg: 20).isFilled, isTrue);
      expect(empty.copyWith(reps: 10, bodyWeight: true).isFilled, isTrue);
      expect(empty.copyWith(bodyWeight: true).isFilled, isFalse);
    });

    test('etapas do drop set também precisam de carga', () {
      const set = ExecutedSet(
        setNumber: 1,
        loadKg: 40,
        reps: 10,
        isDropSet: true,
        dropStages: [DropStage(loadKg: 0, reps: 6)],
      );

      expect(set.isFilled, isFalse);
      expect(
        set.copyWith(dropStages: const [DropStage(loadKg: 30, reps: 6)]).isFilled,
        isTrue,
      );
    });

    test('aparece como BW e é salvo no Firestore', () {
      const set = ExecutedSet(setNumber: 1, loadKg: 0, reps: 12, bodyWeight: true);

      expect(set.loadLabel, 'BW');
      expect(ExecutedSet.fromMap(set.toMap()).bodyWeight, isTrue);
      expect(const ExecutedSet(setNumber: 1, loadKg: 20, reps: 8).toMap(),
          isNot(contains('bodyWeight')));
    });
  });

  group('Fonte das abas', () {
    const style = TextStyle(fontWeight: FontWeight.w800, height: 1.15);

    test('nomes curtos usam a fonte máxima', () {
      expect(fitFontSize(['A', 'B'], maxWidth: 120, style: style), 16);
    });

    test('nomes longos diminuem a fonte, até o limite', () {
      final size = fitFontSize(
        ['FULL BODY 1', 'SUPERIORES COMPLETO'],
        maxWidth: 70,
        style: style,
      );

      expect(size, lessThan(16));
      expect(size, greaterThanOrEqualTo(11));
    });

    test('nunca fica abaixo do mínimo', () {
      expect(
        fitFontSize(['PALAVRAEXTREMAMENTELONGA'], maxWidth: 30, style: style),
        11,
      );
    });
  });

  testWidgets('abas com nomes longos: mesma fonte em todas e sem estourar', (
    tester,
  ) async {
    // Tela de celular
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final service = TrainingHistoryService()
      ..setSessionsForTest([
        for (final name in [
          'FULL BODY 1',
          'FULL BODY 2',
          'SUPERIORES COMPLETO',
          'INFERIORES',
        ])
          CompletedWorkout(DateTime(2026, 11, 10), name, 50),
      ]);
    addTearDown(service.clearForTest);

    await tester.pumpWidget(
      MaterialApp(home: WorkoutSpreadsheetPage(service: service)),
    );
    await tester.pumpAndSettle();

    final labels = tester.widgetList<Text>(
      find.descendant(of: find.byType(Tab), matching: find.byType(Text)),
    );
    final sizes = {for (final label in labels) label.style?.fontSize};

    expect(labels, hasLength(4));
    expect(sizes, hasLength(1));
    expect(sizes.single, inInclusiveRange(11, 16));
    expect(labels.every((label) => label.maxLines == 2), isTrue);
    expect(tester.takeException(), isNull);
  });
}
