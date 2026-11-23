import 'package:flutter/material.dart';

/// Logo do Mentz: a silhueta do fisiculturista, a mesma do ícone do app.
///
/// O asset (`assets/branding/mentz_logo.png`) é uma silhueta branca em fundo
/// transparente; a cor vem de [color] (por padrão, o primário do tema), o que
/// permite usar a mesma imagem no tema claro, no escuro e sobre degradês.
class AppLogo extends StatelessWidget {
  static const asset = 'assets/branding/mentz_logo.png';

  final double size;

  /// Cor da silhueta; sem valor, usa `colorScheme.primary`.
  final Color? color;

  const AppLogo({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      // Pinta só a silhueta, mantendo o fundo transparente
      color: color ?? Theme.of(context).colorScheme.primary,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Mentz',
    );
  }
}
