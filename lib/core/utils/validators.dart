import 'package:flutter/widgets.dart';

/// Validações reutilizáveis para formulários.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? v) {
    if (v == null || !_emailRegex.hasMatch(v.trim())) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  static String? notEmpty(String? v, [String message = 'Campo obrigatório.']) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().length < 2) return 'Digite seu nome.';
    return null;
  }

  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'Digite uma senha.';
    if (v.length < 8) return 'Mínimo de 8 caracteres.';
    return null;
  }

  /// Valida se a confirmação é igual ao campo de senha original.
  static String? Function(String?) confirmPassword(
    TextEditingController original,
  ) {
    return (v) {
      if (v == null || v.isEmpty) return 'Confirme sua senha.';
      if (v != original.text) return 'As senhas não coincidem.';
      return null;
    };
  }
}