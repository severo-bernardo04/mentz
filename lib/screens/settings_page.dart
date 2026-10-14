import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'auth_widgets.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService? service;

  const SettingsPage({super.key, this.service});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsService get _settings => widget.service ?? SettingsService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Ajustes',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: AuthBackground(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Seção Aparência
                        FadeSlideIn(
                          child: AuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.palette_outlined, color: cs.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Aparência',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile.adaptive(
                                  key: const Key('dark_mode_switch'),
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                      color: cs.onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  title: const Text(
                                    'Modo escuro',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    isDark
                                        ? 'Tema escuro ativado nas telas internas'
                                        : 'Tema claro ativado nas telas internas',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  value: isDark,
                                  onChanged: (val) {
                                    _settings.setThemeMode(
                                      val ? AppThemeMode.dark : AppThemeMode.light,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Seção Idioma
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: AuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.language_rounded, color: cs.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Idioma',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.translate_rounded,
                                      color: cs.onSecondaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  title: const Text(
                                    'Português (Brasil)',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Idioma padrão do aplicativo',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: DropdownButton<String>(
                                    key: const Key('language_dropdown'),
                                    value: _settings.language,
                                    underline: const SizedBox(),
                                    borderRadius: BorderRadius.circular(12),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'pt_BR',
                                        child: Text('PT-BR'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'en_US',
                                        child: Text('EN-US (Em breve)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        _settings.setLanguage(val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Seção Cronômetro
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: AuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: cs.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cronômetro de Treino',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.tertiaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.layers_outlined,
                                      color: cs.onTertiaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  title: const Text(
                                    'Modo de Exibição',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    _settings.timerDisplayMode == 'app_only'
                                        ? 'Somente com o app aberto'
                                        : 'Overlay sobre outros apps (Em breve)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: DropdownButton<String>(
                                    key: const Key('timer_dropdown'),
                                    value: _settings.timerDisplayMode,
                                    underline: const SizedBox(),
                                    borderRadius: BorderRadius.circular(12),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'app_only',
                                        child: Text('App aberto'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'overlay',
                                        child: Text('Overlay (Em breve)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        _settings.setTimerDisplayMode(val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Informação sobre o app
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: Center(
                            child: Text(
                              'Mentz App v1.0.0+1',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
