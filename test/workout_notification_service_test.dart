import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/workout_notification_service.dart';
import 'package:mentz/services/workout_session_service.dart';

/// Plataforma falsa que só registra o que foi pedido.
class FakeNotification implements WorkoutNotificationPlatform {
  bool granted;
  bool grantOnRequest;
  int requests = 0;
  final shown = <WorkoutTimerDisplay>[];
  int hides = 0;

  FakeNotification({this.granted = true, this.grantOnRequest = true});

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return granted = grantOnRequest;
  }

  @override
  Future<void> show(WorkoutTimerDisplay display) async => shown.add(display);

  @override
  Future<void> hide() async => hides++;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutSessionService session;
  late DateTime now;
  final notification = WorkoutNotificationService();

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

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/user-a').set({'name': 'Aluno', 'role': 'student'});
    now = DateTime(2026, 11, 12, 18);
    session = WorkoutSessionService()
      ..startForTest(firestore, uid: 'user-a', clock: () => now);
    await settle();
  });

  tearDown(() {
    notification.resetForTest();
    session.stopWatching('user-a');
  });

  test('com treino em andamento, mostra o cronômetro a partir do início', () async {
    final fake = FakeNotification();
    await session.start(chart, day);

    await notification.syncForTest(platform: fake);

    expect(fake.shown, hasLength(1));
    expect(fake.shown.single.running, isTrue);
    expect(fake.shown.single.baseMs, now.millisecondsSinceEpoch);
  });

  test('sem treino em andamento, não mostra nada', () async {
    final fake = FakeNotification();

    await notification.syncForTest(platform: fake);

    expect(fake.shown, isEmpty);
    expect(fake.hides, 0);
  });

  test('o mesmo estado não é publicado duas vezes', () async {
    final fake = FakeNotification();
    await session.start(chart, day);

    await notification.syncForTest(platform: fake);
    await notification.syncForTest(platform: fake);

    expect(fake.shown, hasLength(1));
  });

  test('pausar publica o tempo parado e retomar volta a contar', () async {
    final fake = FakeNotification();
    await session.start(chart, day);
    await notification.syncForTest(platform: fake);

    now = now.add(const Duration(minutes: 10));
    await session.pause();
    await notification.syncForTest(platform: fake);

    expect(fake.shown.last.running, isFalse);
    expect(fake.shown.last.elapsedMs, const Duration(minutes: 10).inMilliseconds);

    now = now.add(const Duration(minutes: 20));
    await session.resume();
    await notification.syncForTest(platform: fake);

    // Início equivalente = início real + 20 min parados
    expect(fake.shown.last.running, isTrue);
    expect(
      fake.shown.last.baseMs,
      now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
  });

  test('ao finalizar, a notificação é removida', () async {
    final fake = FakeNotification();
    await session.start(chart, day);
    await notification.syncForTest(platform: fake);

    await session.finish(chart, day);
    await notification.syncForTest(platform: fake);

    expect(fake.hides, 1);
  });

  test('pede a permissão uma vez, ao iniciar o treino', () async {
    final fake = FakeNotification(granted: false, grantOnRequest: false);
    await session.start(chart, day);

    await notification.syncForTest(platform: fake);
    now = now.add(const Duration(minutes: 1));
    await session.pause();
    await notification.syncForTest(platform: fake);

    expect(fake.requests, 1);
  });

  test('não pede a permissão se ela já foi concedida', () async {
    final fake = FakeNotification();
    await session.start(chart, day);

    await notification.syncForTest(platform: fake);

    expect(fake.requests, 0);
  });
}