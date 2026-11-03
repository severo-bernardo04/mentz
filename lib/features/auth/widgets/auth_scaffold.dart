import 'package:flutter/material.dart';

import '../../../services/settings_service.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/fade_slide_in.dart';
import 'auth_logo.dart';

/// Layout comum das telas de autenticação: tema, fundo, logo, cartão e rodapé.
///
/// Os widgets filhos usam `Theme.of(context)` dentro do próprio `build`,
/// por isso já enxergam o tema de autenticação aplicado aqui.
class AuthScaffold extends StatelessWidget {
  /// Conteúdo do cartão (normalmente um [Form]).
  final Widget form;

  /// Conteúdo abaixo do cartão (link para outra tela).
  final Widget footer;

  /// Mostra a AppBar transparente com o botão de voltar.
  final bool showBackButton;

  const AuthScaffold({
    super.key,
    required this.form,
    required this.footer,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SettingsService.authTheme,
      child: Scaffold(
        extendBodyBehindAppBar: showBackButton,
        appBar: showBackButton
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
              )
            : null,
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FadeSlideIn(child: AuthLogo()),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: AppCard(child: form),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 600),
                        child: footer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}