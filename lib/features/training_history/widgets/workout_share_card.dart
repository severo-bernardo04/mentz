import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import '../../workout_session/widgets/set_count_summary.dart';

/// Card visual moderno no formato Instagram Stories (9:16)
/// projetado para exibir a foto tirada pelo usuário com as informações
/// do treino sobrepostas em alta resolução para compartilhamento.
class WorkoutShareCard extends StatelessWidget {
  final CompletedWorkout session;
  final String? userName;
  final Uint8List? backgroundImageBytes;
  final VoidCallback? onTakePhoto;
  final bool isExport;

  const WorkoutShareCard({
    super.key,
    required this.session,
    this.userName,
    this.backgroundImageBytes,
    this.onTakePhoto,
    this.isExport = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final totalExercises = session.executedExercises.length;
    // Exercícios realmente realizados/trabalhados
    final completedExercises = session.executedExercises.where((e) {
      return e.completed ||
          e.allSetsFilled ||
          e.sets.any((s) => s.isFilled || s.reps > 0);
    }).length;

    // Métricas reais calculadas a partir de todas as séries salvas
    double totalVolumeKg = 0;
    double maxLoadKg = 0;
    int completedSets = 0;

    for (final ex in session.executedExercises) {
      for (final s in ex.sets) {
        if (s.isFilled || s.completed || s.reps > 0) {
          completedSets++;
          if (s.loadKg > 0) {
            totalVolumeKg += s.loadKg * s.reps;
            if (s.loadKg > maxLoadKg) maxLoadKg = s.loadKg;
          }
        }
        for (final stage in s.dropStages) {
          if (stage.reps > 0) {
            if (stage.loadKg > 0) {
              totalVolumeKg += stage.loadKg * stage.reps;
              if (stage.loadKg > maxLoadKg) maxLoadKg = stage.loadKg;
            }
          }
        }
      }
    }

    final totalSets = completedSets > 0
        ? completedSets
        : SetCountSummary.totalOf(session.setCountByType);

    // Músculos trabalhados
    final musclesList = <String>[];
    for (final ex in session.executedExercises) {
      final m = ex.muscle.trim();
      if (m.isNotEmpty && !musclesList.contains(m)) {
        musclesList.add(m);
      }
    }
    final musclesSummary = musclesList.take(3).join(' • ');

    final hasPhoto = backgroundImageBytes != null;

    // Se tiver foto de fundo, mostra até 3 exercícios para manter a foto bem visível
    // Sem foto, mostra até 5 exercícios
    final highlightExercises =
        session.executedExercises.take(hasPhoto ? 3 : 5).toList();

    // Cores adaptativas ao tema claro e escuro (ou à foto de fundo)
    final textColor =
        (hasPhoto || isDark) ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        (hasPhoto || isDark) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        (hasPhoto || isDark) ? Colors.white.withAlpha(35) : const Color(0xFFCBD5E1);
    final accentColor =
        (hasPhoto || isDark) ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    return Container(
      width: 360,
      height: 640,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: isExport ? BorderRadius.zero : BorderRadius.circular(24),
        boxShadow: isExport
            ? null
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(120)
                      : Colors.black.withAlpha(25),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FOTO TIRADA PELO USUÁRIO (se disponível) OU FUNDO TEMA CLARO/ESCURO
          if (hasPhoto)
            Positioned.fill(
              child: Image.memory(
                backgroundImageBytes!,
                fit: BoxFit.cover,
                width: 360,
                height: 640,
                cacheWidth: 720,
              ),
            )
          else if (isDark)
            // Fundo tema escuro (gradiente índigo profundo/slate)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.7),
                  radius: 1.3,
                  colors: [
                    Color(0xFF312E81),
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            )
          else
            // Fundo tema claro (gradiente suave e limpo indigo/slate)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF2FF),
                    Color(0xFFF8FAFC),
                    Color(0xFFE0E7FF),
                  ],
                ),
              ),
            ),

          // 2. GRADIENTE DE CONTRASTE (Vignette para fotos)
          if (hasPhoto)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(200), // Topo escuro para a logo
                      Colors.transparent,         // Centro livre para a foto
                      Colors.black.withAlpha(140), // Transição
                      Colors.black.withAlpha(240), // Base escura para os dados
                    ],
                    stops: const [0.0, 0.22, 0.60, 1.0],
                  ),
                ),
              ),
            ),

          // 3. CONTEÚDO PRINCIPAL SOBREPOSTO NA FOTO
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isExport ? 42 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topo: Logo oficial do App (ícone psychology com gradiente + MENTZ)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withAlpha(100),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MENTZ',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),

                // Se não houver foto, mostra o ícone de upload para adicionar foto de fundo
                if (!hasPhoto) ...[
                  const Spacer(),
                  Center(
                    child: GestureDetector(
                      onTap: onTakePhoto,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(isDark ? 35 : 20),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withAlpha(isDark ? 120 : 80),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha(isDark ? 50 : 25),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.file_upload_outlined,
                          color: accentColor,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),

                // Painel de Informações do Treino (Totalmente Transparente)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Data e Dia da Semana
                      Text(
                        '${_formatDate(session.date)} • ${session.weekdayName.toUpperCase()}',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Nome do Treino e Ficha
                      Text(
                        session.displayWorkoutName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (session.displayChartName.isNotEmpty || musclesSummary.isNotEmpty) ...[
                        Text(
                          [
                            if (session.displayChartName.isNotEmpty) session.displayChartName,
                            if (musclesSummary.isNotEmpty) musclesSummary,
                          ].join(' • '),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Métricas Reais do Treino (Cards Transparentes)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              icon: Icons.timer_outlined,
                              value: '${session.minutes}',
                              unit: 'min',
                              label: 'DURAÇÃO',
                              iconColor: accentColor,
                              textColor: textColor,
                              labelColor: textSecondary,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildStatBox(
                              icon: Icons.checklist_rounded,
                              value: '$completedExercises/$totalExercises',
                              unit: 'feitos',
                              label: 'EXERCÍCIOS',
                              iconColor: accentColor,
                              textColor: textColor,
                              labelColor: textSecondary,
                              borderColor: borderColor,
                            ),
                          ),
                          if (totalVolumeKg > 0) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildStatBox(
                                icon: Icons.fitness_center_rounded,
                                value: totalVolumeKg >= 1000
                                    ? (totalVolumeKg / 1000).toStringAsFixed(1)
                                    : '${totalVolumeKg.round()}',
                                unit: totalVolumeKg >= 1000 ? 'ton' : 'kg',
                                label: 'VOLUME',
                                iconColor: accentColor,
                                textColor: textColor,
                                labelColor: textSecondary,
                                borderColor: borderColor,
                              ),
                            ),
                          ],
                          if (totalSets > 0) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildStatBox(
                                icon: Icons.repeat_rounded,
                                value: '$totalSets',
                                unit: 'sets',
                                label: 'SÉRIES',
                                iconColor: accentColor,
                                textColor: textColor,
                                labelColor: textSecondary,
                                borderColor: borderColor,
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (highlightExercises.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final ex in highlightExercises)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF4ADE80),
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    ex.name,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatExerciseSummary(ex),
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Rodapé com branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orange.shade400,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          maxLoadKg > 0
                              ? 'Carga máx: ${_formatKgValue(maxLoadKg)}'
                              : 'Constância',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '#MentzApp',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color iconColor,
    required Color textColor,
    required Color labelColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value $unit',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatKgValue(double kg) {
    final str = kg == kg.roundToDouble() ? '${kg.toInt()}' : '$kg';
    return '$str kg';
  }

  static String _formatExerciseSummary(ExecutedExercise ex) {
    final workedSets =
        ex.sets.where((s) => s.isFilled || s.completed || s.reps > 0).toList();
    final count = workedSets.isNotEmpty ? workedSets.length : ex.sets.length;

    double peak = 0;
    bool hasBw = false;
    for (final s in (workedSets.isNotEmpty ? workedSets : ex.sets)) {
      if (s.bodyWeight) hasBw = true;
      if (s.loadKg > peak) peak = s.loadKg;
    }

    final setsText = '$count ${count == 1 ? 'série' : 'séries'}';
    if (peak > 0) {
      return '$setsText • ${_formatKgValue(peak)}';
    } else if (hasBw) {
      return '$setsText • BW';
    }
    return setsText;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
