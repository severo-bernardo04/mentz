import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/core/utils/duration_format.dart';
import 'package:mentz/models/active_workout.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/workout_session_service.dart';

void main() {
  group('ActiveWorkout (pausa)', () {
    final start = DateTime(2026, 11, 10, 14);
    final workout = ActiveWorkout(chartId: 'c1', dayId: 'd0', startedAt: start);

    test('sem pausa, o tempo é agora menos o início', () {
      expect(
        workout.elapsedAt(start.add(const Duration(minutes: 7))),
        const Duration(minutes: 7),
      );
    });

    test('pausado, o tempo fica congelado', () {
      final paused = workout.paused(start.add(const Duration(minutes: 5)));

      expect(
        paused.elapsedAt(start.add(const Duration(hours: 3))),
        const Duration(minutes: 5),
      );
    });

    test('retomar não conta o tempo parado', () {
      final resumed = workout
          .paused(start.add(const Duration(minutes: 5)))
          .resumed(start.add(const Duration(minutes: 15)));

      expect(resumed.isPaused, isFalse);
      expect(resumed.pausedDuration, const Duration(minutes: 10));
      expect(
        resumed.elapsedAt(start.add(const Duration(minutes: 20))),
        const Duration(minutes: 10),
      );
    });

    test('a pausa sobrevive a toMap/tryFromMap', () {
      final paused = workout
          .paused(start.add(const Duration(minutes: 5)))
          .resumed(start.add(const Duration(minutes: 8)))
          .paused(start.add(const Duration(minutes: 20)));

      final restored = ActiveWorkout.tryFromMap(paused.toMap())!;

      expect(restored.pausedAt, start.add(const Duration(minutes: 20)));
      expect(restored.pausedDuration, const Duration(minutes: 3));
      expect(
        restored.elapsedAt(start.add(const Duration(hours: 1))),
        const Duration(minutes: 17),
      );
    });

    test('um treino salvo sem os campos de pausa continua válido', () {
      final restored = ActiveWorkout.tryFromMap({
        'chartId': 'c1',
        'dayId': 'd0',
        'startedAt': Timestamp.fromDate(start),
      })!;

      expect(restored.isPaused, isFalse);
      expect(restored.pausedDuration, Duration.zero);
    });

    test('copyWith preserva a pausa', () {
      final paused = workout.paused(start.add(const Duration(minutes: 5)));

      expect(paused.copyWith(exercises: const []).isPaused, isTrue);
    });
  });

  test('formatStopwatchHms mostra sempre HH:MM:SS', () {
    expect(formatStopwatchHms(Duration.zero), '00:00:00');
    expect(formatStopwatchHms(const Duration(minutes: 5, seconds: 7)), '00:05:07');
    expect(formatStopwatchHms(const Duration(hours: 1, minutes: 2, seconds: 3)), '01:02:03');
  });

  group('WorkoutSessionService (pausa)', () {
    late FakeFirebaseFirestore firestore;
    late WorkoutSessionService service;
    late DateTime now;

    const day = TrainingDay(id: 'd0', name: 'TREINO A', order: 1);
    final chart = TrainingChart(
      id: 'c1',
      name: 'Hipertrofia',
      createdAt: DateTime(2026, 11, 1),
      frequencyConfig: const WorkoutFrequencyConfig(
        type: WorkoutFrequencyType.fixedDays,
        fixedWeekdays: [1, 3, 5],
      ),
      days: const [day],
    );

    Future<void> settle() => Future<void>.delayed(Duration.zero);
    Future<Map<String, dynamic>> stored() async =>
        ((await firestore.doc('users/user-a').get()).data()!['activeSession']
        as Map<String, dynamic>);

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await firestore.doc('users/user-a').set({'name': 'Aluno', 'role': 'student'});
      now = DateTime(2026, 11, 10, 14);
      service = WorkoutSessionService()
        ..startForTest(firestore, uid: 'user-a', clock: () => now);
      await settle();
    });

    tearDown(() => service.stopWatching('user-a'));

    test('pausar congela o tempo e grava o horário da pausa', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 10));

      await service.pause();
      now = now.add(const Duration(minutes: 30));

      expect(service.isPaused, isTrue);
      expect(service.elapsed, const Duration(minutes: 10));
      expect((await stored()).containsKey('pausedAt'), isTrue);
    });

    test('retomar continua do tempo em que parou', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 10));
      await service.pause();
      now = now.add(const Duration(minutes: 30));

      await service.resume();
      now = now.add(const Duration(minutes: 5));

      expect(service.isPaused, isFalse);
      expect(service.elapsed, const Duration(minutes: 15));
      expect((await stored())['pausedMs'], const Duration(minutes: 30).inMilliseconds);
    });

    test('a pausa é recuperada ao abrir o app de novo', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 10));
      await service.pause();

      service.stopWatching('user-a');
      await settle();
      now = now.add(const Duration(hours: 2));
      service.startForTest(firestore, uid: 'user-a', clock: () => now);
      await settle();

      expect(service.isPaused, isTrue);
      expect(service.elapsed, const Duration(minutes: 10));
    });

    test('finalizar não conta o tempo pausado', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 20));
      await service.pause();
      now = now.add(const Duration(minutes: 40));
      await service.resume();
      now = now.add(const Duration(minutes: 10));

      final session = await service.finish(chart, day);

      expect(session.minutes, 30);
    });

    test('finalizar com o treino pausado salva o tempo parado', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 25));
      await service.pause();
      now = now.add(const Duration(hours: 1));

      final session = await service.finish(chart, day);

      expect(session.minutes, 25);
    });

    test('digitar séries não perde a pausa', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 5));
      await service.pause();

      expect(service.active!.copyWith().isPaused, isTrue);
    });

    test('sem treino em andamento, pausar falha', () {
      expect(service.pause(), throwsStateError);
    });

    test('pausar duas vezes não altera o tempo parado', () async {
      await service.start(chart, day);
      now = now.add(const Duration(minutes: 5));
      await service.pause();
      now = now.add(const Duration(minutes: 5));
      await service.pause();

      expect(service.elapsed, const Duration(minutes: 5));
    });

    test('descartar com o treino pausado não salva nada', () async {
      await service.start(chart, day);
      await service.pause();

      await service.discard();

      final sessions = await firestore.collection('users/user-a/sessions').get();
      expect(sessions.docs, isEmpty);
      expect(service.active, isNull);
    });
  });
}