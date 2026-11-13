import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/workout_schedule_service.dart';

/// Datas de referência (novembro de 2026).
final monday = DateTime(2026, 11, 9);
final tuesday = DateTime(2026, 11, 10);
final wednesday = DateTime(2026, 11, 11);
final thursday = DateTime(2026, 11, 12);
final friday = DateTime(2026, 11, 13);
final nextMonday = DateTime(2026, 11, 16);

TrainingChart chart({
  int days = 4,
  WorkoutFrequencyConfig frequency = const WorkoutFrequencyConfig(
    type: WorkoutFrequencyType.fixedDays,
    fixedWeekdays: [1, 3, 5],
  ),
}) {
  return TrainingChart(
    id: 'c1',
    name: 'Planilha',
    createdAt: DateTime(2026, 11, 1),
    frequencyConfig: frequency,
    days: [
      for (var i = 0; i < days; i++)
        TrainingDay(
          id: 'd$i',
          name: 'TREINO ${String.fromCharCode(65 + i)}',
          order: i + 1,
        ),
    ],
  );
}

CompletedWorkout session(String dayId, DateTime date, {String chartId = 'c1'}) =>
    CompletedWorkout(date, dayId, 60, chartId: chartId, dayId: dayId);

void main() {
  NextWorkout next(
    TrainingChart c,
    List<CompletedWorkout> sessions,
    DateTime now,
  ) => WorkoutScheduleService.nextWorkout(c, sessions, now: now)!;

  group('Dias fixos', () {
    test('sem treinos, começa pelo primeiro no próximo dia marcado', () {
      final result = next(chart(), [], tuesday);

      expect(result.day.name, 'TREINO A');
      expect(result.date, wednesday);
    });

    test('hoje sendo dia marcado e sem treino feito, o treino é hoje', () {
      expect(next(chart(), [], monday).date, monday);
    });

    test('o 4º treino cai no primeiro dia marcado da semana seguinte', () {
      final sessions = [
        session('d0', monday),
        session('d1', wednesday),
        session('d2', friday),
      ];

      final result = next(chart(), sessions, friday);

      expect(result.day.name, 'TREINO D');
      expect(result.date, nextMonday);
    });

    test('depois do último treino do ciclo, volta ao primeiro', () {
      final result = next(chart(), [session('d3', monday)], monday);

      expect(result.day.name, 'TREINO A');
      expect(result.date, wednesday);
    });

    test('ao faltar, o treino passa para o próximo dia marcado', () {
      // Fez A na segunda e faltou na quarta: B vai para sexta
      final result = next(chart(), [session('d0', monday)], thursday);

      expect(result.day.name, 'TREINO B');
      expect(result.date, friday);
    });

    test('quem já treinou hoje só treina de novo no próximo dia marcado', () {
      final result = next(chart(), [session('d0', monday)], monday);

      expect(result.date, wednesday);
    });

    test('sem dias marcados, mostra o treino sem data', () {
      final noDays = chart(
        frequency: const WorkoutFrequencyConfig(
          type: WorkoutFrequencyType.fixedDays,
        ),
      );

      expect(next(noDays, [], monday).date, isNull);
    });
  });

  group('Intervalos', () {
    final interval = chart(
      days: 3,
      frequency: const WorkoutFrequencyConfig(
        type: WorkoutFrequencyType.intervalDays,
        intervalRestDays: [1, 0, 2],
      ),
    );

    test('sem treinos, o primeiro é hoje', () {
      expect(next(interval, [], tuesday).date, tuesday);
    });

    test('respeita o descanso definido depois do último treino', () {
      // A tem 1 dia de descanso: feito na segunda, B fica para quarta
      final result = next(interval, [session('d0', monday)], monday);

      expect(result.day.name, 'TREINO B');
      expect(result.date, wednesday);
    });

    test('sem descanso, o próximo é no dia seguinte', () {
      final result = next(interval, [session('d1', monday)], monday);

      expect(result.day.name, 'TREINO C');
      expect(result.date, tuesday);
    });

    test('com atraso, o próximo é hoje e nenhum treino é pulado', () {
      final result = next(interval, [session('d0', monday)], friday);

      expect(result.day.name, 'TREINO B');
      expect(result.date, friday);
    });
  });

  test('ignora treinos de outras planilhas', () {
    final result = next(chart(), [session('d2', monday, chartId: 'outra')], monday);

    expect(result.day.name, 'TREINO A');
  });

  test('se o dia do último treino saiu da planilha, recomeça pelo primeiro', () {
    final result = next(chart(), [session('removido', monday)], monday);

    expect(result.day.name, 'TREINO A');
  });

  test('o texto mostra hoje, amanhã ou a data', () {
    final today = NextWorkout(chart().days.first, tuesday);
    final tomorrow = NextWorkout(chart().days.first, wednesday);
    final later = NextWorkout(chart().days.first, friday);

    expect(WorkoutScheduleService.label(today, now: tuesday), 'TREINO A • hoje');
    expect(WorkoutScheduleService.label(tomorrow, now: tuesday), 'TREINO A • amanhã');
    expect(WorkoutScheduleService.label(later, now: tuesday), 'TREINO A • sex, 13/11');
  });

  test('a sessão guarda a planilha e o dia do treino', () {
    final restored = CompletedWorkout.fromMap(
      's1',
      session('d1', monday).toMap(),
    );

    expect(restored.chartId, 'c1');
    expect(restored.dayId, 'd1');
  });
}
