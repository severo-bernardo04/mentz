import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gráfico de linha simples (sem dependências externas).
class SimpleLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String unit;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.unit = '',
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              values: values,
              unit: unit,
              lineColor: cs.primary,
              gridColor: cs.outlineVariant,
              textColor: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
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
  final List<double> values;
  final String unit;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _LinePainter({
    required this.values,
    required this.unit,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const padX = 14.0;
    const padTop = 18.0;
    const padBottom = 8.0;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final w = size.width - padX * 2;
    final h = size.height - padTop - padBottom;

    Offset point(int i) {
      final x = padX + (w * i / (values.length - 1));
      final y = padTop + h - ((values[i] - minV) / range) * h;
      return Offset(x, y);
    }

    // linhas de grade
    final grid = Paint()
      ..color = gridColor.withAlpha(120)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padTop + h * i / 2;
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

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (final p in pts) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3.5, Paint()..color = lineColor);
    }

    // rótulo do último valor
    final tp = TextPainter(
      text: TextSpan(
        text: '${values.last.toStringAsFixed(1)}$unit',
        style: TextStyle(
          color: lineColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final last = pts.last;
    final dx = math.min(last.dx - tp.width / 2, size.width - tp.width);
    tp.paint(canvas, Offset(math.max(0, dx), math.max(0, last.dy - 22)));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.lineColor != lineColor;
}