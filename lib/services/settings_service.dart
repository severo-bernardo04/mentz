import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'user_profile_service.dart';

/// Modo de tema da aplicação.
enum AppThemeMode {
  light,
  dark,
}

/// Preferências do usuário logado: tema, idioma e exibição do cronômetro.
/// Ficam no campo `settings` de `users/{uid}`, valendo em qualquer aparelho.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _defaultLanguage = 'pt_BR';
  static const _defaultTimerMode = 'app_only';
  static const _languages = {'pt_BR', 'en_US'};
  static const _timerModes = {'app_only', 'overlay'};

  /// Tempo máximo de espera pela confirmação do servidor. Sem internet, a
  /// escrita fica na fila do Firestore e é enviada quando a conexão voltar.
  static const _writeTimeout = Duration(seconds: 8);

  UserProfileService _profiles = UserProfileService();
  StreamSubscription<AppUser?>? _subscription;
  String? _uid;

  AppThemeMode _themeMode = AppThemeMode.light;
  String _language = _defaultLanguage;
  String _timerDisplayMode = _defaultTimerMode;

  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == AppThemeMode.dark;
  String get language => _language;
  String get timerDisplayMode => _timerDisplayMode;

  /// Retorna o tema claro padronizado da aplicação.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
    );
  }

  /// Retorna o tema escuro padronizado para as telas internas.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF12141C),
    );
  }

  /// Tema exclusivo e fixo para autenticação (Login e Cadastro),
  /// garantindo que eles NUNCA mudem de aparência, mesmo em modo escuro.
  static ThemeData get authTheme => lightTheme;

  /// Começa a acompanhar as preferências de [uid].
  void watchUser(String uid) {
    if (_uid == uid) return;

    _subscription?.cancel();
    _uid = uid;
    _subscription = _profiles.watch(uid).listen(
      _applyUser,
      onError: (Object _) {},
    );
  }

  /// Para de acompanhar [uid] e volta aos padrões, para não vazar para a
  /// próxima conta. Ignora a chamada se outro usuário já estiver logado.
  void stopWatching(String uid) {
    if (_uid != uid) return;

    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _themeMode = AppThemeMode.light;
    _language = _defaultLanguage;
    _timerDisplayMode = _defaultTimerMode;

    // Chamado durante o descarte de widgets, quando a árvore não pode mudar
    scheduleMicrotask(notifyListeners);
  }

  /// Aplica as preferências salvas, ignorando valores desconhecidos.
  void _applyUser(AppUser? user) {
    if (user == null) return;

    final theme = switch (user.themeMode) {
      'dark' => AppThemeMode.dark,
      'light' => AppThemeMode.light,
      _ => _themeMode,
    };
    final language = _languages.contains(user.language)
        ? user.language!
        : _language;
    final timerMode = _timerModes.contains(user.timerDisplayMode)
        ? user.timerDisplayMode!
        : _timerDisplayMode;

    if (theme == _themeMode &&
        language == _language &&
        timerMode == _timerDisplayMode) {
      return;
    }

    _themeMode = theme;
    _language = language;
    _timerDisplayMode = timerMode;
    notifyListeners();
  }

  /// Grava uma preferência sem apagar as demais de `settings`.
  Future<void> _persist(String field, String value) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _profiles
          .update(uid, {'settings.$field': value})
          .timeout(_writeTimeout, onTimeout: () {});
    } catch (_) {
      debugPrint('Não foi possível salvar a preferência $field.');
    }
  }

  /// Define o modo do tema (claro ou escuro) e persiste a escolha.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist('themeMode', mode.name);
  }

  /// Alterna diretamente entre claro e escuro.
  Future<void> toggleTheme() async {
    final nextMode = _themeMode == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
    await setThemeMode(nextMode);
  }

  /// Atualiza o idioma (preparado para expansão futura).
  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    await _persist('language', lang);
  }

  /// Atualiza a preferência do cronômetro (app_only ou overlay).
  Future<void> setTimerDisplayMode(String mode) async {
    _timerDisplayMode = mode;
    notifyListeners();
    await _persist('timerDisplayMode', mode);
  }

  /// Passa a usar um Firestore de teste, acompanhando [uid].
  @visibleForTesting
  void startForTest(FirebaseFirestore firestore, {required String uid}) {
    resetForTest();
    _profiles = UserProfileService(firestore: firestore);
    watchUser(uid);
  }

  /// Limpa as configurações para ambiente de teste.
  @visibleForTesting
  void resetForTest({AppThemeMode defaultMode = AppThemeMode.light}) {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _themeMode = defaultMode;
    _language = _defaultLanguage;
    _timerDisplayMode = _defaultTimerMode;
    notifyListeners();
  }
}
