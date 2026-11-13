import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/home/widgets/training_chart_card.dart';
import 'package:mentz/features/workout_session/workout_session_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/muscle_analysis_service.dart';
import 'package:mentz/services/training_history_service.dart';

void main() {
  final bench = Exercise(
    id: 'supino',
    name: 'Supino reto',
    muscle: 'Peito',
    primaryMuscle: 'Peitoral maior',
    highActivationMuscles: ['Tríceps', 'Deltoide anterior'],
    secondaryMuscles: ['Serrátil anterior', 'Core'],
  );
  final dips = Exercise(
    id: 'paralelas',
    name: 'Paralelas',
    muscle: 'Tríceps',
    primaryMuscle: 'Tríceps',
    highActivationMuscles: ['Peitoral maior'],
    secondaryMuscles: ['Deltoide anterior'],
  );

  final dayA = TrainingDay(
    id: 'dA',
    name: 'TREINO A',
    order: 1,
    exercises: [
      WorkoutExercise(
        exercise: bench,
        plannedSets: const [
          PlannedSet(type: SetType.warmup, minReps: 15, maxReps: 20),
          PlannedSet(type: SetType.feeder, minReps: 3, maxReps: 3),
          PlannedSet(minReps: 8, maxReps: 10),
          PlannedSet(minReps: 8, maxReps: 10, isDropSet: true),
        ],
      ),
      WorkoutExercise(
        exercise: dips,
        plannedSets: const [
          PlannedSet(type: SetType.warmup, minReps: 12, maxReps: 15, isDropSet: true),
          PlannedSet(minReps: 8, maxReps: 12),
        ],
      ),
    ],
  );
  final dayB = TrainingDay(
    id: 'dB',
    name: 'TREINO B',
    order: 2,
    exercises: [
      WorkoutExercise(
        exercise: bench,
        plannedSets: PlannedSet.repeat(3, minReps: 8, maxReps: 10),
      ),
    ],
  );
  final chart = TrainingChart(
    id: 'c1',
    name: 'Hipertrofia',
    createdAt: DateTime(2026, 11, 1),
    frequencyConfig: const WorkoutFrequencyConfig(
      type: WorkoutFrequencyType.intervalDays,
      intervalRestDays: [1, 1],
    ),
    days: [dayA, dayB],
  );

  group('Contagem de séries por tipo', () {
    test('conta as séries de cada tipo no dia', () {
      expect(MuscleAnalysisService.daySetCounts(dayA), {
        SetType.warmup: 2,
        SetType.feeder: 1,
        SetType.working: 3,
      });
    });

    test('a série com drop set conta no tipo que ela acompanha', () {
      final day = TrainingDay(
        id: 'd',
        name: 'D',
        order: 1,
        exercises: [
          WorkoutExercise(
            exercise: bench,
            plannedSets: const [
              PlannedSet(minReps: 8, maxReps: 10, isDropSet: true),
              PlannedSet(type: SetType.warmup, minReps: 8, maxReps: 10, isDropSet: true),
            ],
          ),
        ],
      );

      expect(MuscleAnalysisService.daySetCounts(day), {
        SetType.warmup: 1,
        SetType.feeder: 0,
        SetType.working: 1,
      });
    });

    test('a planilha soma as séries de todos os dias', () {
      expect(MuscleAnalysisService.chartSetCounts(chart), {
        SetType.warmup: 2,
        SetType.feeder: 1,
        SetType.working: 6,
      });
    });
  });

  group('Pontuação muscular', () {
    test('principal vale 3, alta ativação 2 e secundário 1', () {
      final points = {
        for (final c in MuscleAnalysisService.contributionsOf(bench))
          c.muscle: c.points,
      };

      expect(points, {
        'Peitoral maior': 3,
        'Tríceps': 2,
        'Deltoide anterior': 2,
        'Serrátil anterior': 1,
        'Core': 1,
      });
    });

    test('sem músculo principal detalhado, usa o músculo geral', () {
      final simple = Exercise(id: 'x', name: 'Rosca', muscle: 'Bíceps');

      final only = MuscleAnalysisService.contributionsOf(simple).single;

      expect(only.muscle, 'Bíceps');
      expect(only.role, MuscleRole.primary);
    });

    test('junta os músculos no grupamento certo', () {
      expect(MuscleAnalysisService.groupOf('Peitoral superior'), 'Peito');
      expect(MuscleAnalysisService.groupOf('Grande dorsal'), 'Costas');
      expect(MuscleAnalysisService.groupOf('Romboides'), 'Costas');
      expect(MuscleAnalysisService.groupOf('Lombar'), 'Costas');
      expect(MuscleAnalysisService.groupOf('Trapézio'), 'Trapézio');
      expect(MuscleAnalysisService.groupOf('Deltoide posterior'), 'Ombros');
      expect(MuscleAnalysisService.groupOf('Isquiotibiais'), 'Posterior de coxa');
      expect(MuscleAnalysisService.groupOf('Braquiorradial'), 'Antebraço');
      expect(MuscleAnalysisService.groupOf('Braquial'), 'Bíceps');
      expect(MuscleAnalysisService.groupOf('Bíceps (cabeça curta)'), 'Bíceps');
      expect(MuscleAnalysisService.groupOf('Músculo novo'), 'Músculo novo');
    });

    test('soma por grupamento, em ordem decrescente', () {
      final scores = MuscleAnalysisService.dayScores(dayA);

      // Peito: supino 3 + serrátil 1 + paralelas 2 = 6
      // Tríceps: supino 2 + paralelas 3 = 5
      // Ombros: supino 2 + paralelas 1 = 3
      // Abdômen: core do supino = 1
      expect(
        [for (final s in scores) '${s.group} ${s.points}'],
        ['Peito 6', 'Tríceps 5', 'Ombros 3', 'Abdômen 1'],
      );
    });

    test('a planilha soma a pontuação de todos os dias', () {
      final scores = MuscleAnalysisService.chartScores(chart);

      // TREINO A (Peito 6, Tríceps 5, Ombros 3, Abdômen 1) + supino do
      // TREINO B (Peito 4, Tríceps 2, Ombros 2, Abdômen 1)
      expect(
        [for (final s in scores) '${s.group} ${s.points}'],
        ['Peito 10', 'Tríceps 7', 'Ombros 5', 'Abdômen 2'],
      );
      expect(scores.first.contributions.last.dayName, 'TREINO B');
    });

    test('cada grupamento guarda os exercícios que o compõem', () {
      final chest = MuscleAnalysisService.dayScores(dayA).first;

      expect(
        [for (final c in chest.contributions) '${c.exerciseName}: ${c.muscle}'],
        [
          'Supino reto: Peitoral maior',
          'Supino reto: Serrátil anterior',
          'Paralelas: Peitoral maior',
        ],
      );
    });
  });

  group('Telas', () {
    setUp(() => TrainingHistoryService().setSessionsForTest([]));
    tearDown(TrainingHistoryService().clearForTest);

    testWidgets('a tela do treino mostra as séries e a pontuação do dia', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: WorkoutSessionPage(chart: chart, day: dayA)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Séries do treino'), findsOneWidget);
      expect(find.text('Pontuação muscular'), findsOneWidget);

      // Tocar em um grupamento lista os exercícios que o compõem
      final chest = find.byKey(const Key('muscle_score_Peito'));
      await tester.ensureVisible(chest);
      await tester.tap(chest);
      await tester.pumpAndSettle();

      expect(find.text('Peito  •  6 pontos'), findsOneWidget);
      expect(find.text('Peitoral maior  •  Principal'), findsOneWidget);
      expect(find.text('Peitoral maior  •  Alta ativação'), findsOneWidget);
      expect(find.text('Serrátil anterior  •  Secundário'), findsOneWidget);
    });

    testWidgets('o cartão da planilha mostra os totais da planilha inteira', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TrainingChartCard.fromChart(context, chart),
            ),
          ),
        ),
      );

      expect(find.text('2 Aquecimento', findRichText: true), findsOneWidget);
      expect(find.text('1 Reconhecimento', findRichText: true), findsOneWidget);
      expect(find.text('6 Trabalho', findRichText: true), findsOneWidget);
    });

    testWidgets('o botão do cartão abre a pontuação total da planilha', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TrainingChartCard.fromChart(context, chart),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('chart_muscle_score_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Hipertrofia  •  soma de todos os treinos do ciclo'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('muscle_score_Peito')), findsOneWidget);

      // O detalhe do grupamento mostra de qual dia vem cada exercício
      await tester.tap(find.byKey(const Key('muscle_score_Peito')));
      await tester.pumpAndSettle();

      expect(find.text('Peito  •  10 pontos'), findsOneWidget);
      expect(
        find.text('TREINO B  •  Peitoral maior  •  Principal'),
        findsOneWidget,
      );
    });
  });
}
