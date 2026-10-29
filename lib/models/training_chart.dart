import 'package:flutter/foundation.dart';

/// Tipo de frequência com que os treinos da planilha são executados.
enum WorkoutFrequencyType {
  /// Dias fixos da semana (ex: Segunda, Quarta, Sexta).
  fixedDays,

  /// Intervalo flexível/variável de dias entre os treinos (ex: Treino 1 dia, descanso 1 dia).
  intervalDays,
}

/// Dia de treino que compõe o ciclo da planilha (`t_day`).
class TrainingDay {
  final String id;
  final String name;
  final int order;
  final String? focusOrDescription;

  const TrainingDay({
    required this.id,
    required this.name,
    required this.order,
    this.focusOrDescription,
  });

  TrainingDay copyWith({
    String? id,
    String? name,
    int? order,
    String? focusOrDescription,
  }) {
    return TrainingDay(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      focusOrDescription: focusOrDescription ?? this.focusOrDescription,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'focusOrDescription': focusOrDescription,
    };
  }

  factory TrainingDay.fromMap(Map<String, dynamic> map) {
    return TrainingDay(
      id: map['id'] as String,
      name: map['name'] as String,
      order: (map['order'] as num?)?.toInt() ?? 0,
      focusOrDescription: map['focusOrDescription'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingDay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          order == other.order &&
          focusOrDescription == other.focusOrDescription;

  @override
  int get hashCode => Object.hash(id, name, order, focusOrDescription);
}

/// Configuração de frequência de execução dos treinos.
class WorkoutFrequencyConfig {
  final WorkoutFrequencyType type;

  /// Dias da semana selecionados (1 = Segunda ... 7 = Domingo).
  /// Utilizado quando [type] == [WorkoutFrequencyType.fixedDays].
  final List<int> fixedWeekdays;

  /// Dias de descanso ou intervalo após cada treino do ciclo.
  /// Por exemplo: [1, 1, 2] indica 1 dia de descanso após treino 1, 1 após treino 2 e 2 após treino 3.
  /// Utilizado quando [type] == [WorkoutFrequencyType.intervalDays].
  final List<int> intervalRestDays;

  const WorkoutFrequencyConfig({
    required this.type,
    this.fixedWeekdays = const [],
    this.intervalRestDays = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'fixedWeekdays': fixedWeekdays,
      'intervalRestDays': intervalRestDays,
    };
  }

  factory WorkoutFrequencyConfig.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? WorkoutFrequencyType.fixedDays.name;
    final type = WorkoutFrequencyType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => WorkoutFrequencyType.fixedDays,
    );

    final fixedList = (map['fixedWeekdays'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [];

    final intervalList = (map['intervalRestDays'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [];

    return WorkoutFrequencyConfig(
      type: type,
      fixedWeekdays: fixedList,
      intervalRestDays: intervalList,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutFrequencyConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          listEquals(fixedWeekdays, other.fixedWeekdays) &&
          listEquals(intervalRestDays, other.intervalRestDays);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(fixedWeekdays), Object.hashAll(intervalRestDays));
}

/// Planilha de treino (`chart`).
class TrainingChart {
  final String id;
  final String name;
  final String? description;
  final List<TrainingDay> days;
  final WorkoutFrequencyConfig frequencyConfig;
  final DateTime createdAt;

  const TrainingChart({
    required this.id,
    required this.name,
    this.description,
    required this.days,
    required this.frequencyConfig,
    required this.createdAt,
  });

  TrainingChart copyWith({
    String? id,
    String? name,
    String? description,
    List<TrainingDay>? days,
    WorkoutFrequencyConfig? frequencyConfig,
    DateTime? createdAt,
  }) {
    return TrainingChart(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      days: days ?? this.days,
      frequencyConfig: frequencyConfig ?? this.frequencyConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'days': days.map((d) => d.toMap()).toList(),
      'frequencyConfig': frequencyConfig.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TrainingChart.fromMap(Map<String, dynamic> map) {
    return TrainingChart(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      days: (map['days'] as List?)
              ?.map((item) => TrainingDay.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      frequencyConfig: map['frequencyConfig'] != null
          ? WorkoutFrequencyConfig.fromMap(
              Map<String, dynamic>.from(map['frequencyConfig'] as Map))
          : const WorkoutFrequencyConfig(type: WorkoutFrequencyType.fixedDays),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
