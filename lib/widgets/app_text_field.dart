import 'package:flutter/material.dart';

/// Campo de texto padrão do app. Com `isPassword`, já inclui o botão de
/// mostrar/ocultar senha. `label`, `hint` e `icon` são opcionais.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool isPassword;
  final int? minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.isPassword = false,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration: appInputDecoration(
        context,
        label: widget.label,
        hint: widget.hint,
        icon: widget.icon,
        suffix: widget.isPassword ? _buildToggle() : null,
      ),
    );
  }

  Widget _buildToggle() {
    return IconButton(
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          key: ValueKey(_obscure),
        ),
      ),
    );
  }
}

/// Estilo padrão dos campos (pública para outros formulários do app).
InputDecoration appInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  IconData? icon,
  Widget? suffix,
}) {
  final cs = Theme.of(context).colorScheme;

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: cs.surfaceContainerHighest.withAlpha(90),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(cs.primary, 2),
    errorBorder: border(cs.error),
    focusedErrorBorder: border(cs.error, 2),
  );
}