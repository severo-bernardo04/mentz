import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/training_history/workout_session_detail_page.dart';
import 'package:mentz/models/profile_models.dart';

void main() {
  final session = CompletedWorkout(
    DateTime(2026, 11, 10),
    'TREINO A',
    50,
    chartName: 'Hipertrofia',
    workoutName: 'TREINO A',
    executedExercises: const [
      ExecutedExercise(
        name: 'Supino reto',
        sets: [
          ExecutedSet(
            setNumber: 1,
            type: SetType.warmup,
            loadKg: 20,
            reps: 15,
            minReps: 15,
            maxReps: 20,
          ),
          ExecutedSet(setNumber: 2, loadKg: 40, reps: 7, minReps: 8, maxReps: 10),
        ],
      ),
      ExecutedExercise(
        name: 'Crucifixo',
        completed: false,
        sets: [
          ExecutedSet(
            setNumber: 1,
            loadKg: 0,
            reps: 0,
            completed: false,
            minReps: 10,
            maxReps: 12,
          ),
        ],
      ),
    ],
  );

  Future<void> pumpPage(WidgetTester tester) async {
    // Tela de celular, onde o rótulo do tipo de série quebrava
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: WorkoutSessionDetailPage(session: session)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a faixa e a cor do desempenho de cada série', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Faixa ', findRichText: true), findsNothing);
    expect(find.textContaining('8–10', findRichText: true), findsOneWidget);

    // 7 repetições numa faixa de 8–10: vermelho
    final reps = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == 'Reps 7',
      ),
    );
    // O Text.rich envolve o TextSpan do widget em outro, com o estilo padrão
    final outer = (reps.text as TextSpan).children!.single as TextSpan;
    final value = outer.children!.last as TextSpan;
    expect(value.style?.color, RepsPerformance.below.color);
  });

  testWidgets('séries totais separadas por tipo', (tester) async {
    await pumpPage(tester);

    expect(find.text('Séries totais: 3'), findsOneWidget);
    expect(find.text('Aquecimento'), findsWidgets);
    expect(find.text('Reconhecimento'), findsOneWidget);
    expect(find.text('Trabalho'), findsWidgets);
  });

  testWidgets('treino incompleto lista os pendentes sem COMPLETAR', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.ensureVisible(find.byKey(const Key('incomplete_workout_banner')));
    await tester.tap(find.byKey(const Key('incomplete_workout_banner')));
    await tester.pumpAndSettle();

    expect(find.text('Exercícios pendentes'), findsOneWidget);
    expect(find.text('COMPLETAR'), findsNothing);
  });
}
