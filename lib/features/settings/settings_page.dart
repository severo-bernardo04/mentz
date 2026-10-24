import 'package:flutter/material.dart';
import 'package:mentz/features/settings/widgets/appearance_section.dart';
import 'package:mentz/features/settings/widgets/language_section.dart';
import 'package:mentz/features/settings/widgets/timer_section.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:mentz/widgets/app_page_scaffold.dart';
import 'package:mentz/widgets/staggered_column.dart';

class SettingsPage extends StatelessWidget {
  final SettingsService? service;

  const SettingsPage({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final settings = service ?? SettingsService();

    return AppPageScaffold(
      title: 'Ajustes',
      maxWidth: 560,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => StaggeredColumn(
          spacing: 0,
          startDelay: Duration.zero,
          children: [
            AppearanceSection(settings: settings),
            LanguageSection(settings: settings),
            TimerSection(settings: settings),
            const _VersionLabel(),
          ],
        ),
      ),
    );
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Center(
        child: Text(
          'Mentz App v1.0.0+1',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}