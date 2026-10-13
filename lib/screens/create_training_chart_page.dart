import 'package:flutter/material.dart';
import '../models/training_chart.dart';
import '../services/training_chart_service.dart';
import 'auth_widgets.dart';

class _DayItem {
  final TextEditingController nameCtrl;
  final TextEditingController focusCtrl;
  int restDaysAfter;

  _DayItem({
    required String name,
    String focus = '',
    this.restDaysAfter = 1,
  })  : nameCtrl = TextEditingController(text: name),
        focusCtrl = TextEditingController(text: focus);

  void dispose() {
    nameCtrl.dispose();
    focusCtrl.dispose();
  }
}

class CreateTrainingChartPage extends StatefulWidget {
  final TrainingChartService? service;

  const CreateTrainingChartPage({super.key, this.service});

  @override
  State<CreateTrainingChartPage> createState() => _CreateTrainingChartPageState();
}

class _CreateTrainingChartPageState extends State<CreateTrainingChartPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController(text: 'Training Charts 7');
  final _descCtrl = TextEditingController();

  final List<_DayItem> _days = [];

  WorkoutFrequencyType _frequencyType = WorkoutFrequencyType.fixedDays;
  final Set<int> _selectedWeekdays = {1, 3, 5}; // 1 = Seg, 3 = Qua, 5 = Sex

  bool _loading = false;
  String? _errorMessage;

  static const _weekdayLabels = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  @override
  void initState() {
    super.initState();
    // Inicia com 3 dias padrão (ABC)
    _days.add(_DayItem(name: 'TREINO A', focus: 'Peito e Tríceps', restDaysAfter: 1));
    _days.add(_DayItem(name: 'TREINO B', focus: 'Costas e Bíceps', restDaysAfter: 1));
    _days.add(_DayItem(name: 'TREINO C', focus: 'Pernas e Ombros', restDaysAfter: 2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    final nextLetter = String.fromCharCode(65 + (_days.length % 26));
    setState(() {
      _days.add(_DayItem(
        name: 'TREINO $nextLetter',
        restDaysAfter: 1,
      ));
      _errorMessage = null;
    });
  }

  void _removeDay(int index) {
    if (_days.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A planilha deve conter pelo menos um dia de treino.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      final removed = _days.removeAt(index);
      removed.dispose();
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_days.isEmpty) {
      setState(() {
        _errorMessage = 'Adicione pelo menos um dia de treino ao ciclo.';
      });
      return;
    }

    // Validação dos nomes dos dias
    for (var i = 0; i < _days.length; i++) {
      if (_days[i].nameCtrl.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'O dia #${i + 1} está com o nome vazio.';
        });
        return;
      }
    }

    // Se a frequência for dias fixos, certifique-se de selecionar pelo menos um dia
    if (_frequencyType == WorkoutFrequencyType.fixedDays && _selectedWeekdays.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione ao menos um dia da semana para treinar.';
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final chartService = widget.service ?? TrainingChartService();

      final trainingDays = List<TrainingDay>.generate(
        _days.length,
        (i) => TrainingDay(
          id: 'day-${DateTime.now().millisecondsSinceEpoch}-$i',
          name: _days[i].nameCtrl.text.trim(),
          order: i + 1,
          focusOrDescription: _days[i].focusCtrl.text.trim().isEmpty
              ? null
              : _days[i].focusCtrl.text.trim(),
        ),
      );

      final frequencyConfig = WorkoutFrequencyConfig(
        type: _frequencyType,
        fixedWeekdays: _frequencyType == WorkoutFrequencyType.fixedDays
            ? (_selectedWeekdays.toList()..sort())
            : const [],
        intervalRestDays: _frequencyType == WorkoutFrequencyType.intervalDays
            ? _days.map((d) => d.restDaysAfter).toList()
            : const [],
      );

      final newChart = TrainingChart(
        id: 'chart-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        days: trainingDays,
        frequencyConfig: frequencyConfig,
        createdAt: DateTime.now(),
      );

      await chartService.saveChart(newChart);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Planilha "${newChart.name}" criada com sucesso!'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.of(context).pop(newChart);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao salvar a planilha: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nova Planilha',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: AuthBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card Informações da Planilha
                      FadeSlideIn(
                        child: AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.assignment_outlined, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dados da Planilha',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('chart_name_field'),
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.sentences,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Informe o nome da planilha.'
                                    : null,
                                decoration: authInputDecoration(
                                  context,
                                  label: 'Nome da planilha',
                                  icon: Icons.fitness_center_rounded,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: const Key('chart_desc_field'),
                                controller: _descCtrl,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: authInputDecoration(
                                  context,
                                  label: 'Objetivo ou descrição (opcional)',
                                  icon: Icons.notes_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Card Configuração de Frequência
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_rounded, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Frequência de Execução',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SegmentedButton<WorkoutFrequencyType>(
                                key: const Key('frequency_segmented_button'),
                                segments: const [
                                  ButtonSegment(
                                    value: WorkoutFrequencyType.fixedDays,
                                    label: Text('Dias Fixos'),
                                    icon: Icon(Icons.date_range_rounded),
                                  ),
                                  ButtonSegment(
                                    value: WorkoutFrequencyType.intervalDays,
                                    label: Text('Por Intervalo'),
                                    icon: Icon(Icons.timelapse_rounded),
                                  ),
                                ],
                                selected: {_frequencyType},
                                onSelectionChanged: (set) {
                                  setState(() {
                                    _frequencyType = set.first;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_frequencyType == WorkoutFrequencyType.fixedDays) ...[
                                Text(
                                  'Dias da semana em que você treina:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final entry in _weekdayLabels.entries)
                                      FilterChip(
                                        key: Key('weekday_chip_${entry.key}'),
                                        label: Text(entry.value),
                                        selected: _selectedWeekdays.contains(entry.key),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedWeekdays.add(entry.key);
                                            } else {
                                              _selectedWeekdays.remove(entry.key);
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Ciclo por intervalos variáveis:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Configure os dias de descanso após cada dia de treino logo abaixo.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Card Dias de Treino do Ciclo
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.view_timeline_rounded, color: cs.primary),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Dias do Ciclo (${_days.length})',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    key: const Key('add_day_button'),
                                    onPressed: _addDay,
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                    label: const Text('Adicionar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Defina a sequência de treinos (ex: TREINO A, TREINO B).',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (int i = 0; i < _days.length; i++)
                                _buildDayTile(context, i, _days[i]),
                            ],
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withAlpha(200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: cs.onErrorContainer),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        child: AuthButton(
                          label: 'Criar Planilha',
                          loading: _loading,
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, int index, _DayItem item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      key: Key('day_item_$index'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dia ${index + 1} do ciclo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: Key('delete_day_button_$index'),
                tooltip: 'Remover dia',
                icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                onPressed: () => _removeDay(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: Key('day_name_field_$index'),
            controller: item.nameCtrl,
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
            decoration: authInputDecoration(
              context,
              label: 'Nome do dia (ex: TREINO A, FULL BODY 1)',
              icon: Icons.label_outline_rounded,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: Key('day_focus_field_$index'),
            controller: item.focusCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: authInputDecoration(
              context,
              label: 'Foco muscular ou observações (opcional)',
              icon: Icons.flag_outlined,
            ),
          ),
          if (_frequencyType == WorkoutFrequencyType.intervalDays) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bed_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Descanso após este treino:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: item.restDaysAfter,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: [0, 1, 2, 3, 4].map((d) {
                    return DropdownMenuItem<int>(
                      value: d,
                      child: Text(d == 0 ? 'Sem descanso (0d)' : '$d dia${d > 1 ? 's' : ''}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        item.restDaysAfter = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
