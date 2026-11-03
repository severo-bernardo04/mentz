import 'package:flutter/material.dart';
import 'package:mentz/features/settings/widgets/icon_badge.dart';
import 'package:mentz/features/settings/widgets/settings_tile.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:mentz/widgets/app_dropdown.dart';
import 'package:mentz/widgets/section_card.dart';

/// Modo de exibição do cronômetro de treino.
class TimerSection extends StatelessWidget {
  final SettingsService settings;

  const TimerSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final appOnly = settings.timerDisplayMode == 'app_only';

    return SectionCard(
      title: 'Cronômetro de Treino',
      icon: Icons.timer_outlined,
      child: SettingsTile(
        icon: Icons.layers_outlined,
        tone: BadgeTone.tertiary,
        title: 'Modo de Exibição',
        subtitle: appOnly
            ? 'Somente com o app aberto'
            : 'Overlay sobre outros apps (Em breve)',
        trailing: AppDropdown<String>(
          key: const Key('timer_dropdown'),
          value: settings.timerDisplayMode,
          onChanged: settings.setTimerDisplayMode,
          items: const [
            DropdownMenuItem(value: 'app_only', child: Text('App aberto')),
            DropdownMenuItem(value: 'overlay', child: Text('Overlay (Em breve)')),
          ],
        ),
      ),
    );
  }
}