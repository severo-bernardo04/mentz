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

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_chart_outlined, size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Nenhuma execução registrada para o $dayName.',
                style: TextStyle(color: cs.onSurfaceVariant),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withAlpha(120)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(cs.primaryContainer),
              horizontalMargin: 16,
              columnSpacing: 24,
              dataRowMinHeight: 70,
              dataRowMaxHeight: 120,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: cs.outlineVariant.withAlpha(60),
                ),
                verticalInside: BorderSide(
                  color: cs.outlineVariant.withAlpha(60),
                ),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Exercício',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                for (final s in chronologicalSessions)
                  DataColumn(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(s.date),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${s.minutes} min  •  ${s.weekdayName.substring(0, 3)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onPrimaryContainer.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              rows: [
                for (final name in exerciseNames)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      for (final s in chronologicalSessions)
                        DataCell(
                          _buildExerciseExecutionCell(
                            context,
                            s.executedExercises.firstWhere(
                              (e) => e.name == name,
                              orElse: () => const ExecutedExercise(name: ''),
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
    );
  }

  Widget _buildExerciseExecutionCell(
    BuildContext context,
    ExecutedExercise exercise,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (exercise.name.isEmpty) {
      return Text('—', style: TextStyle(color: cs.onSurfaceVariant));
    }

    if (!exercise.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Não concluído',
              style: TextStyle(
                color: Colors.deepOrange,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (exercise.sets.isNotEmpty)
            Text(
              '${exercise.sets.first.load} × ${exercise.sets.first.reps}',
              style: const TextStyle(fontSize: 11),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final set in exercise.sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'S${set.setNumber}: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    '${set.load} × ${set.reps}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (set.type == SetType.dropSet)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'drop',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
