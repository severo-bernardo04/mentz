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
