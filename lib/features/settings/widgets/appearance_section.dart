import 'package:flutter/material.dart';
import 'package:mentz/features/settings/widgets/settings_tile.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:mentz/widgets/section_card.dart';

/// Ajuste de tema claro/escuro.
class AppearanceSection extends StatelessWidget {
  final SettingsService settings;

  const AppearanceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = settings.isDarkMode;

    void setDark(bool dark) {
      settings.setThemeMode(dark ? AppThemeMode.dark : AppThemeMode.light);
    }

    return SectionCard(
      title: 'Aparência',
      icon: Icons.palette_outlined,
      child: SettingsTile(
        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        title: 'Modo escuro',
        subtitle: isDark
            ? 'Tema escuro ativado nas telas internas'
            : 'Tema claro ativado nas telas internas',
        onTap: () => setDark(!isDark),
        trailing: Switch.adaptive(
          key: const Key('dark_mode_switch'),
          value: isDark,
          onChanged: setDark,
        ),
      ),
    );
  }
}