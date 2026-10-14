import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Modo de tema da aplicação.
enum AppThemeMode {
  light,
  dark,
}

/// Serviço de configurações e preferências do Mentz.
/// Gerencia tema (claro/escuro), persistência em arquivo JSON local e configurações futuras.
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  AppThemeMode _themeMode = AppThemeMode.light;
  String _language = 'pt_BR'; // pt_BR ou en_US
  String _timerDisplayMode = 'app_only'; // 'app_only' ou 'overlay'
  bool enableFilePersistence = true;

  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == AppThemeMode.dark;
  String get language => _language;
  String get timerDisplayMode => _timerDisplayMode;

  File? _preferencesFile;

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

  /// Obtém o arquivo de preferências local.
  Future<File> _getFile() async {
    if (_preferencesFile != null) return _preferencesFile!;
    try {
      final dir = Directory.systemTemp;
      _preferencesFile = File('${dir.path}/settings_prefs.json');
    } catch (_) {
      try {
        final dir = Directory.current;
        _preferencesFile = File('${dir.path}/settings_prefs.json');
      } catch (_) {
        _preferencesFile = File('settings_prefs.json');
      }
    }
    return _preferencesFile!;
  }

  /// Carrega as preferências salvas no arquivo.
  Future<void> loadSettings({File? customFile}) async {
    if (customFile != null) {
      _preferencesFile = customFile;
    }
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final savedTheme = data['themeMode'] as String?;
          if (savedTheme == 'dark') {
            _themeMode = AppThemeMode.dark;
          } else {
            _themeMode = AppThemeMode.light;
          }
          if (data['language'] is String) {
            _language = data['language'] as String;
          }
          if (data['timerDisplayMode'] is String) {
            _timerDisplayMode = data['timerDisplayMode'] as String;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
    }
  }

  /// Salva as preferências atuais em arquivo.
  Future<void> _saveSettings() async {
    if (!enableFilePersistence) return;
    try {
      final file = await _getFile();
      final data = {
        'themeMode': _themeMode == AppThemeMode.dark ? 'dark' : 'light',
        'language': _language,
        'timerDisplayMode': _timerDisplayMode,
      };
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('Erro ao salvar preferências: $e');
    }
  }

  /// Define o modo do tema (claro ou escuro) e persiste a escolha.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveSettings();
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
    await _saveSettings();
  }

  /// Atualiza a preferência do cronômetro (app_only ou overlay).
  Future<void> setTimerDisplayMode(String mode) async {
    _timerDisplayMode = mode;
    notifyListeners();
    await _saveSettings();
  }

  /// Limpa as configurações para ambiente de teste.
  @visibleForTesting
  void resetForTest({
    AppThemeMode defaultMode = AppThemeMode.light,
    bool filePersistence = false,
  }) {
    _themeMode = defaultMode;
    _language = 'pt_BR';
    _timerDisplayMode = 'app_only';
    _preferencesFile = null;
    enableFilePersistence = filePersistence;
    notifyListeners();
  }
}
