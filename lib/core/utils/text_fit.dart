import 'package:flutter/widgets.dart';

/// Maior tamanho de fonte, entre [min] e [max], em que todos os [texts]
/// cabem em [maxWidth] com no máximo [maxLines] linhas e sem quebrar
/// nenhuma palavra no meio. Se nem [min] couber, retorna [min] (o texto
/// será cortado com reticências por quem exibe).
///
/// Um único tamanho para todos os textos mantém um conjunto (como abas)
/// homogêneo, em vez de cada item com uma fonte diferente.
double fitFontSize(
  List<String> texts, {
  required double maxWidth,
  required TextStyle style,
  int maxLines = 2,
  double max = 16,
  double min = 11,
  double step = 0.5,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  if (maxWidth <= 0 || !maxWidth.isFinite) return min;

  bool fits(double size) {
    final sized = style.copyWith(fontSize: size);

    for (final text in texts) {
      // O texto inteiro cabe nas linhas permitidas
      final painter = TextPainter(
        text: TextSpan(text: text, style: sized),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth);
      final exceeded = painter.didExceedMaxLines;
      painter.dispose();
      if (exceeded) return false;

      // Nenhuma palavra é mais larga que a linha (seria quebrada no meio)
      for (final word in text.split(RegExp(r'\s+'))) {
        final wordPainter = TextPainter(
          text: TextSpan(text: word, style: sized),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        final tooWide = wordPainter.width > maxWidth;
        wordPainter.dispose();
        if (tooWide) return false;
      }
    }
    return true;
  }

  for (var size = max; size >= min; size -= step) {
    if (fits(size)) return size;
  }
  return min;
}
