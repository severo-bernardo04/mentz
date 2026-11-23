import 'package:flutter/material.dart';

import '../../../widgets/app_logo.dart';

/// Logo com Hero (anima na troca entre login e registro).
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Hero(
          tag: 'auth-logo',
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withAlpha(90),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            // Silhueta do Mentz em branco sobre o degradê do tema, na mesma
            // proporção do ícone do Android: a figura ocupa o círculo e as
            // pernas continuam além da borda de baixo
            child: ClipOval(
              child: OverflowBox(
                maxHeight: 76 + 18, // figura + recuo; o excesso some pela borda
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: AppLogo(size: 76, color: cs.onPrimary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Mentz',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}