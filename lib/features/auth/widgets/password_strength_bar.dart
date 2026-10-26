import 'package:flutter/material.dart';

/// Barra animada de força da senha. Escuta o controller sozinha,
/// então a tela não precisa de setState a cada tecla.
class PasswordStrengthBar extends StatelessWidget {
  final TextEditingController controller;

  const PasswordStrengthBar({super.key, required this.controller});

  static const _labels = ['Muito fraca', 'Fraca', 'Média', 'Boa', 'Forte'];

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF7CB342),
    Color(0xFF2E7D32),
  ];

  static int _score(String p) {
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final password = value.text;
        final score = _score(password);
        final color = _colors[score];

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: password.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (score + 1) / 5),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            color: color,
                            backgroundColor: color.withAlpha(40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Força da senha: ${_labels[score]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}