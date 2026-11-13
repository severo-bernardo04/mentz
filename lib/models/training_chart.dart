import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'profile_models.dart';

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

  /// Exercícios do dia, na ordem de execução.
  final List<WorkoutExercise> exercises;

  const TrainingDay({
    required this.id,
    required this.name,
    required this.order,
    this.focusOrDescription,
    this.exercises = const [],
  });

  TrainingDay copyWith({
    String? id,
    String? name,
    int? order,
    String? focusOrDescription,
    List<WorkoutExercise>? exercises,
  }) {
    return TrainingDay(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      focusOrDescription: focusOrDescription ?? this.focusOrDescription,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
      if (focusOrDescription != null) 'focusOrDescription': focusOrDescription,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory TrainingDay.fromMap(
    Map<String, dynamic> map, {
    required ExerciseLookup findExercise,
  }) {
    return TrainingDay(
      id: map['id'] as String,
      name: map['name'] as String,
      order: (map['order'] as num?)?.toInt() ?? 0,
      focusOrDescription: map['focusOrDescription'] as String?,
      exercises: (map['exercises'] as List?)
              ?.map(
                (e) => WorkoutExercise.fromMap(
                  Map<String, dynamic>.from(e as Map),
                  findExercise: findExercise,
                ),
              )
              .toList() ??
          const [],
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
          focusOrDescription == other.focusOrDescription &&
          listEquals(exercises, other.exercises);

  @override
  int get hashCode =>
      Object.hash(id, name, order, focusOrDescription, Object.hashAll(exercises));
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
  /// Limites também aplicados pelas regras de segurança do Firestore.
  static const maxNameLength = 50;
  static const maxDays = 15;

  final String id;
  final String name;
  final String? description;
  final List<TrainingDay> days;
  final WorkoutFrequencyConfig frequencyConfig;
  final DateTime createdAt;

  /// Quando o usuário escolheu esta planilha como a atual; null se nunca
  /// escolheu. A atual é a de escolha mais recente (veja
  /// `TrainingChartService.currentChart`).
  final DateTime? selectedAt;

  const TrainingChart({
    required this.id,
    required this.name,
    this.description,
    required this.days,
    required this.frequencyConfig,
    required this.createdAt,
    this.selectedAt,
  });

  TrainingChart copyWith({
    String? id,
    String? name,
    String? description,
    List<TrainingDay>? days,
    WorkoutFrequencyConfig? frequencyConfig,
    DateTime? createdAt,
    DateTime? selectedAt,
  }) {
    return TrainingChart(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      days: days ?? this.days,
      frequencyConfig: frequencyConfig ?? this.frequencyConfig,
      createdAt: createdAt ?? this.createdAt,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'days': days.map((d) => d.toMap()).toList(),
      'frequencyConfig': frequencyConfig.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (selectedAt != null) 'selectedAt': Timestamp.fromDate(selectedAt!),
    };
  }

  /// [id] é o identificador do documento no Firestore.
  factory TrainingChart.fromMap(
    String id,
    Map<String, dynamic> map, {
    required ExerciseLookup findExercise,
  }) {
    return TrainingChart(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String?,
      days: (map['days'] as List?)
              ?.map(
                (item) => TrainingDay.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  findExercise: findExercise,
                ),
              )
              .toList() ??
          [],
      frequencyConfig: map['frequencyConfig'] != null
          ? WorkoutFrequencyConfig.fromMap(
              Map<String, dynamic>.from(map['frequencyConfig'] as Map))
          : const WorkoutFrequencyConfig(type: WorkoutFrequencyType.fixedDays),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selectedAt: (map['selectedAt'] as Timestamp?)?.toDate(),
    );
  }
}
