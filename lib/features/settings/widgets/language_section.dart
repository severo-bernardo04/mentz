import 'package:flutter/material.dart';
import 'package:mentz/features/settings/widgets/icon_badge.dart';
import 'package:mentz/features/settings/widgets/settings_tile.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:mentz/widgets/app_dropdown.dart';
import 'package:mentz/widgets/section_card.dart';

/// Seleção de idioma.
class LanguageSection extends StatelessWidget {
  final SettingsService settings;

  const LanguageSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Idioma',
      icon: Icons.language_rounded,
      child: SettingsTile(
        icon: Icons.translate_rounded,
        tone: BadgeTone.secondary,
        title: 'Português (Brasil)',
        subtitle: 'Idioma padrão do aplicativo',
        trailing: AppDropdown<String>(
          key: const Key('language_dropdown'),
          value: settings.language,
          onChanged: settings.setLanguage,
          items: const [
            DropdownMenuItem(value: 'pt_BR', child: Text('PT-BR')),
            DropdownMenuItem(value: 'en_US', child: Text('EN-US (Em breve)')),
          ],
        ),
      ),
    );
  }
}