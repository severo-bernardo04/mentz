import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gráfico de linha simples (sem dependências externas).
///
/// Com [interactive], tocar ou arrastar sobre o gráfico seleciona o ponto
/// mais próximo e mostra o valor dele (e o texto de [pointLabels], se
/// houver). Sem seleção, o rótulo mostra o último valor.
class SimpleLineChart extends StatefulWidget {
  final List<double> values;

  /// Textos sob o gráfico, distribuídos de ponta a ponta (ex: datas).
  final List<String> labels;
  final String unit;
  final double height;
  final bool interactive;

  /// Texto de cada ponto, mostrado junto do valor ao selecioná-lo.
  final List<String>? pointLabels;

  /// Formata o valor do rótulo; por padrão, uma casa decimal mais [unit].
  final String Function(double value)? valueFormatter;

  const SimpleLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.unit = '',
    this.height = 150,
    this.interactive = false,
    this.pointLabels,
    this.valueFormatter,
  });

  @override
  State<SimpleLineChart> createState() => _SimpleLineChartState();
}

class _SimpleLineChartState extends State<SimpleLineChart> {
  /// Ponto selecionado pelo toque; null sem seleção.
  int? _selected;

  @override
  void didUpdateWidget(SimpleLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dados novos: a seleção antiga não vale mais
    if (oldWidget.values != widget.values) _selected = null;
  }

  /// Seleciona o ponto mais próximo da posição horizontal do toque.
  void _selectAt(double dx, double width) {
    final count = widget.values.length;
    if (count < 2) return;

    final usable = width - _LinePainter.padX * 2;
    final ratio = ((dx - _LinePainter.padX) / usable).clamp(0.0, 1.0);
    final index = (ratio * (count - 1)).round();
    if (index != _selected) setState(() => _selected = index);
  }

  String _format(double value) =>
      widget.valueFormatter?.call(value) ??
      '${value.toStringAsFixed(1)}${widget.unit}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = widget.values;
    final selected = _selected != null && _selected! < values.length
        ? _selected
        : null;

    // Rótulo: ponto selecionado (com o texto dele) ou o último valor
    final labelIndex = selected ?? values.length - 1;
    final pointLabel = selected == null ? null : widget.pointLabels?[selected];
    final label = values.isEmpty
        ? ''
        : [?pointLabel, _format(values[labelIndex])].join('  ');

    Widget chart = LayoutBuilder(
      builder: (context, constraints) {
        final painted = CustomPaint(
          size: Size(constraints.maxWidth, widget.height),
          painter: _LinePainter(
            values: values,
            label: label,
            labelIndex: labelIndex,
            selected: selected,
            lineColor: cs.primary,
            gridColor: cs.outlineVariant,
            dotColor: cs.surface,
          ),
        );
        if (!widget.interactive) return painted;

        return GestureDetector(
          key: const Key('line_chart_touch_area'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _selectAt(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _selectAt(d.localPosition.dx, constraints.maxWidth),
          child: painted,
        );
      },
    );

    return Column(
      children: [
        SizedBox(height: widget.height, width: double.infinity, child: chart),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in widget.labels)
              Text(
                l,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  static const padX = 14.0;
  static const _padTop = 22.0;
  static const _padBottom = 8.0;

  final List<double> values;

  /// Texto do rótulo e ponto ao qual ele se refere.
  final String label;
  final int labelIndex;
  final int? selected;
  final Color lineColor;
  final Color gridColor;
  final Color dotColor;

  _LinePainter({
    required this.values,
    required this.label,
    required this.labelIndex,
    required this.selected,
    required this.lineColor,
    required this.gridColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final w = size.width - padX * 2;
    final h = size.height - _padTop - _padBottom;

    Offset point(int i) {
      final x = padX + (w * i / (values.length - 1));
      final y = _padTop + h - ((values[i] - minV) / range) * h;
      return Offset(x, y);
    }

    // linhas de grade
    final grid = Paint()
      ..color = gridColor.withAlpha(120)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = _padTop + h * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = [for (var i = 0; i < values.length; i++) point(i)];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withAlpha(70), lineColor.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // guia vertical do ponto selecionado
    final selectedIndex = selected;
    if (selectedIndex != null) {
      final x = pts[selectedIndex].dx;
      canvas.drawLine(
        Offset(x, _padTop - 4),
        Offset(x, size.height),
        Paint()
          ..color = lineColor.withAlpha(110)
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < pts.length; i++) {
      final big = i == selectedIndex;
      canvas.drawCircle(pts[i], big ? 7 : 5, Paint()..color = dotColor);
      canvas.drawCircle(pts[i], big ? 5 : 3.5, Paint()..color = lineColor);
    }

    // rótulo do ponto selecionado (ou do último valor), sempre no topo
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: lineColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final anchor = pts[labelIndex];
    final dx = (anchor.dx - tp.width / 2)
        .clamp(0.0, math.max(0.0, size.width - tp.width))
        .toDouble();
    final dy = selectedIndex == null ? math.max(0.0, anchor.dy - 22) : 0.0;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values ||
      old.label != label ||
      old.selected != selected ||
      old.lineColor != lineColor;
}
