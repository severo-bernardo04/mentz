import 'package:flutter/material.dart';

extension SnackBarContext on BuildContext {
  /// Mostra uma mensagem rápida na parte inferior da tela.
  void showSnack(String message, {Color? background}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }
}