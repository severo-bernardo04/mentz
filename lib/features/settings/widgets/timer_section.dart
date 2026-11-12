import 'package:flutter/material.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/features/settings/widgets/icon_badge.dart';
import 'package:mentz/features/settings/widgets/settings_tile.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:mentz/services/timer_overlay_service.dart';
import 'package:mentz/widgets/app_dropdown.dart';
import 'package:mentz/widgets/section_card.dart';

/// Modo de exibição do cronômetro de treino: só dentro do app ou também
/// sobre outros apps (overlay, disponível apenas no Android).
class TimerSection extends StatelessWidget {
  final SettingsService settings;

  const TimerSection({super.key, required this.settings});

  /// Troca o modo. O overlay depende da permissão de sobreposição do
  /// sistema: se o usuário recusar, o modo continua como estava.
  Future<void> _changeMode(BuildContext context, String? mode) async {
    if (mode == null || mode == settings.timerDisplayMode) return;

    if (mode != 'overlay') {
      await settings.setTimerDisplayMode(mode);
      return;
    }

    final enabled = await TimerOverlayService().enableOverlayMode();
    if (!enabled && context.mounted) {
      context.showSnack(
        'Permita a exibição sobre outros apps para usar o overlay.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlaySupported = TimerOverlayService().isSupported;
    final appOnly = settings.timerDisplayMode == 'app_only';

    return SectionCard(
      title: 'Cronômetro de Treino',
      icon: Icons.timer_outlined,
      child: SettingsTile(
        icon: Icons.layers_outlined,
        tone: BadgeTone.tertiary,
        title: 'Modo de Exibição',
        subtitle: !overlaySupported
            ? 'Somente com o app aberto (overlay só no Android)'
            : appOnly
            ? 'Somente com o app aberto'
            : 'Também sobre outros apps',
        trailing: AppDropdown<String>(
          key: const Key('timer_dropdown'),
          // Fora do Android, o modo salvo em outro aparelho não tem efeito
          value: overlaySupported ? settings.timerDisplayMode : 'app_only',
          onChanged: (mode) => _changeMode(context, mode),
          items: [
            const DropdownMenuItem(value: 'app_only', child: Text('App aberto')),
            if (overlaySupported)
              const DropdownMenuItem(value: 'overlay', child: Text('Overlay')),
          ],
        ),
      ),
    );
  }
}
