import 'package:flutter/material.dart';

import '../../../services/muscle_analysis_service.dart';
import '../../../services/settings_service.dart';
import '../../../widgets/muscle_body_map.dart';

/// Abre a pontuação muscular em uma folha (ex: a da planilha inteira).
Future<void> showMuscleScoreSheet(
  BuildContext context, {
  required String title,
  required List<MuscleScore> scores,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);

      return SafeArea(
        child: ConstrainedBox(
          // Deixa o topo da tela visível mesmo com muitos grupamentos
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pontuação muscular',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: scores.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Nenhum exercício cadastrado ainda.'),
                          )
                        : MuscleScoreOverview(scores: scores),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Abre os exercícios que compõem a pontuação de um grupamento.
Future<void> showMuscleScoreDetails(BuildContext context, MuscleScore score) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _MuscleScoreSheet(score),
  );
}

/// Pontuação muscular completa: o boneco anatômico pintado conforme os
/// pontos e, abaixo, a lista por grupamento. Tocar em um músculo do boneco
/// ou em uma linha da lista abre os exercícios daquele grupamento.
class MuscleScoreOverview extends StatelessWidget {
  final List<MuscleScore> scores;

  const MuscleScoreOverview({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuscleBodyMap(
          scores: scores,
          // Boneco masculino ou feminino conforme o sexo do perfil
          female: SettingsService().femaleBody,
          onGroupTap: (score) => showMuscleScoreDetails(context, score),
        ),
        const SizedBox(height: 12),
        MuscleScoreList(scores: scores),
      ],
    );
  }
}

/// Pontuação muscular do treino: um grupamento por linha, do mais para o
/// menos trabalhado, com uma barra proporcional aos pontos. Tocar em um
/// grupamento lista os exercícios que compõem a ativação dele.
class MuscleScoreList extends StatelessWidget {
  final List<MuscleScore> scores;

  const MuscleScoreList({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // A lista vem ordenada: o primeiro tem a maior pontuação
    final top = scores.isEmpty ? 1 : scores.first.points;

    return Column(
      children: [
        for (final score in scores)
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: Key('muscle_score_${score.group}'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => showMuscleScoreDetails(context, score),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(
                        score.group,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: score.points / top,
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${score.points}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Exercícios do treino que compõem a ativação de um grupamento, com o
/// músculo, o papel dele no exercício e os pontos.
class _MuscleScoreSheet extends StatelessWidget {
  final MuscleScore score;

  const _MuscleScoreSheet(this.score);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${score.group}  •  ${score.points} pontos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Principal vale 3, alta ativação 2 e secundário 1.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in score.contributions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        c.exerciseName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          ?c.dayName,
                          c.muscle,
                          c.role.label,
                        ].join('  •  '),
                      ),
                      trailing: Text(
                        '+${c.points}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
