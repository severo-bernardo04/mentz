import 'package:flutter/material.dart';

/// Cor usada para indicar treino não 100% aproveitado.
const incompleteColor = Color(0xFFEF6C00); // Laranja

/// Faixa que indica treino não 100% aproveitado. Tocar abre os pendentes.
/// Usada na tela do treino (atual ou anterior) e nos Detalhes do Treino.
class IncompleteWorkoutBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;
  final String title;

  /// Chave da área de toque, para localizar a faixa nos testes.
  final Key tapKey;

  const IncompleteWorkoutBanner({
    super.key,
    required this.pendingCount,
    required this.onTap,
    this.title = 'Treino não 100% aproveitado',
    this.tapKey = const Key('incomplete_workout_banner'),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final label = pendingCount == 1
        ? '1 exercício pendente'
        : '$pendingCount exercícios pendentes';

    return Material(
      color: incompleteColor.withAlpha(30),
      borderRadius: radius,
      child: InkWell(
        key: tapKey,
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: incompleteColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: incompleteColor,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: incompleteColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: incompleteColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista os exercícios pendentes ([names], com a posição no treino em
/// [indexes]).
///
/// - [onComplete]: cada exercício ganha o botão COMPLETAR, que fecha a lista
///   e devolve a posição dele (usado com o cronômetro rodando).
/// - [onCompleteAll] e [onIgnore]: botões no rodapé para completar ou ignorar
///   os pendentes de um treino anterior.
Future<void> showPendingExercisesSheet(
  BuildContext context, {
  required List<String> names,
  required List<int> indexes,
  String? subtitle,
  ValueChanged<int>? onComplete,
  VoidCallback? onCompleteAll,
  VoidCallback? onIgnore,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);

      /// Fecha a lista e só então executa a ação escolhida.
      void closeAnd(VoidCallback action) {
        Navigator.of(context).pop();
        action();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exercícios pendentes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < names.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: incompleteColor.withAlpha(40),
                          child: Text(
                            '${indexes[i] + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: incompleteColor,
                            ),
                          ),
                        ),
                        title: Text(names[i]),
                        trailing: onComplete == null
                            ? null
                            : FilledButton.tonal(
                                onPressed: () =>
                                    closeAnd(() => onComplete(indexes[i])),
                                child: const Text('COMPLETAR'),
                              ),
                      ),
                  ],
                ),
              ),
              if (onCompleteAll != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('complete_previous_button'),
                  onPressed: () => closeAnd(onCompleteAll),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('COMPLETAR'),
                ),
              ],
              if (onIgnore != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  key: const Key('ignore_previous_button'),
                  onPressed: () => closeAnd(onIgnore),
                  child: const Text('IGNORAR'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
