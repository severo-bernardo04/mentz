import 'package:flutter/material.dart';

import '../../../models/profile_models.dart';

/// Tabela em formato de planilha (estilo Excel) para comparar o histórico de execuções de um treino.
class SpreadsheetDataTable extends StatelessWidget {
  final List<CompletedWorkout> sessions;
  final String dayName;

  const SpreadsheetDataTable({
    super.key,
    required this.sessions,
    required this.dayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Estado vazio com ícone e textos maiores
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withAlpha(150),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma execução registrada para o $dayName.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Conclua este treino para acompanhar sua evolução aqui.',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Ordenar sessões da mais antiga para a mais recente nas colunas (evolução temporal da esquerda para a direita)
    final chronologicalSessions = List<CompletedWorkout>.from(sessions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Coletar lista única de exercícios executados nesse treino ao longo do tempo
    final exerciseNames = <String>[];
    for (final s in chronologicalSessions) {
      for (final ex in s.executedExercises) {
        if (!exerciseNames.contains(ex.name)) {
          exerciseNames.add(ex.name);
        }
      }
    }

    final headerStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: cs.onPrimaryContainer,
    );

    // Rolagem vertical + horizontal: a tabela cresce em linhas (exercícios)
    // e em colunas (datas) sem estourar a área disponível da tela.
    // LayoutBuilder lê a largura disponível: a tabela ocupa no mínimo a tela inteira
    // e, se tiver mais datas do que cabem, fica mais larga e rola para o lado.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.outlineVariant.withAlpha(120)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(cs.primaryContainer),
                  headingRowHeight: 68,
                  // Margem horizontal igual em todas as células: 14 nas bordas da tabela
                  // e 14 de cada lado das linhas divisórias (columnSpacing = 2 × horizontalMargin)
                  horizontalMargin: 14,
                  columnSpacing: 28,
                  // Altura da linha acompanha o conteúdo (nº de séries), sem sobra em cima e embaixo
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: double.infinity,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: cs.outlineVariant.withAlpha(80),
                    ),
                    verticalInside: BorderSide(
                      color: cs.outlineVariant.withAlpha(80),
                    ),
                  ),
                  columns: [
                    // flex igual em todas as colunas: a largura que sobra na tela é
                    // dividida por igual, sem concentrar o espaço em uma coluna só
                    DataColumn(
                      columnWidth: const IntrinsicColumnWidth(flex: 1),
                      label: Text('Exercício', style: headerStyle),
                    ),
                    for (final s in chronologicalSessions)
                      DataColumn(
                        columnWidth: const IntrinsicColumnWidth(flex: 1),
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDate(s.date), style: headerStyle),
                            const SizedBox(height: 2),
                            Text(
                              '${s.minutes} min  •  ${s.weekdayName.substring(0, 3)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: cs.onPrimaryContainer.withAlpha(210),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  rows: [
                    for (var i = 0; i < exerciseNames.length; i++)
                      DataRow(
                        // Linhas zebradas para facilitar o acompanhamento horizontal
                        color: WidgetStatePropertyAll(
                          i.isOdd
                              ? cs.surfaceContainerHighest.withAlpha(70)
                              : Colors.transparent,
                        ),
                        cells: [
                          DataCell(
                            // Largura se adapta ao nome: nomes curtos encolhem a coluna,
                            // nomes longos quebram linha a partir de 170
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 170),
                              child: Text(
                                exerciseNames[i],
                                // Mede pela linha mais longa, sem ocupar os 170 inteiros ao quebrar
                                textWidthBasis: TextWidthBasis.longestLine,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          for (final s in chronologicalSessions)
                            DataCell(
                              _buildExerciseExecutionCell(
                                context,
                                s.executedExercises.firstWhere(
                                  (e) => e.name == exerciseNames[i],
                                  orElse: () =>
                                      const ExecutedExercise(name: ''),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Célula de um exercício em uma data: lista as séries (S1, S2...) com carga × reps,
  /// ou uma etiqueta de "Não concluído", ou um traço quando o exercício não foi feito.
  Widget _buildExerciseExecutionCell(
    BuildContext context,
    ExecutedExercise exercise,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (exercise.name.isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
      );
    }

    if (!exercise.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTag('Não concluído', Colors.deepOrange),
          if (exercise.sets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${exercise.sets.first.load} × ${exercise.sets.first.reps}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      );
    }

    // Coluna com mainAxisSize.min: ocupa só a altura das séries, com um respiro pequeno
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final set in exercise.sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Número da série em um "badge" com a cor do tipo da série
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: set.type.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'S${set.setNumber}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: set.type.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${set.load} × ${set.reps}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (set.isDropSet)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildTag('drop', dropSetColor),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Etiqueta pequena e arredondada usada para "Não concluído" e "drop".
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
