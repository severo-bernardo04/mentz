import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/half_step_field.dart';

void main() {
  group('Desempenho na faixa (T14)', () {
    test('abaixo do mínimo é vermelho', () {
      expect(RepsPerformance.of(7, 8, 10), RepsPerformance.below);
      expect(RepsPerformance.below.color, isNotNull);
    });

    test('dentro da faixa e abaixo do máximo fica na cor normal', () {
      expect(RepsPerformance.of(8, 8, 10), RepsPerformance.within);
      expect(RepsPerformance.of(9.5, 8, 10), RepsPerformance.within);
      expect(RepsPerformance.within.color, isNull);
    });

    test('no máximo ou acima é verde', () {
      expect(RepsPerformance.of(10, 8, 10), RepsPerformance.top);
      expect(RepsPerformance.of(13, 8, 10), RepsPerformance.top);
    });

    test('série sem faixa ou ainda não feita não tem cor', () {
      const noRange = ExecutedSet(setNumber: 1, loadKg: 20, reps: 10);
      const notDone = ExecutedSet(
        setNumber: 1,
        loadKg: 20,
        reps: 0,
        minReps: 8,
        maxReps: 10,
      );

      expect(noRange.performance, isNull);
      expect(notDone.performance, isNull);
    });
  });

  group('Registro na sessão (T13)', () {
    final planned = WorkoutExercise(
      exercise: Exercise(id: 'supino', name: 'Supino reto', muscle: 'Peito'),
      plannedSets: const [
        PlannedSet(type: SetType.warmup, minReps: 15, maxReps: 20),
        PlannedSet(minReps: 8, maxReps: 10, isDropSet: true),
      ],
    );

    test('cria uma série vazia para cada série planejada, com a faixa', () {
      final executed = ExecutedExercise.fromPlanned(planned);

      expect(executed.exerciseId, 'supino');
      expect(executed.completed, isFalse);
      expect(executed.sets.map((s) => s.type), [SetType.warmup, SetType.working]);
      expect(executed.sets.map((s) => s.rangeLabel), ['15–20', '8–10']);
      expect(executed.sets.last.dropStages, hasLength(1));
    });

    test('a faixa é salva e lida do Firestore junto com a série', () {
      final set = ExecutedExercise.fromPlanned(planned).sets.last
          .copyWith(loadKg: 40, reps: 9.5);

      final restored = ExecutedSet.fromMap(set.toMap());

      expect(restored.minReps, 8);
      expect(restored.maxReps, 10);
      expect(restored.reps, 9.5);
    });

    test('a carga e as repetições usam passos de 0,5', () {
      expect(HalfStepField.snap(42.3), 42.5);
      expect(HalfStepField.snap(42.2), 42);
      expect(HalfStepField.snap(-3), 0);
      expect(HalfStepField.parse('12,5'), 12.5);
      expect(HalfStepField.parse(''), 0);
      expect(HalfStepField.format(12.5), '12,5');
      expect(HalfStepField.format(0), '');
    });
  });

  group('Resumo da sessão (T15/T16)', () {
    final session = CompletedWorkout(
      DateTime(2026, 11, 10),
      'TREINO A',
      50,
      executedExercises: const [
        ExecutedExercise(
          name: 'Supino',
          sets: [
            ExecutedSet(setNumber: 1, type: SetType.warmup, loadKg: 20, reps: 15),
            ExecutedSet(setNumber: 2, type: SetType.feeder, loadKg: 30, reps: 3),
            ExecutedSet(setNumber: 3, loadKg: 40, reps: 10),
          ],
        ),
        ExecutedExercise(
          name: 'Crucifixo',
          completed: false,
          sets: [ExecutedSet(setNumber: 1, loadKg: 12, reps: 12)],
        ),
      ],
    );

    test('conta as séries de cada tipo', () {
      expect(session.setCountByType, {
        SetType.warmup: 1,
        SetType.feeder: 1,
        SetType.working: 2,
      });
    });

    test('lista os exercícios pendentes', () {
      expect(session.isIncomplete, isTrue);
      expect(session.pendingExercises.map((e) => e.name), ['Crucifixo']);
    });

    test('o rótulo curto usa a letra do treino', () {
      expect(session.shortLabel, 'A');
      expect(CompletedWorkout(DateTime(2026), 'B', 0).shortLabel, 'B');
      expect(CompletedWorkout(DateTime(2026), 'Pernas', 0).shortLabel, 'P');
    });
  });
}
