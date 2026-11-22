import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/bmi_info.dart';

void main() {
  group('BmiResult.calculate - Padrão Adulto', () {
    test('retorna null se altura ou peso forem nulos ou inválidos', () {
      expect(BmiResult.calculate(weightKg: null, heightCm: 175), isNull);
      expect(BmiResult.calculate(weightKg: 70, heightCm: null), isNull);
      expect(BmiResult.calculate(weightKg: 0, heightCm: 175), isNull);
      expect(BmiResult.calculate(weightKg: -70, heightCm: 175), isNull);
      expect(BmiResult.calculate(weightKg: 70, heightCm: 0), isNull);
      expect(BmiResult.calculate(weightKg: 70, heightCm: -175), isNull);
    });

    test('classifica como Abaixo do peso (< 18.5)', () {
      final result = BmiResult.calculate(weightKg: 50, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.score, 16.3);
      expect(result.category, BmiCategory.underweight);
      expect(result.category.label, 'Abaixo do peso');
    });

    test('classifica como Peso normal (18.5 a 24.9)', () {
      final result = BmiResult.calculate(weightKg: 70, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.score, 22.9);
      expect(result.category, BmiCategory.normal);
      expect(result.category.label, 'Peso normal');
    });

    test('classifica como Sobrepeso (25.0 a 29.9)', () {
      final result = BmiResult.calculate(weightKg: 80, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.score, 26.1);
      expect(result.category, BmiCategory.overweight);
      expect(result.category.label, 'Sobrepeso');
    });

    test('classifica como Obesidade Grau I (30.0 a 34.9)', () {
      final result = BmiResult.calculate(weightKg: 95, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.score, 31.0);
      expect(result.category, BmiCategory.obesityClass1);
    });

    test('calcula a faixa de peso ideal corretamente para a altura', () {
      final result = BmiResult.calculate(weightKg: 70, heightCm: 175);
      expect(result, isNotNull);
      expect(result!.minIdealWeight, 56.7);
      expect(result.maxIdealWeight, 76.3);
      expect(result.idealWeightLabel, '56.7 kg – 76.3 kg');
    });
  });

  group('BmiResult.calculate - Critérios de Idosos (Lipschitz 1994)', () {
    test('idoso com IMC 21.5 é classificado como baixo peso (< 22.0)', () {
      // 170 cm, 62 kg => 62 / 1.7^2 = 21.5
      final result = BmiResult.calculate(
        weightKg: 62,
        heightCm: 170,
        age: 68,
      );
      expect(result, isNotNull);
      expect(result!.isElderlyCriteria, isTrue);
      expect(result.category, BmiCategory.underweight);
    });

    test('idoso com IMC 24.0 está em eutrofia / normal (22.0 a 27.0)', () {
      // 170 cm, 70 kg => 70 / 1.7^2 = 24.2
      final result = BmiResult.calculate(
        weightKg: 70,
        heightCm: 170,
        age: 72,
      );
      expect(result, isNotNull);
      expect(result!.isElderlyCriteria, isTrue);
      expect(result.category, BmiCategory.normal);
      // Faixa ideal de Lipschitz: 22.0 * 2.89 = 63.6 kg a 27.0 * 2.89 = 78.0 kg
      expect(result.minIdealWeight, 63.6);
      expect(result.maxIdealWeight, 78.0);
    });
  });

  group('BmiResult.calculate - Fórmula de Deurenberg (% de Gordura Corporal)', () {
    test('calcula % de gordura para homem adulto', () {
      // Homem, 25 anos, IMC 22.9
      // BF = (1.20 * 22.857) + (0.23 * 25) - (10.8 * 1) - 5.4 = 27.428 + 5.75 - 10.8 - 5.4 = 16.978 => 17.0%
      final result = BmiResult.calculate(
        weightKg: 70,
        heightCm: 175,
        age: 25,
        sex: BiologicalSex.male,
      );
      expect(result, isNotNull);
      expect(result!.bodyFatPercentage, 17.0);
      expect(result.bodyFatCategory, 'Fitness (ACE)');
      expect(result.profileContextDescription, 'Homem • 25 anos');
    });

    test('calcula % de gordura para mulher adulta com mesmo IMC', () {
      // Mulher, 25 anos, IMC 22.9
      // BF = (1.20 * 22.857) + (0.23 * 25) - (10.8 * 0) - 5.4 = 27.428 + 5.75 - 5.4 = 27.778 => 27.8%
      final result = BmiResult.calculate(
        weightKg: 70,
        heightCm: 175,
        age: 25,
        sex: BiologicalSex.female,
      );
      expect(result, isNotNull);
      expect(result!.bodyFatPercentage, 27.8);
      expect(result.bodyFatCategory, 'Moderado (ACE)');
      expect(result.profileContextDescription, 'Mulher • 25 anos');
    });

    test('validação dos dados do usuário (160 cm, 80 kg, 23 anos, masculino)', () {
      final result = BmiResult.calculate(
        weightKg: 80,
        heightCm: 160,
        age: 23,
        sex: BiologicalSex.male,
      );
      expect(result, isNotNull);
      expect(result!.score, 31.3);
      expect(result.category, BmiCategory.obesityClass1);
      expect(result.minIdealWeight, 47.4);
      expect(result.maxIdealWeight, 63.7);
      expect(result.idealWeightLabel, '47.4 kg – 63.7 kg');
      expect(result.bodyFatPercentage, 26.6);
      expect(result.bodyFatCategory, 'Elevado (ACE)');
    });
  });
}
