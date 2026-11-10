import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo numérico que aceita valores de 0,5 em 0,5 (carga e repetições).
///
/// Aceita vírgula ou ponto. Enquanto o usuário digita, o valor é arredondado
/// para o 0,5 mais próximo e enviado em [onChanged]; ao sair do campo, o texto
/// é reescrito com o valor arredondado. Campo vazio vale 0.
class HalfStepField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final Color? textColor;
  final String hint;

  /// Botão opcional dentro do campo, à direita (ex: "BW").
  final Widget? suffixIcon;

  /// Maior valor aceito, para evitar números absurdos por erro de digitação.
  final double max;

  const HalfStepField({
    super.key,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.textColor,
    this.hint = '0',
    this.suffixIcon,
    this.max = 999.5,
  });

  /// Arredonda para o múltiplo de 0,5 mais próximo, entre 0 e [max].
  static double snap(double value, {double max = 999.5}) =>
      ((value * 2).round() / 2).clamp(0, max).toDouble();

  /// Lê o texto digitado. Retorna null se não for um número.
  static double? parse(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized);
  }

  /// Texto do valor, sem casas decimais quando inteiro e vazio quando 0.
  static String format(double value) {
    if (value == 0) return '';
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return text.replaceAll('.', ',');
  }

  @override
  State<HalfStepField> createState() => _HalfStepFieldState();
}

class _HalfStepFieldState extends State<HalfStepField> {
  late final _controller = TextEditingController(
    text: HalfStepField.format(widget.value),
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(HalfStepField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Valor mudou por fora (ex: outro aparelho): atualiza se não estiver digitando
    final typed = HalfStepField.parse(_controller.text);
    if (!_focus.hasFocus && typed != widget.value) {
      _controller.text = HalfStepField.format(widget.value);
    }
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) return;
    _controller.text = HalfStepField.format(widget.value);
  }

  void _onTextChanged(String text) {
    final parsed = HalfStepField.parse(text);
    if (parsed == null) return;

    final snapped = HalfStepField.snap(parsed, max: widget.max);
    if (snapped != widget.value) widget.onChanged(snapped);
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      focusNode: _focus,
      onChanged: _onTextChanged,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      // Só dígitos e um separador decimal
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d?)?')),
      ],
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: widget.textColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        // Dica bem clara, para não ser confundida com um valor já digitado
        hintStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant.withAlpha(90),
        ),
        suffixText: widget.suffix,
        suffixIcon: widget.suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: widget.textColor?.withAlpha(150) ?? cs.outlineVariant,
          ),
        ),
      ),
    );
  }
}
