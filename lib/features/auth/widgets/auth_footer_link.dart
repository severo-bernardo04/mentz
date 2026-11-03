import 'package:flutter/material.dart';

/// Linha "Não tem conta? Cadastre-se" / "Já tem conta? Entrar".
class AuthFooterLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onPressed;

  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          onPressed: onPressed,
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}