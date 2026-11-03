import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';

enum AnatomyViewType { anterior, posterior }

enum MuscleRole {
  primary('Músculo Principal', Color(0xFFD32F2F)), // Vermelho
  highActivation('Alta Ativação', Color(0xFFF57C00)), // Laranja
  secondary('Músculo Secundário', Color(0xFFFBC02D)), // Amarelo
  none('Inativo', Color(0xFF9E9E9E));

  final String label;
  final Color color;
  const MuscleRole(this.label, this.color);
}

/// Helper para identificar o papel anatômico de cada região muscular para um exercício.
class MuscleActivationResolver {
  static final Map<String, List<String>> _regionAliases = {
    'chest': ['peito', 'peitoral'],
    'shoulders': ['ombro', 'deltoid'],
    'biceps': ['bíceps', 'biceps', 'braquial'],
    'triceps': ['tríceps', 'triceps'],
    'forearms': ['antebraço', 'antebraco', 'braquiorradial'],
    'back': ['costa', 'dorsal', 'redondo maior', 'romboide'],
    'traps': ['trapézio', 'trapezio'],
    'abs': ['abdômen', 'abdomen', 'oblíquo', 'obliquo', 'core', 'transverso'],
    'lowerBack': ['lombar', 'ereto da espinha'],
    'quads': ['quadríceps', 'quadriceps', 'vasto', 'reto femoral'],
    'hamstrings': ['posterior', 'isquiotibiais', 'isquiotibial', 'bíceps femoral'],
    'glutes': ['glúteo', 'gluteo', 'glúteos', 'gluteos'],
    'calves': ['panturrilha', 'gastrocnêmio', 'gastrocnemio', 'sóleo', 'soleo'],
  };

  static MuscleRole getRole(Exercise exercise, String regionKey) {
    final aliases = _regionAliases[regionKey] ?? [];

    bool check(String text) {
      final t = text.toLowerCase();
      return aliases.any((a) => t.contains(a.toLowerCase()));
    }

    bool checkList(List<String> list) {
      return list.any(check);
    }

    // 1. Verifica se é o músculo principal (Vermelho)
    if (exercise.primaryMuscle != null && check(exercise.primaryMuscle!)) {
      return MuscleRole.primary;
    }
    if (exercise.muscle.isNotEmpty && check(exercise.muscle)) {
      return MuscleRole.primary;
    }

    // 2. Verifica se é alta ativação (Laranja)
    if (checkList(exercise.highActivationMuscles)) {
      return MuscleRole.highActivation;
    }

    // 3. Verifica se é músculo secundário (Amarelo)
    if (checkList(exercise.secondaryMuscles)) {
      return MuscleRole.secondary;
    }

    return MuscleRole.none;
  }
}

/// Painter vetorial que desenha o modelo anatômico do corpo humano (Anterior ou Posterior)
/// com destaque fiel para cada grupamento muscular conforme seu nível de ativação.
class MuscleAnatomyPainter extends CustomPainter {
  final Exercise exercise;
  final AnatomyViewType viewType;
  final Color baseColor;
  final Color borderColor;

  MuscleAnatomyPainter({
    required this.exercise,
    required this.viewType,
    required this.baseColor,
    required this.borderColor,
  });

  Color _resolveColor(String regionKey) {
    final role = MuscleActivationResolver.getRole(exercise, regionKey);
    if (role != MuscleRole.none) {
      return role.color;
    }
    return baseColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 200;
    final scaleY = size.height / 360;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    if (viewType == AnatomyViewType.anterior) {
      _drawAnteriorView(canvas);
    } else {
      _drawPosteriorView(canvas);
    }

    canvas.restore();
  }

  void _drawAnteriorView(Canvas canvas) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void drawPart(String regionKey, Path path) {
      final fillPaint = Paint()
        ..color = _resolveColor(regionKey)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Cabeça e Pescoço (Neutro)
    final headPath = Path()
      ..addOval(const Rect.fromLTWH(86, 12, 28, 34))
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(92, 44, 16, 14), const Radius.circular(4)));
    canvas.drawPath(
        headPath,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(headPath, borderPaint);

    // Trapézio (Superior frontal)
    final traps = Path()
      ..moveTo(88, 48)
      ..lineTo(76, 56)
      ..lineTo(92, 56)
      ..close()
      ..moveTo(112, 48)
      ..lineTo(124, 56)
      ..lineTo(108, 56)
      ..close();
    drawPart('traps', traps);

    // Ombros / Deltoides anteriores e laterais
    final leftShoulder = Path()
      ..moveTo(74, 56)
      ..quadraticBezierTo(58, 62, 60, 80)
      ..quadraticBezierTo(70, 82, 74, 70)
      ..close();
    drawPart('shoulders', leftShoulder);

    final rightShoulder = Path()
      ..moveTo(126, 56)
      ..quadraticBezierTo(142, 62, 140, 80)
      ..quadraticBezierTo(130, 82, 126, 70)
      ..close();
    drawPart('shoulders', rightShoulder);

    // Peitoral (Esquerdo e Direito)
    final chest = Path()
      ..moveTo(98, 58)
      ..lineTo(74, 58)
      ..quadraticBezierTo(72, 86, 98, 90)
      ..close()
      ..moveTo(102, 58)
      ..lineTo(126, 58)
      ..quadraticBezierTo(128, 86, 102, 90)
      ..close();
    drawPart('chest', chest);

    // Bíceps
    final leftBiceps = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 80, 14, 30), const Radius.circular(6)));
    drawPart('biceps', leftBiceps);

    final rightBiceps = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(128, 80, 14, 30), const Radius.circular(6)));
    drawPart('biceps', rightBiceps);

    // Antebraços
    final leftForearm = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 112, 15, 38), const Radius.circular(7)));
    drawPart('forearms', leftForearm);

    final rightForearm = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(131, 112, 15, 38), const Radius.circular(7)));
    drawPart('forearms', rightForearm);

    // Mãos (Neutro)
    final hands = Path()
      ..addOval(const Rect.fromLTWH(55, 152, 12, 14))
      ..addOval(const Rect.fromLTWH(133, 152, 12, 14));
    canvas.drawPath(
        hands,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(hands, borderPaint);

    // Abdômen e Oblíquos (Core)
    final abs = Path()
      ..moveTo(76, 92)
      ..lineTo(124, 92)
      ..lineTo(120, 148)
      ..lineTo(80, 148)
      ..close();
    drawPart('abs', abs);

    // Quadril / Pélvis (Neutro)
    final pelvis = Path()
      ..moveTo(79, 148)
      ..lineTo(121, 148)
      ..lineTo(112, 168)
      ..lineTo(88, 168)
      ..close();
    canvas.drawPath(
        pelvis,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(pelvis, borderPaint);

    // Quadríceps (Coxa Anterior)
    final leftQuad = Path()
      ..moveTo(80, 168)
      ..lineTo(98, 168)
      ..quadraticBezierTo(100, 225, 96, 240)
      ..quadraticBezierTo(74, 235, 76, 175)
      ..close();
    drawPart('quads', leftQuad);

    final rightQuad = Path()
      ..moveTo(102, 168)
      ..lineTo(120, 168)
      ..quadraticBezierTo(124, 175, 124, 235)
      ..quadraticBezierTo(100, 240, 104, 225)
      ..close();
    drawPart('quads', rightQuad);

    // Joelhos (Neutro)
    final knees = Path()
      ..addOval(const Rect.fromLTWH(82, 240, 13, 12))
      ..addOval(const Rect.fromLTWH(105, 240, 13, 12));
    canvas.drawPath(
        knees,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(knees, borderPaint);

    // Panturrilhas / Canelas
    final leftCalf = Path()
      ..moveTo(82, 252)
      ..lineTo(95, 252)
      ..quadraticBezierTo(94, 305, 90, 325)
      ..quadraticBezierTo(77, 290, 82, 252)
      ..close();
    drawPart('calves', leftCalf);

    final rightCalf = Path()
      ..moveTo(105, 252)
      ..lineTo(118, 252)
      ..quadraticBezierTo(123, 290, 110, 325)
      ..quadraticBezierTo(106, 305, 105, 252)
      ..close();
    drawPart('calves', rightCalf);

    // Pés (Neutro)
    final feet = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(82, 325, 14, 18), const Radius.circular(5)))
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(104, 325, 14, 18), const Radius.circular(5)));
    canvas.drawPath(
        feet,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(feet, borderPaint);
  }

  void _drawPosteriorView(Canvas canvas) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void drawPart(String regionKey, Path path) {
      final fillPaint = Paint()
        ..color = _resolveColor(regionKey)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Cabeça e Pescoço (Posterior)
    final headPath = Path()
      ..addOval(const Rect.fromLTWH(86, 12, 28, 34))
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(92, 44, 16, 14), const Radius.circular(4)));
    canvas.drawPath(
        headPath,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(headPath, borderPaint);

    // Trapézio (Superior e Médio)
    final traps = Path()
      ..moveTo(92, 46)
      ..lineTo(108, 46)
      ..lineTo(122, 60)
      ..lineTo(100, 85)
      ..lineTo(78, 60)
      ..close();
    drawPart('traps', traps);

    // Ombros / Deltoides Posteriores
    final leftShoulder = Path()
      ..moveTo(76, 58)
      ..quadraticBezierTo(60, 64, 60, 82)
      ..quadraticBezierTo(72, 82, 76, 72)
      ..close();
    drawPart('shoulders', leftShoulder);

    final rightShoulder = Path()
      ..moveTo(124, 58)
      ..quadraticBezierTo(140, 64, 140, 82)
      ..quadraticBezierTo(128, 82, 124, 72)
      ..close();
    drawPart('shoulders', rightShoulder);

    // Grande Dorsal (Costas / Lats)
    final lats = Path()
      ..moveTo(76, 70)
      ..lineTo(100, 85)
      ..lineTo(124, 70)
      ..lineTo(120, 118)
      ..lineTo(80, 118)
      ..close();
    drawPart('back', lats);

    // Tríceps (Braço posterior)
    final leftTriceps = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 80, 14, 30), const Radius.circular(6)));
    drawPart('triceps', leftTriceps);

    final rightTriceps = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(128, 80, 14, 30), const Radius.circular(6)));
    drawPart('triceps', rightTriceps);

    // Antebraços Posteriores
    final leftForearm = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 112, 15, 38), const Radius.circular(7)));
    drawPart('forearms', leftForearm);

    final rightForearm = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(131, 112, 15, 38), const Radius.circular(7)));
    drawPart('forearms', rightForearm);

    // Mãos (Posterior)
    final hands = Path()
      ..addOval(const Rect.fromLTWH(55, 152, 12, 14))
      ..addOval(const Rect.fromLTWH(133, 152, 12, 14));
    canvas.drawPath(
        hands,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(hands, borderPaint);

    // Lombar (Lower Back)
    final lowerBack = Path()
      ..moveTo(80, 118)
      ..lineTo(120, 118)
      ..lineTo(116, 144)
      ..lineTo(84, 144)
      ..close();
    drawPart('lowerBack', lowerBack);

    // Glúteos
    final glutes = Path()
      ..moveTo(82, 144)
      ..lineTo(118, 144)
      ..quadraticBezierTo(124, 168, 115, 185)
      ..lineTo(100, 185)
      ..lineTo(85, 185)
      ..quadraticBezierTo(76, 168, 82, 144)
      ..close();
    drawPart('glutes', glutes);

    // Isquiotibiais / Posterior de Coxa
    final leftHamstrings = Path()
      ..moveTo(82, 185)
      ..lineTo(98, 185)
      ..quadraticBezierTo(97, 235, 94, 240)
      ..quadraticBezierTo(78, 235, 80, 195)
      ..close();
    drawPart('hamstrings', leftHamstrings);

    final rightHamstrings = Path()
      ..moveTo(102, 185)
      ..lineTo(118, 185)
      ..quadraticBezierTo(122, 195, 120, 235)
      ..quadraticBezierTo(103, 235, 106, 240)
      ..close();
    drawPart('hamstrings', rightHamstrings);

    // Fossa poplítea / Joelhos posteriores (Neutro)
    final popliteal = Path()
      ..addOval(const Rect.fromLTWH(82, 240, 13, 12))
      ..addOval(const Rect.fromLTWH(105, 240, 13, 12));
    canvas.drawPath(
        popliteal,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(popliteal, borderPaint);

    // Panturrilhas / Gastrocnêmio
    final leftCalf = Path()
      ..moveTo(82, 252)
      ..lineTo(95, 252)
      ..quadraticBezierTo(96, 285, 90, 325)
      ..quadraticBezierTo(76, 285, 82, 252)
      ..close();
    drawPart('calves', leftCalf);

    final rightCalf = Path()
      ..moveTo(105, 252)
      ..lineTo(118, 252)
      ..quadraticBezierTo(124, 285, 110, 325)
      ..quadraticBezierTo(104, 285, 105, 252)
      ..close();
    drawPart('calves', rightCalf);

    // Pés posteriores (Calcanhar)
    final feet = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(82, 325, 14, 18), const Radius.circular(5)))
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(104, 325, 14, 18), const Radius.circular(5)));
    canvas.drawPath(
        feet,
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(feet, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MuscleAnatomyPainter oldDelegate) {
    return oldDelegate.exercise != exercise ||
        oldDelegate.viewType != viewType ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.borderColor != borderColor;
  }
}
