import 'package:flutter/material.dart';

/// Classificação do IMC segundo os padrões da Organização Mundial da Saúde (OMS)
/// e critérios de David A. Lipschitz (1994) para idosos.
enum BmiCategory {
  underweight('Abaixo do peso', Color(0xFF0284C7)),
  normal('Peso normal', Color(0xFF16A34A)),
  overweight('Sobrepeso', Color(0xFFEAB308)),
  obesityClass1('Obesidade Grau I', Color(0xFFF97316)),
  obesityClass2('Obesidade Grau II', Color(0xFFEA580C)),
  obesityClass3('Obesidade Grau III', Color(0xFFDC2626));

  final String label;
  final Color color;
  const BmiCategory(this.label, this.color);
}

/// Sexo biológico para aplicação de fórmulas fisiológicas (Deurenberg, TMB).
enum BiologicalSex {
  male('Masculino'),
  female('Feminino');

  final String label;
  const BiologicalSex(this.label);

  static BiologicalSex? tryParse(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase().trim();
    if (lower.startsWith('m') || lower == 'masculino' || lower == 'male') {
      return BiologicalSex.male;
    }
    if (lower.startsWith('f') || lower == 'feminino' || lower == 'female') {
      return BiologicalSex.female;
    }
    return null;
  }
}

/// Resultado consolidado do cálculo de IMC com suporte a idade e sexo biológico.
class BmiResult {
  /// Valor numérico do IMC, arredondado para 1 casa decimal (ex: 23.8).
  final double score;

  /// Categoria correspondente segundo a OMS ou Lipschitz.
  final BmiCategory category;

  /// Peso ideal mínimo recomendado para a altura informada.
  final double minIdealWeight;

  /// Peso ideal máximo recomendado para a altura informada.
  final double maxIdealWeight;

  /// Posição percentual normalizada (0.0 a 1.0) para posicionar o indicador na régua visual.
  final double gaugePosition;

  /// Idade em anos (se informada).
  final int? age;

  /// Sexo biológico (se informado).
  final BiologicalSex? sex;

  /// Percentual de gordura corporal estimado pela fórmula de Deurenberg et al. (1991):
  /// %BF = (1.20 * IMC) + (0.23 * Idade) - (10.8 * Sexo) - 5.4
  /// (Sexo: 1 para masculino, 0 para feminino).
  final double? bodyFatPercentage;

  /// Classificação do percentual de gordura (ACE / ACSM).
  final String? bodyFatCategory;

  /// Indica se foram aplicados os critérios geriátricos de Lipschitz (idade >= 60).
  final bool isElderlyCriteria;

  const BmiResult({
    required this.score,
    required this.category,
    required this.minIdealWeight,
    required this.maxIdealWeight,
    required this.gaugePosition,
    this.age,
    this.sex,
    this.bodyFatPercentage,
    this.bodyFatCategory,
    this.isElderlyCriteria = false,
  });

  /// Descrição formatada da faixa saudável para a altura do usuário.
  String get idealWeightLabel =>
      '${minIdealWeight.toStringAsFixed(1)} kg – ${maxIdealWeight.toStringAsFixed(1)} kg';

  /// Contexto amigável do perfil (ex: "Homem, 28 anos").
  String? get profileContextDescription {
    if (age == null && sex == null) return null;
    final sexStr = sex != null
        ? (sex == BiologicalSex.male ? 'Homem' : 'Mulher')
        : null;
    final ageStr = age != null ? '$age anos' : null;

    if (sexStr != null && ageStr != null) {
      return '$sexStr • $ageStr';
    }
    return sexStr ?? ageStr;
  }

  /// Arredonda um valor matemático para 1 casa decimal usando round-half-up,
  /// com tolerância para imprecisões binárias de ponto flutuante IEEE-754.
  static double _round1(double val) => (((val + 1e-9) * 10).roundToDouble()) / 10.0;

  /// Calcula o IMC e métricas complementares a partir dos dados corporais.
  /// Retorna `null` se qualquer valor fundamental for nulo, menor ou igual a zero.
  static BmiResult? calculate({
    double? weightKg,
    double? heightCm,
    int? age,
    BiologicalSex? sex,
  }) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg <= 0 || heightCm <= 0) return null;

    final heightM = heightCm / 100.0;
    final rawBmi = weightKg / (heightM * heightM);
    if (rawBmi.isNaN || rawBmi.isInfinite) return null;

    final score = _round1(rawBmi);
    final isElderly = age != null && age >= 60;

    final BmiCategory category;
    final double minIdeal;
    final double maxIdeal;

    if (isElderly) {
      // Critérios de David A. Lipschitz (1994) para idosos (>= 60 anos)
      // < 22.0: Baixo peso | 22.0 a 27.0: Eutrofia (Peso normal) | > 27.0: Sobrepeso
      minIdeal = _round1(22.0 * (heightM * heightM));
      maxIdeal = _round1(27.0 * (heightM * heightM));

      if (score < 22.0) {
        category = BmiCategory.underweight;
      } else if (score <= 27.0) {
        category = BmiCategory.normal;
      } else if (score < 30.0) {
        category = BmiCategory.overweight;
      } else if (score < 35.0) {
        category = BmiCategory.obesityClass1;
      } else if (score < 40.0) {
        category = BmiCategory.obesityClass2;
      } else {
        category = BmiCategory.obesityClass3;
      }
    } else {
      // Padrão OMS para adultos (18 a 59 anos)
      minIdeal = _round1(18.5 * (heightM * heightM));
      maxIdeal = _round1(24.9 * (heightM * heightM));

      if (score < 18.5) {
        category = BmiCategory.underweight;
      } else if (score < 25.0) {
        category = BmiCategory.normal;
      } else if (score < 30.0) {
        category = BmiCategory.overweight;
      } else if (score < 35.0) {
        category = BmiCategory.obesityClass1;
      } else if (score < 40.0) {
        category = BmiCategory.obesityClass2;
      } else {
        category = BmiCategory.obesityClass3;
      }
    }

    // Mapeamento visual para régua (faixa de 15.0 a 40.0)
    final clamped = score.clamp(15.0, 40.0);
    final gaugePos = (clamped - 15.0) / (40.0 - 15.0);

    // Estimativa de % de gordura pela Fórmula de Deurenberg et al. (1991)
    // Calculado sobre o rawBmi sem arredondamento prévio
    double? bodyFat;
    String? bodyFatCat;

    if (age != null && age >= 16 && sex != null) {
      final sexValue = sex == BiologicalSex.male ? 1.0 : 0.0;
      final rawBf = (1.20 * rawBmi) + (0.23 * age) - (10.8 * sexValue) - 5.4;
      if (rawBf > 0 && rawBf < 70) {
        bodyFat = _round1(rawBf);
        bodyFatCat = _classifyBodyFat(bodyFat, sex);
      }
    }

    return BmiResult(
      score: score,
      category: category,
      minIdealWeight: minIdeal,
      maxIdealWeight: maxIdeal,
      gaugePosition: gaugePos.clamp(0.0, 1.0),
      age: age,
      sex: sex,
      bodyFatPercentage: bodyFat,
      bodyFatCategory: bodyFatCat,
      isElderlyCriteria: isElderly,
    );
  }

  /// Classificação do percentual de gordura segundo o American Council on Exercise (ACE)
  static String _classifyBodyFat(double bf, BiologicalSex sex) {
    if (sex == BiologicalSex.male) {
      if (bf < 6.0) return 'Essencial (ACE)';
      if (bf < 14.0) return 'Atleta (ACE)';
      if (bf < 18.0) return 'Fitness (ACE)';
      if (bf < 25.0) return 'Moderado (ACE)';
      return 'Elevado (ACE)';
    } else {
      if (bf < 14.0) return 'Essencial (ACE)';
      if (bf < 21.0) return 'Atleta (ACE)';
      if (bf < 25.0) return 'Fitness (ACE)';
      if (bf < 32.0) return 'Moderado (ACE)';
      return 'Elevado (ACE)';
    }
  }
}
