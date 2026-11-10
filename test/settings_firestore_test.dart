import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/services/settings_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SettingsService settings;

  const path = 'users/user-a';

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc(path).set({'name': 'Stefan', 'role': 'student'});
    settings = SettingsService();
    settings.startForTest(firestore, uid: 'user-a');
    await settle();
  });

  tearDown(() => settings.resetForTest());

  test('começa com os valores padrão quando nada foi salvo', () {
    expect(settings.isDarkMode, isFalse);
    expect(settings.language, 'pt_BR');
    expect(settings.timerDisplayMode, 'app_only');
  });

  test('salva tema, idioma e cronômetro no perfil do usuário', () async {
    await settings.setThemeMode(AppThemeMode.dark);
    await settings.setLanguage('en_US');
    await settings.setTimerDisplayMode('overlay');

    final data = (await firestore.doc(path).get()).data()!;

    expect(data['settings'], {
      'themeMode': 'dark',
      'language': 'en_US',
      'timerDisplayMode': 'overlay',
    });
  });

  test('não altera os demais dados do perfil', () async {
    await settings.setThemeMode(AppThemeMode.dark);

    final data = (await firestore.doc(path).get()).data()!;

    expect(data['name'], 'Stefan');
    expect(data['role'], 'student');
  });

  test('recupera as preferências ao entrar em outro aparelho', () async {
    await firestore.doc(path).update({
      'settings': {
        'themeMode': 'dark',
        'language': 'en_US',
        'timerDisplayMode': 'overlay',
      },
    });

    settings.startForTest(firestore, uid: 'user-a');
    await settle();

    expect(settings.isDarkMode, isTrue);
    expect(settings.language, 'en_US');
    expect(settings.timerDisplayMode, 'overlay');
  });

  test('ignora valores desconhecidos', () async {
    await firestore.doc(path).update({
      'settings': {'themeMode': 'azul', 'language': 'xx'},
    });
    await settle();

    expect(settings.isDarkMode, isFalse);
    expect(settings.language, 'pt_BR');
  });

  test('volta aos padrões ao sair da conta', () async {
    await settings.setThemeMode(AppThemeMode.dark);
    await settle();

    settings.stopWatching('user-a');
    await settle();

    expect(settings.isDarkMode, isFalse);
  });

  test('sair de outra conta não afeta o usuário atual', () async {
    await settings.setThemeMode(AppThemeMode.dark);

    settings.stopWatching('user-b');

    expect(settings.isDarkMode, isTrue);
  });
}
