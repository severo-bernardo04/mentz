import 'package:flutter/material.dart';
import 'package:muscle_mapper/muscle_mapper.dart';

import '../models/profile_models.dart';
import '../services/muscle_analysis_service.dart';

/// Ligação entre os grupamentos da pontuação muscular e as regiões do boneco
/// da biblioteca `muscle_mapper` (nível `MuscleGroup` dela).
abstract final class MuscleMapperGroups {
  /// Regiões do boneco de cada grupamento do [MuscleAnalysisService].
  static const byGroup = <String, Set<MuscleGroup>>{
    'Peito': {MuscleGroup.chest},
    'Costas': {MuscleGroup.lats, MuscleGroup.lowerBack},
    'Trapézio': {MuscleGroup.traps},
    'Ombros': {MuscleGroup.deltoids},
    'Bíceps': {MuscleGroup.biceps},
    'Tríceps': {MuscleGroup.triceps},
    'Antebraço': {MuscleGroup.forearms},
    'Abdômen': {MuscleGroup.abs, MuscleGroup.obliques},
    'Quadríceps': {MuscleGroup.quads},
    'Posterior de coxa': {MuscleGroup.hamstrings},
    'Glúteos': {MuscleGroup.glutes},
    'Panturrilha': {MuscleGroup.calves},
  };

  /// Músculos do boneco que acendem para [group]; vazio se o grupamento
  /// não tem região no boneco (ex: um músculo fora da lista conhecida).
  static Set<Muscle> musclesOf(String group) => {
        for (final region in byGroup[group] ?? const <MuscleGroup>{})
          ...region.subMuscles,
      };

  /// Músculos citados pelo nome com precisão maior que o grupamento (ex:
  /// "Deltoide posterior" acende só a parte de trás do ombro). A ordem
  /// importa: os nomes mais específicos vêm primeiro.
  static const _byName = <String, Set<Muscle>>{
    'deltoide anterior': {Muscle.anteriorDeltoid},
    'deltoide lateral': {Muscle.lateralDeltoid},
    'deltoide medial': {Muscle.lateralDeltoid},
    'deltoide posterior': {Muscle.posteriorDeltoid},
    'peitoral superior': {Muscle.upperPectoralis},
    'bíceps (cabeça curta)': {Muscle.shortHeadBicep},
    'bíceps (cabeça longa)': {Muscle.longHeadBicep},
    'braquiorradial': {Muscle.wristExtensors},
    'grande dorsal': {Muscle.lats},
    'redondo maior': {Muscle.lats},
    'romboide': {Muscle.trapsMiddle},
    'lombar': {Muscle.lowerBack},
    'oblíquo': {Muscle.obliques},
    'sóleo': {Muscle.soleus},
    'gastrocnêmio': {Muscle.gastrocnemius},
    'glúteo médio': {Muscle.gluteusMedius},
    'glúteo máximo': {Muscle.gluteusMaximus},
    'reto femoral': {Muscle.rectusFemoris},
  };

  /// Regiões do boneco do músculo [name], como está cadastrado no catálogo.
  /// Sem um nome específico conhecido, acende o grupamento inteiro.
  static Set<Muscle> musclesOfName(String name) {
    final lower = name.trim().toLowerCase();
    for (final entry in _byName.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return musclesOf(MuscleAnalysisService.groupOf(name));
  }

  /// Papel mais forte de cada região do boneco no exercício [exercise]
  /// (principal > alta ativação > secundário), a partir dos músculos
  /// cadastrados no catálogo.
  static Map<Muscle, MuscleRole> rolesOf(Exercise exercise) {
    final roles = <Muscle, MuscleRole>{};
    for (final c in MuscleAnalysisService.contributionsOf(exercise)) {
      for (final muscle in musclesOfName(c.muscle)) {
        final current = roles[muscle];
        // O enum está em ordem de força: primary vem antes
        if (current == null || c.role.index < current.index) {
          roles[muscle] = c.role;
        }
      }
    }
    return roles;
  }

  /// Grupamento ao qual pertence a região [muscle] tocada no boneco.
  static String? groupOf(Muscle muscle) {
    for (final entry in byGroup.entries) {
      if (entry.value.contains(muscle.group)) return entry.key;
    }
    return null;
  }

  /// Intensidade (opacidade de 0 a 1) de cada músculo do boneco: o
  /// grupamento mais pontuado fica com cor cheia e os demais proporcionais,
  /// com um mínimo para que mesmo o menos trabalhado continue visível.
  static Map<Muscle, double> intensitiesOf(List<MuscleScore> scores) {
    final top = scores.fold(0, (max, s) => s.points > max ? s.points : max);
    if (top == 0) return const {};

    return {
      for (final score in scores)
        for (final muscle in musclesOf(score.group))
          muscle: 0.25 + 0.75 * (score.points / top),
    };
  }
}

/// Boneco anatômico (frente e costas) com os grupamentos pintados conforme a
/// pontuação muscular: quanto mais pontos, mais forte a cor. Tocar em um
/// músculo chama [onGroupTap] com a pontuação do grupamento dele.
///
/// Usa o pacote `muscle_mapper` com o estilo `minimal`, o único que tem
/// boneco feminino. Os desenhos vêm do próprio pacote (sem rede).
class MuscleBodyMap extends StatelessWidget {
  final List<MuscleScore> scores;

  /// Usa o boneco feminino (o perfil informa o sexo biológico).
  final bool female;

  /// Toque em um grupamento pontuado; músculos sem pontos são ignorados.
  final ValueChanged<MuscleScore>? onGroupTap;

  final double height;

  const MuscleBodyMap({
    super.key,
    required this.scores,
    this.female = false,
    this.onGroupTap,
    this.height = 240,
  });

  void _onMuscleTapped(Muscle muscle) {
    final group = MuscleMapperGroups.groupOf(muscle);
    if (group == null) return;

    for (final score in scores) {
      if (score.group == group) {
        onGroupTap?.call(score);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final intensities = MuscleMapperGroups.intensitiesOf(scores);
    final gender = female ? AnatomyGender.female : AnatomyGender.male;

    Widget body(AnatomyView view, String label) => Expanded(
          child: Column(
            children: [
              SizedBox(
                height: height,
                child: MuscleMapper(
                  key: Key('muscle_body_map_${view.name}'),
                  gender: gender,
                  view: view,
                  assetProvider: const DefaultAnatomyProvider(
                    style: AnatomyStyle.minimal,
                  ),
                  activeMuscles: intensities.keys.toSet(),
                  muscleIntensities: intensities,
                  highlightColor: cs.primary,
                  baseColor: cs.onSurfaceVariant,
                  onMuscleTapped: onGroupTap == null ? null : _onMuscleTapped,
                  // Sem animação infinita enquanto o desenho carrega
                  loadingWidget: const SizedBox.shrink(),
                  onError: (_) {},
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        body(AnatomyView.front, 'Frente'),
        const SizedBox(width: 8),
        body(AnatomyView.back, 'Costas'),
      ],
    );
  }
}
