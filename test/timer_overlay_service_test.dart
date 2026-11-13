import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/training_chart.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:mentz/services/timer_overlay_service.dart';
import 'package:mentz/services/workout_session_service.dart';

/// Janela flutuante falsa, que só registra o que foi pedido.
class FakeOverlay implements TimerOverlayPlatform {
  bool granted;
  bool grantOnRequest;
  bool supported;
  int requests = 0;
  DateTime? shown;
  int closes = 0;

  FakeOverlay({
    this.granted = true,
    this.grantOnRequest = false,
    this.supported = true,
  });

  @override
  bool get isSupported => supported;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return granted = grantOnRequest;
  }

  int shows = 0;

  @override
  Future<void> show(DateTime startedAt) async {
    shows++;
    shown = startedAt;
  }

  @override
  Future<void> close() async {
    shown = null;
    closes++;
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutSessionService session;
  late SettingsService settings;
  final overlay = TimerOverlayService();
  final start = DateTime(2026, 11, 12, 18);

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
    settings = SettingsService()..startForTest(firestore, uid: 'user-a');
    session = WorkoutSessionService()
      ..startForTest(firestore, uid: 'user-a', clock: () => start);
    await settle();
  });

  tearDown(() {
    overlay.resetForTest();
    session.stopWatching('user-a');
    settings.resetForTest();
  });

  test('no modo overlay, com treino e app em segundo plano, a janela aparece', () async {
    final fake = FakeOverlay();
    await settings.setTimerDisplayMode('overlay');
    await session.start(chart, day);

    await overlay.syncForTest(platform: fake, inBackground: true);

    expect(fake.shown, start);
  });

  test('dois avisos seguidos de segundo plano abrem a janela uma vez só', () async {
    final fake = FakeOverlay();
    await settings.setTimerDisplayMode('overlay');
    await session.start(chart, day);

    // O Android avisa "hidden" e "paused" em sequência, sem esperar
    final first = overlay.syncForTest(platform: fake, inBackground: true);
    final second = overlay.syncForTest(platform: fake, inBackground: true);
    await Future.wait([first, second]);

    expect(fake.shows, 1);
  });

  test('ao voltar para o app, a janela fecha', () async {
    final fake = FakeOverlay();
    await settings.setTimerDisplayMode('overlay');
    await session.start(chart, day);
    await overlay.syncForTest(platform: fake, inBackground: true);

    await overlay.syncForTest(platform: fake, inBackground: false);

    expect(fake.shown, isNull);
    expect(fake.closes, 1);
  });

  test('no modo "App aberto", a janela nunca aparece', () async {
    final fake = FakeOverlay();
    await session.start(chart, day);

    await overlay.syncForTest(platform: fake, inBackground: true);

    expect(fake.shown, isNull);
  });

  test('sem treino em andamento, a janela não aparece', () async {
    final fake = FakeOverlay();
    await settings.setTimerDisplayMode('overlay');

    await overlay.syncForTest(platform: fake, inBackground: true);

    expect(fake.shown, isNull);
  });

  test('sem a permissão do sistema, a janela não aparece', () async {
    final fake = FakeOverlay(granted: false);
    await settings.setTimerDisplayMode('overlay');
    await session.start(chart, day);

    await overlay.syncForTest(platform: fake, inBackground: true);

    expect(fake.shown, isNull);
  });

  group('Ativar o modo overlay', () {
    test('pede a permissão e ativa quando o usuário concede', () async {
      final fake = FakeOverlay(granted: false, grantOnRequest: true);
      await overlay.syncForTest(platform: fake, inBackground: false);

      expect(await overlay.enableOverlayMode(), isTrue);
      expect(fake.requests, 1);
      expect(settings.timerDisplayMode, 'overlay');
    });

    test('mantém "App aberto" quando o usuário recusa', () async {
      final fake = FakeOverlay(granted: false);
      await overlay.syncForTest(platform: fake, inBackground: false);

      expect(await overlay.enableOverlayMode(), isFalse);
      expect(settings.timerDisplayMode, 'app_only');
    });

    test('não pede de novo se a permissão já existe', () async {
      final fake = FakeOverlay();
      await overlay.syncForTest(platform: fake, inBackground: false);

      expect(await overlay.enableOverlayMode(), isTrue);
      expect(fake.requests, 0);
    });

    test('fora do Android, não ativa', () async {
      final fake = FakeOverlay(supported: false);
      await overlay.syncForTest(platform: fake, inBackground: false);

      expect(await overlay.enableOverlayMode(), isFalse);
      expect(settings.timerDisplayMode, 'app_only');
    });
  });
}
