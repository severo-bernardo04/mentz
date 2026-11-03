import 'package:flutter/material.dart';
import '../../../models/profile_models.dart';
import 'muscle_anatomy_painter.dart';
import 'muscle_legend_bar.dart';

/// Componente que apresenta a demonstração anatômica do corpo humano com o destaque
/// de ativação muscular do exercício nas vistas anterior e posterior.
class MuscleAnatomyView extends StatefulWidget {
  final Exercise exercise;
  final double height;

  const MuscleAnatomyView({
    super.key,
    required this.exercise,
    this.height = 320,
  });

  @override
  State<MuscleAnatomyView> createState() => _MuscleAnatomyViewState();
}

class _MuscleAnatomyViewState extends State<MuscleAnatomyView> {
  late AnatomyViewType _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = _defaultViewForExercise(widget.exercise);
  }

  @override
  void didUpdateWidget(covariant MuscleAnatomyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.name != widget.exercise.name) {
      _viewType = _defaultViewForExercise(widget.exercise);
    }
  }

  /// Define a visão inicial mais adequada com base no músculo principal do exercício.
  static AnatomyViewType _defaultViewForExercise(Exercise exercise) {
    final m = (exercise.primaryMuscle ?? exercise.muscle).toLowerCase();
    if (m.contains('costa') ||
        m.contains('dorsal') ||
        m.contains('tríceps') ||
        m.contains('triceps') ||
        m.contains('lombar') ||
        m.contains('posterior') ||
        m.contains('isquiotibial') ||
        m.contains('glúteo') ||
        m.contains('gluteo')) {
      return AnatomyViewType.posterior;
    }
    return AnatomyViewType.anterior;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseBodyColor = isDark
        ? const Color(0xFF2C2D35)
        : const Color(0xFFE2E4EC);
    final bodyBorderColor = isDark
        ? const Color(0xFF434555)
        : const Color(0xFFB5B8C8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Seletor de visualização (Frente / Costas)
        Center(
          child: SegmentedButton<AnatomyViewType>(
            segments: const [
              ButtonSegment(
                value: AnatomyViewType.anterior,
                label: Text('Vista Anterior (Frente)'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: AnatomyViewType.posterior,
                label: Text('Vista Posterior (Costas)'),
                icon: Icon(Icons.accessibility_new_rounded),
              ),
            ],
            selected: {_viewType},
            onSelectionChanged: (set) => setState(() => _viewType = set.first),
          ),
        ),
        const SizedBox(height: 16),

        // Área do boneco anatômico
        Center(
          child: Container(
            height: widget.height,
            width: widget.height * 0.65,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withAlpha(70)),
            ),
            child: CustomPaint(
              painter: MuscleAnatomyPainter(
                exercise: widget.exercise,
                viewType: _viewType,
                baseColor: baseBodyColor,
                borderColor: bodyBorderColor,
              ),
              size: Size(widget.height * 0.65, widget.height),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Legenda obrigatória de três cores
        const MuscleLegendBar(),
        const SizedBox(height: 14),

        // Resumo dos músculos cadastrados para este exercício
        _buildMusclesBreakdown(context),
      ],
    );
  }

  Widget _buildMusclesBreakdown(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = widget.exercise;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleRow(
            label: 'Músculo Principal:',
            role: MuscleRole.primary,
            muscles: [e.displayPrimaryMuscle],
          ),
          if (e.highActivationMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRoleRow(
              label: 'Alta Ativação:',
              role: MuscleRole.highActivation,
              muscles: e.highActivationMuscles,
            ),
          ],
          if (e.secondaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRoleRow(
              label: 'Secundários:',
              role: MuscleRole.secondary,
              muscles: e.secondaryMuscles,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleRow({
    required String label,
    required MuscleRole role,
    required List<String> muscles,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: role.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: role.color,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final m in muscles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: role.color.withAlpha(22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: role.color.withAlpha(70)),
                  ),
                  child: Text(
                    m,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: role.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
