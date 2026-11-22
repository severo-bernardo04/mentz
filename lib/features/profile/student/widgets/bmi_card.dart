import 'package:flutter/material.dart';
import 'package:mentz/models/bmi_info.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/section_card.dart';
import 'package:mentz/widgets/stat_tile.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Card unificado de Medidas Corporais e IMC com estatísticas e régua visual.
class BmiCard extends StatelessWidget {
  final double? heightCm;
  final double? weightKg;
  final DateTime? birthDate;
  final String? sex;
  final bool hidden;
  final bool isOwnerView;
  final VoidCallback? onEdit;

  const BmiCard({
    super.key,
    required this.heightCm,
    required this.weightKg,
    this.birthDate,
    this.sex,
    this.hidden = false,
    this.isOwnerView = true,
    this.onEdit,
  });

  String _mask(String v) => hidden ? '•••' : v;

  String _categoryDescription(BmiResult bmi) {
    if (bmi.isElderlyCriteria) {
      switch (bmi.category) {
        case BmiCategory.underweight:
          return 'Abaixo da faixa saudável para idosos (Critério Lipschitz)';
        case BmiCategory.normal:
          return 'Dentro da faixa saudável para idosos (22,0 – 27,0 kg/m²)';
        case BmiCategory.overweight:
          return 'Levemente acima da faixa ideal geriátrica (> 27,0 kg/m²)';
        default:
          return 'Faixa de obesidade segundo critérios geriátricos';
      }
    }

    switch (bmi.category) {
      case BmiCategory.underweight:
        return 'Abaixo da faixa recomendada pela OMS';
      case BmiCategory.normal:
        return 'Dentro da faixa saudável recomendada pela OMS';
      case BmiCategory.overweight:
        return 'Levemente acima da faixa ideal da OMS';
      case BmiCategory.obesityClass1:
        return 'Na faixa de obesidade grau I';
      case BmiCategory.obesityClass2:
        return 'Na faixa de obesidade grau II';
      case BmiCategory.obesityClass3:
        return 'Na faixa de obesidade mórbida (grau III)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = birthDate != null ? ageFrom(birthDate!) : null;
    final bioSex = BiologicalSex.tryParse(sex);
    final bmi = BmiResult.calculate(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      sex: bioSex,
    );
    final hasMeasures = heightCm != null || weightKg != null;

    return SectionCard(
      title: 'Medidas e IMC',
      icon: Icons.monitor_weight_outlined,
      // Deixamos no trailing apenas o botão de edição para que o título nunca quebre de linha
      trailing: isOwnerView && onEdit != null
          ? IconButton(
              key: const Key('edit_measures_button'),
              tooltip: 'Editar medidas',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            )
          : null,
      child: !hasMeasures
          ? _buildEmptyState(context)
          : _buildContent(context, bmi),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(Icons.monitor_weight_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 10),
          Text(
            'Cadastre suas medidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informe sua altura e peso para calcular automaticamente seu IMC, % de gordura e faixa de peso saudável.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const Key('empty_add_measures_button'),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Cadastrar medidas'),
              onPressed: onEdit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BmiResult? bmi) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final heightLabel = heightCm == null
        ? '—'
        : _mask('${heightCm!.toStringAsFixed(0)} cm');
    final weightLabel = weightKg == null
        ? '—'
        : _mask('${weightKg!.toStringAsFixed(1)} kg');
    final bmiScoreLabel = bmi == null ? '—' : _mask(bmi.score.toStringAsFixed(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linha superior com contexto de sexo/idade e classificação (dentro do card)
        if (bmi != null && !hidden) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (bmi.profileContextDescription != null)
                Text(
                  bmi.profileContextDescription!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox.shrink(),
              StatusChip(
                label: bmi.category.label,
                color: bmi.category.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 3 tiles estatísticos integrados (Altura, Peso, IMC)
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.height,
                value: heightLabel,
                label: 'Altura',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                icon: Icons.monitor_weight_outlined,
                value: weightLabel,
                label: 'Peso atual',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BmiStatTile(
                scoreText: bmiScoreLabel,
                categoryColor: bmi?.category.color ?? cs.primary,
                categoryLabel: bmi == null ? 'IMC' : (hidden ? 'IMC' : bmi.category.label),
              ),
            ),
          ],
        ),
        if (bmi != null) ...[
          const SizedBox(height: 18),
          // Régua gráfica do IMC
          _BmiGaugeBar(
            position: hidden ? null : bmi.gaugePosition,
            activeColor: bmi.category.color,
          ),
          const SizedBox(height: 14),
          // Faixa de peso saudável e descrição da OMS / Lipschitz
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(110),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heightCm != null
                            ? 'Faixa de peso saudável (${heightCm!.toStringAsFixed(0)} cm): ${_mask(bmi.idealWeightLabel)}'
                            : 'Faixa de peso saudável: ${_mask(bmi.idealWeightLabel)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _categoryDescription(bmi),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Estimativa de % de gordura corporal pela fórmula de Deurenberg
          if (bmi.bodyFatPercentage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(90),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_mask(bmi.bodyFatPercentage!.toStringAsFixed(1))}% — ${_mask(bmi.bodyFatCategory ?? '')}',
                          key: const Key('body_fat_text'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ESTIMATIVA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Estimativa pela fórmula de Deurenberg (1991) com base no IMC, idade e sexo. '
                    'Tabela de referência ACE. Pode apresentar variações em indivíduos com alta massa muscular.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// StatTile customizado para o IMC com destaque na cor da categoria.
class _BmiStatTile extends StatelessWidget {
  final String scoreText;
  final Color categoryColor;
  final String categoryLabel;

  const _BmiStatTile({
    required this.scoreText,
    required this.categoryColor,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: categoryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, color: categoryColor, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              scoreText,
              key: const Key('bmi_score_text'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: categoryColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            categoryLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra visual de IMC dividida nas 4 zonas da OMS com marcador indicador.
class _BmiGaugeBar extends StatelessWidget {
  final double? position;
  final Color activeColor;

  const _BmiGaugeBar({
    required this.position,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pos = position;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 35,
                          child: ColoredBox(color: Color(0xFF0284C7)),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 65,
                          child: ColoredBox(color: Color(0xFF16A34A)),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 50,
                          child: ColoredBox(color: Color(0xFFEAB308)),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 100,
                          child: ColoredBox(color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (pos != null)
                  Positioned(
                    left: (w * pos).clamp(0.0, w) - 6,
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 18,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '< 18.5',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
            Text(
              '18.5 – 24.9',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '25 – 29.9',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
            Text(
              '≥ 30',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
