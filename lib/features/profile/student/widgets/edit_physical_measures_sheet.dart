import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/models/bmi_info.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/user_profile_service.dart';
import 'package:mentz/widgets/app_button.dart';
import 'package:mentz/widgets/status_chip.dart';

/// Resultado retornado ao salvar as medidas.
class PhysicalMeasuresResult {
  final double? heightCm;
  final double? weightKg;
  final DateTime? birthDate;
  final String? sex;

  const PhysicalMeasuresResult({
    this.heightCm,
    this.weightKg,
    this.birthDate,
    this.sex,
  });
}

/// Modal bottom sheet para cadastrar ou editar altura, peso, nascimento e sexo biológico.
class EditPhysicalMeasuresSheet extends StatefulWidget {
  final double? initialHeightCm;
  final double? initialWeightKg;
  final DateTime? initialBirthDate;
  final String? initialSex;
  final List<WeightEntry>? weightHistory;
  final String? uid;
  final Future<void> Function({
    double? heightCm,
    double? weightKg,
    DateTime? birthDate,
    String? sex,
  })? onSave;

  const EditPhysicalMeasuresSheet({
    super.key,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialBirthDate,
    this.initialSex,
    this.weightHistory,
    this.uid,
    this.onSave,
  });

  @override
  State<EditPhysicalMeasuresSheet> createState() =>
      _EditPhysicalMeasuresSheetState();
}

class _EditPhysicalMeasuresSheetState extends State<EditPhysicalMeasuresSheet> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  double? _previewHeight;
  double? _previewWeight;
  DateTime? _birthDate;
  BiologicalSex? _sex;

  @override
  void initState() {
    super.initState();
    _previewHeight = widget.initialHeightCm;
    _previewWeight = widget.initialWeightKg;
    _birthDate = widget.initialBirthDate;
    _sex = BiologicalSex.tryParse(widget.initialSex);

    _heightController = TextEditingController(
      text: widget.initialHeightCm != null
          ? widget.initialHeightCm!.toStringAsFixed(0)
          : '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeightKg != null
          ? widget.initialWeightKg!.toStringAsFixed(1)
          : '',
    );

    _heightController.addListener(_onMeasuresChanged);
    _weightController.addListener(_onMeasuresChanged);
  }

  @override
  void dispose() {
    _heightController.removeListener(_onMeasuresChanged);
    _weightController.removeListener(_onMeasuresChanged);
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onMeasuresChanged() {
    final h = double.tryParse(_heightController.text.replaceAll(',', '.').trim());
    final w = double.tryParse(_weightController.text.replaceAll(',', '.').trim());
    setState(() {
      _previewHeight = h;
      _previewWeight = w;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('pt', 'BR'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: child,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final height = _previewHeight;
    final weight = _previewWeight;
    final birth = _birthDate;
    final sexStr = _sex?.label;

    if (height == null && weight == null && birth == null && sexStr == null) {
      return;
    }

    setState(() => _loading = true);

    try {
      if (widget.onSave != null) {
        await widget.onSave!(
          heightCm: height,
          weightKg: weight,
          birthDate: birth,
          sex: sexStr,
        );
      } else {
        String? targetUid = widget.uid;
        if (targetUid == null) {
          try {
            targetUid = FirebaseAuth.instance.currentUser?.uid;
          } catch (_) {
            // Em testes de widget ou sem Firebase inicializado
          }
        }
        if (targetUid != null) {
          await UserProfileService().updatePhysicalMeasures(
            targetUid,
            heightCm: height,
            weightKg: weight,
            birthDate: birth,
            sex: sexStr,
            existingHistory: widget.weightHistory,
          );
        }
      }

      if (mounted) {
        final nav = Navigator.of(context);
        final messenger = ScaffoldMessenger.maybeOf(context);
        nav.pop(
          PhysicalMeasuresResult(
            heightCm: height,
            weightKg: weight,
            birthDate: birth,
            sex: sexStr,
          ),
        );
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Medidas físicas atualizadas com sucesso.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        context.showSnack('Não foi possível salvar as medidas. Tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final age = _birthDate != null ? ageFrom(_birthDate!) : null;
    final bmi = BmiResult.calculate(
      weightKg: _previewWeight,
      heightCm: _previewHeight,
      age: age,
      sex: _sex,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de arraste visual no topo
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      color: cs.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Medidas Corporais',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                Text(
                  'Informe suas medidas, idade e sexo biológico para calcular o IMC, % de gordura e peso ideal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                // Campos de Altura e Peso
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('height_input_field'),
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Altura',
                          suffixText: 'cm',
                          prefixIcon: const Icon(Icons.height),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a altura';
                          }
                          final parsed = double.tryParse(
                            value.replaceAll(',', '.').trim(),
                          );
                          if (parsed == null || parsed < 50 || parsed > 260) {
                            return 'Altura inválida';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('weight_input_field'),
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Peso atual',
                          suffixText: 'kg',
                          prefixIcon: const Icon(Icons.scale_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o peso';
                          }
                          final parsed = double.tryParse(
                            value.replaceAll(',', '.').trim(),
                          );
                          if (parsed == null || parsed < 20 || parsed > 350) {
                            return 'Peso inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Data de Nascimento
                InkWell(
                  key: const Key('pick_birth_date_button'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickBirthDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake_outlined, color: cs.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nascimento / Idade',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _birthDate == null
                                    ? 'Toque para selecionar'
                                    : '${formatDate(_birthDate!)} (${ageFrom(_birthDate!)} anos)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_calendar_outlined, color: cs.primary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Sexo Biológico (para fórmulas metabólicas)
                Row(
                  children: [
                    Text(
                      'Sexo biológico:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SegmentedButton<BiologicalSex>(
                        key: const Key('sex_segmented_button'),
                        segments: const [
                          ButtonSegment(
                            value: BiologicalSex.male,
                            label: Text('Masculino'),
                            icon: Icon(Icons.male, size: 18),
                          ),
                          ButtonSegment(
                            value: BiologicalSex.female,
                            label: Text('Feminino'),
                            icon: Icon(Icons.female, size: 18),
                          ),
                        ],
                        selected: _sex == null ? const {} : {_sex!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (newSet) {
                          setState(() {
                            _sex = newSet.isEmpty ? null : newSet.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card de preview em tempo real do IMC e Gordura
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(120),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: bmi != null
                          ? bmi.category.color.withAlpha(80)
                          : cs.outlineVariant.withAlpha(50),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            color: bmi?.category.color ?? cs.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bmi == null
                                      ? 'Preencha altura e peso para ver o IMC'
                                      : 'IMC Estimado: ${bmi.score.toStringAsFixed(1)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: bmi?.category.color,
                                  ),
                                ),
                                if (bmi != null)
                                  Text(
                                    'Faixa ideal: ${bmi.idealWeightLabel}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (bmi != null)
                            StatusChip(
                              label: bmi.category.label,
                              color: bmi.category.color,
                            ),
                        ],
                      ),
                      if (bmi?.bodyFatPercentage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, size: 16, color: cs.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Gordura estimada: ${bmi!.bodyFatPercentage}% (${bmi.bodyFatCategory})',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  key: const Key('save_measures_button'),
                  label: 'Salvar Medidas',
                  icon: Icons.check_circle_outline,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exibe o modal de medidas corporais.
Future<PhysicalMeasuresResult?> showEditPhysicalMeasuresSheet(
  BuildContext context, {
  double? initialHeightCm,
  double? initialWeightKg,
  DateTime? initialBirthDate,
  String? initialSex,
  List<WeightEntry>? weightHistory,
  String? uid,
  Future<void> Function({
    double? heightCm,
    double? weightKg,
    DateTime? birthDate,
    String? sex,
  })? onSave,
}) {
  return showModalBottomSheet<PhysicalMeasuresResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditPhysicalMeasuresSheet(
      initialHeightCm: initialHeightCm,
      initialWeightKg: initialWeightKg,
      initialBirthDate: initialBirthDate,
      initialSex: initialSex,
      weightHistory: weightHistory,
      uid: uid,
      onSave: onSave,
    ),
  );
}
