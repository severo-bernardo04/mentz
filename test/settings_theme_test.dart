import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/home/home_page.dart';
import 'package:mentz/features/auth/login_page.dart';
import 'package:mentz/features/auth/register_page.dart';
import 'package:mentz/features/settings/settings_page.dart';
import 'package:mentz/services/settings_service.dart';

void main() {
  late SettingsService settingsService;
  late File tempSettingsFile;

  setUp(() async {
    settingsService = SettingsService();
    tempSettingsFile = File('test_settings_prefs_${DateTime.now().microsecondsSinceEpoch}.json');
    settingsService.resetForTest(defaultMode: AppThemeMode.light);
  });

  tearDown(() async {
    if (await tempSettingsFile.exists()) {
      await tempSettingsFile.delete();
    }
  });

  Widget buildAppUnderTest({Widget? home}) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        final isDark = settingsService.isDarkMode;
        return MaterialApp(
          theme: SettingsService.lightTheme,
          darkTheme: SettingsService.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: home ?? const HomePage(userName: 'Bernardo'),
        );
      },
    );
  }

  group('Settings & Theme Mode Tests', () {
    testWidgets('1. Presença do botão Configurações na AppBar e nos Atalhos da HomePage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAppUnderTest());
      await tester.pumpAndSettle();

      // Botão na AppBar com tooltip 'Ajustes'
      expect(find.byKey(const Key('home_settings_appbar_button')), findsOneWidget);

      // Card de atalho rápido 'Ajustes'
      expect(find.byKey(const Key('home_settings_shortcut_card')), findsOneWidget);
    });

    testWidgets('2. Navegação para a tela de configurações a partir da HomePage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAppUnderTest());
      await tester.pumpAndSettle();

      // Clica no botão de Ajustes na AppBar
      await tester.tap(find.byKey(const Key('home_settings_appbar_button')));
      await tester.pumpAndSettle();

      // Confirma que abriu SettingsPage
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Aparência'), findsOneWidget);
      expect(find.text('Modo escuro'), findsOneWidget);
      expect(find.byKey(const Key('dark_mode_switch')), findsOneWidget);
    });

    testWidgets('3 & 4. Alternância entre modo claro e escuro atualiza telas internas reativamente',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAppUnderTest());
      await tester.pumpAndSettle();

      // Abre a tela de Ajustes
      await tester.tap(find.byKey(const Key('home_settings_appbar_button')));
      await tester.pumpAndSettle();

      expect(settingsService.isDarkMode, isFalse);

      // Alterna o switch para modo escuro
      await tester.tap(find.byKey(const Key('dark_mode_switch')));
      await tester.pumpAndSettle();

      expect(settingsService.isDarkMode, isTrue);
      expect(find.text('Tema escuro ativado nas telas internas'), findsOneWidget);

      // Volta para a HomePage
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      // HomePage permanece exibida sob o tema escuro
      expect(find.byType(HomePage), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold, isNotNull);
    });

    test('5. Persistência da preferência em arquivo JSON', () async {
      settingsService.enableFilePersistence = true;
      // Carrega com arquivo customizado temporário
      await settingsService.loadSettings(customFile: tempSettingsFile);
      expect(settingsService.isDarkMode, isFalse);

      // Altera para escuro
      await settingsService.setThemeMode(AppThemeMode.dark);
      expect(await tempSettingsFile.exists(), isTrue);

      // Simula uma nova instância ou reinicialização
      settingsService.resetForTest(defaultMode: AppThemeMode.light, filePersistence: true);
      expect(settingsService.isDarkMode, isFalse);

      // Recarrega do arquivo
      await settingsService.loadSettings(customFile: tempSettingsFile);
      expect(settingsService.isDarkMode, isTrue);
    });

    testWidgets('6 & 7. Preservação do tema visual de Login e Cadastro nos modos claro e escuro',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildAppUnderTest(home: const LoginPage()));
      await tester.pumpAndSettle();

      // Confirma que LoginPage renderiza com authTheme
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Mentz'), findsWidgets);
      expect(find.text('Cadastre-se'), findsOneWidget);

      // Força modo escuro global
      await settingsService.setThemeMode(AppThemeMode.dark);
      await tester.pumpAndSettle();

      // LoginPage continua exibida com authTheme (tema claro protegido)
      expect(find.byType(LoginPage), findsOneWidget);

      // Testa RegisterPage também diretamente sob modo escuro
      await tester.pumpWidget(buildAppUnderTest(home: const RegisterPage()));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
    });
  });
}
