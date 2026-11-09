import 'package:flutter/material.dart';

/// Modelos e dados de exemplo (mock) dos perfis de aluno e treinador.
/// Quando houver backend (ex: Firestore), basta trocar os `sample` por dados reais.

enum UserRole { student, trainer }

// ───────────────────────── Utilitários ─────────────────────────

const weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

int ageFrom(DateTime birth) {
  final now = DateTime.now();
  var age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age;
}

DateTime _daysAgo(int d) => DateTime.now().subtract(Duration(days: d));
DateTime _inDays(int d) => DateTime.now().add(Duration(days: d));

// ───────────────────────── Aluno ─────────────────────────

enum FitnessGoal {
  weightLoss('Emagrecimento', Icons.monitor_weight_outlined),
  hypertrophy('Hipertrofia', Icons.fitness_center),
  conditioning('Condicionamento', Icons.directions_run),
  health('Saúde', Icons.favorite_outline);

  final String label;
  final IconData icon;
  const FitnessGoal(this.label, this.icon);
}

class WeightEntry {
  final DateTime date;
  final double kg;
  const WeightEntry(this.date, this.kg);
}

class Assessment {
  final DateTime date;
  final double weight;
  final double bodyFat;
  final String notes;
  const Assessment(this.date, this.weight, this.bodyFat, this.notes);
}

class BodyMeasure {
  final DateTime date;
  final double chest, waist, hip, arm, thigh;
  const BodyMeasure(this.date, this.chest, this.waist, this.hip, this.arm,
      this.thigh);
}

/// Série planejada de um exercício: tipo, faixa de repetições e drop set.
/// A carga e as repetições realizadas só são registradas na execução.
class PlannedSet {
  final SetType type;
  final int minReps;
  final int maxReps;

  /// Indica se a série tem drop set. Não pode acompanhar [SetType.feeder].
  final bool isDropSet;

  const PlannedSet({
    this.type = SetType.working,
    required this.minReps,
    required this.maxReps,
    this.isDropSet = false,
  }) : assert(minReps > 0, 'A faixa deve começar em pelo menos 1 repetição.'),
       assert(minReps <= maxReps, 'O mínimo não pode ser maior que o máximo.'),
       assert(
         !isDropSet || type != SetType.feeder,
         'Drop set só pode acompanhar séries de Trabalho ou Aquecimento.',
       );

  /// Cria [count] séries iguais, com a mesma faixa de repetições.
  static List<PlannedSet> repeat(
    int count, {
    required int minReps,
    required int maxReps,
  }) => List.filled(count, PlannedSet(minReps: minReps, maxReps: maxReps));

  /// Lê uma faixa digitada como "8-10". Retorna null se o formato for
  /// inválido, se começar em zero ou se o mínimo for maior que o máximo.
  static PlannedSet? tryParse(String text) {
    final match = RegExp(r'^\s*(\d{1,3})\s*[-–]\s*(\d{1,3})\s*$').firstMatch(text);
    if (match == null) return null;

    final min = int.parse(match.group(1)!);
    final max = int.parse(match.group(2)!);
    if (min < 1 || min > max) return null;

    return PlannedSet(minReps: min, maxReps: max);
  }

  /// Faixa para exibição (ex: "8–10").
  String get repsLabel => minReps == maxReps ? '$minReps' : '$minReps–$maxReps';

  /// Faixa no formato aceito por [tryParse] (ex: "8-10").
  String get repsInput => '$minReps-$maxReps';

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'minReps': minReps,
        'maxReps': maxReps,
        'isDropSet': isDropSet,
      };

  factory PlannedSet.fromMap(Map<String, dynamic> map) {
    return PlannedSet(
      type: SetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SetType.working,
      ),
      minReps: (map['minReps'] as num?)?.toInt() ?? 1,
      maxReps: (map['maxReps'] as num?)?.toInt() ?? 1,
      isDropSet: map['isDropSet'] as bool? ?? false,
    );
  }
}

/// Exercício do catálogo: guarda apenas os dados fixos do exercício.
/// O que varia de treino para treino fica em [WorkoutExercise].
class Exercise {
  String name;
  String muscle;
  String? nameEn;
  String? primaryMuscle;
  List<String> highActivationMuscles;
  List<String> secondaryMuscles;
  String? equipment;
  String? instructions;

  Exercise({
    required this.name,
    this.muscle = '',
    this.nameEn,
    this.primaryMuscle,
    this.highActivationMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment,
    this.instructions,
  });

  String get displayPrimaryMuscle =>
      primaryMuscle ?? (muscle.isNotEmpty ? muscle : 'Geral');

  Exercise copyWith({
    String? name,
    String? muscle,
    String? nameEn,
    String? primaryMuscle,
    List<String>? highActivationMuscles,
    List<String>? secondaryMuscles,
    String? equipment,
    String? instructions,
  }) {
    return Exercise(
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      nameEn: nameEn ?? this.nameEn,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      highActivationMuscles:
          highActivationMuscles ?? this.highActivationMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'muscle': muscle,
        'nameEn': nameEn,
        'primaryMuscle': primaryMuscle,
        'highActivationMuscles': highActivationMuscles,
        'secondaryMuscles': secondaryMuscles,
        'equipment': equipment,
        'instructions': instructions,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] as String? ?? '',
      muscle: map['muscle'] as String? ?? '',
      nameEn: map['nameEn'] as String?,
      primaryMuscle: map['primaryMuscle'] as String?,
      highActivationMuscles: (map['highActivationMuscles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      secondaryMuscles: (map['secondaryMuscles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      equipment: map['equipment'] as String?,
      instructions: map['instructions'] as String?,
    );
  }
}

const _defaultPlannedSets = [
  PlannedSet(minReps: 10, maxReps: 12),
  PlannedSet(minReps: 10, maxReps: 12),
  PlannedSet(minReps: 10, maxReps: 12),
];

/// Exercício dentro de um treino: referencia o catálogo e guarda o que é
/// próprio daquele treino, como as séries, a faixa de repetições e o descanso.
class WorkoutExercise {
  Exercise exercise;

  /// Séries planejadas, na ordem de execução. Nunca fica vazia.
  List<PlannedSet> plannedSets;
  String load;
  int restSeconds;

  WorkoutExercise({
    required this.exercise,
    this.plannedSets = _defaultPlannedSets,
    this.load = '—',
    this.restSeconds = 60,
  }) : assert(plannedSets.isNotEmpty, 'O exercício precisa de ao menos uma série.');

  String get name => exercise.name;
  String get muscle => exercise.muscle;

  /// Resumo das séries, agrupando faixas seguidas iguais
  /// (ex: "4 × 8–10" ou "1 × 15–20 + 3 × 8–10").
  String get setsLabel {
    final parts = <String>[];
    var count = 0;
    for (var i = 0; i < plannedSets.length; i++) {
      count++;
      final isLast = i == plannedSets.length - 1;
      if (isLast || plannedSets[i + 1].repsLabel != plannedSets[i].repsLabel) {
        parts.add('$count × ${plannedSets[i].repsLabel}');
        count = 0;
      }
    }
    return parts.join(' + ');
  }

  String get restLabel => restSeconds >= 60 && restSeconds % 60 == 0
      ? '${restSeconds ~/ 60} min'
      : '${restSeconds}s';

  Map<String, dynamic> toMap() => {
        'exercise': exercise.toMap(),
        'plannedSets': plannedSets.map((s) => s.toMap()).toList(),
        'load': load,
        'restSeconds': restSeconds,
      };

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    final planned = (map['plannedSets'] as List?)
        ?.map((s) => PlannedSet.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    return WorkoutExercise(
      exercise: Exercise.fromMap(
        Map<String, dynamic>.from(map['exercise'] as Map? ?? const {}),
      ),
      plannedSets: planned == null || planned.isEmpty
          ? _defaultPlannedSets
          : planned,
      load: map['load'] as String? ?? '—',
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
    );
  }
}

class WorkoutPlan {
  String id;
  String name; // A, B, C...
  String focus; // "Peito e tríceps"
  List<WorkoutExercise> exercises;
  List<String> assignedStudents;
  String notes;
  double weeklyCompletion; // 0..1 (acompanhamento do treinador)

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.focus,
    List<WorkoutExercise>? exercises,
    List<String>? assignedStudents,
    this.notes = '',
    this.weeklyCompletion = 0,
  })  : exercises = exercises ?? [],
        assignedStudents = assignedStudents ?? [];
}

/// Tipos de série, cada um com sua cor na interface.
/// Apenas [working] conta como série válida para fins de evolução.
enum SetType {
  warmup('Aquecimento', Color(0xFF757575)), // Cinza
  feeder('Reconhecimento', Color(0xFF8E24AA)), // Roxo
  working('Trabalho', Color(0xFF1E88E5)); // Azul

  final String label;
  final Color color;
  const SetType(this.label, this.color);
}

/// Etiqueta do drop set, que não é um tipo: complementa uma série de
/// Trabalho ou Aquecimento. A cor própria evita confusão com o Reconhecimento.
const dropSetLabel = 'Drop set';
const dropSetColor = Color(0xFF00897B); // Verde-azulado

/// Formata um número sem casas decimais quando for um valor inteiro.
String _formatNumber(double value) =>
    '${value == value.roundToDouble() ? value.toInt() : value}';

/// Formata uma carga em kg (ex: "57.5 kg").
String _formatKg(double value) => '${_formatNumber(value)} kg';

/// Etapa seguinte de um drop set: nova carga e repetições feitas nela.
/// Os dois valores aceitam apenas passos de 0,5.
class DropStage {
  final double loadKg;
  final double reps;

  const DropStage({required this.loadKg, required this.reps})
    : assert(
        loadKg >= 0 && (loadKg * 2) % 1 == 0,
        'A carga deve ser positiva e variar de 0,5 em 0,5.',
      ),
      assert(
        reps >= 0 && (reps * 2) % 1 == 0,
        'As repetições devem ser positivas e variar de 0,5 em 0,5.',
      );

  Map<String, dynamic> toMap() => {'loadKg': loadKg, 'reps': reps};

  factory DropStage.fromMap(Map<String, dynamic> map) {
    return DropStage(
      loadKg: (map['loadKg'] as num?)?.toDouble() ?? 0,
      reps: (map['reps'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExecutedSet {
  final int setNumber;
  final SetType type;

  /// Carga em kg, em passos de 0,5. Em um drop set, é a carga da primeira etapa.
  final double loadKg;

  /// Repetições realizadas, em passos de 0,5. Em um drop set, são as da primeira etapa.
  final double reps;
  final bool completed;

  /// Indica se a série tem drop set. Não pode acompanhar [SetType.feeder].
  final bool isDropSet;

  /// Etapas do drop set depois da primeira.
  final List<DropStage> dropStages;

  const ExecutedSet({
    required this.setNumber,
    this.type = SetType.working,
    required this.loadKg,
    required this.reps,
    this.completed = true,
    this.isDropSet = false,
    this.dropStages = const [],
  }) : assert(
         loadKg >= 0 && (loadKg * 2) % 1 == 0,
         'A carga deve ser positiva e variar de 0,5 em 0,5.',
       ),
       assert(
         reps >= 0 && (reps * 2) % 1 == 0,
         'As repetições devem ser positivas e variar de 0,5 em 0,5.',
       ),
       assert(
         !isDropSet || type != SetType.feeder,
         'Drop set só pode acompanhar séries de Trabalho ou Aquecimento.',
       );

  /// Carga com unidade, incluindo as etapas do drop set (ex: "40 kg / 30 kg").
  String get loadLabel => [
    _formatKg(loadKg),
    for (final stage in dropStages) _formatKg(stage.loadKg),
  ].join(' / ');

  /// Repetições, incluindo as etapas do drop set (ex: "12 + 6").
  String get repsLabel => [
    _formatNumber(reps),
    for (final stage in dropStages) _formatNumber(stage.reps),
  ].join(' + ');

  ExecutedSet copyWith({
    int? setNumber,
    SetType? type,
    double? loadKg,
    double? reps,
    bool? completed,
    bool? isDropSet,
    List<DropStage>? dropStages,
  }) {
    return ExecutedSet(
      setNumber: setNumber ?? this.setNumber,
      type: type ?? this.type,
      loadKg: loadKg ?? this.loadKg,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
      isDropSet: isDropSet ?? this.isDropSet,
      dropStages: dropStages ?? this.dropStages,
    );
  }

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        'type': type.name,
        'loadKg': loadKg,
        'reps': reps,
        'completed': completed,
        'isDropSet': isDropSet,
        'dropStages': dropStages.map((s) => s.toMap()).toList(),
      };

  factory ExecutedSet.fromMap(Map<String, dynamic> map) {
    return ExecutedSet(
      setNumber: (map['setNumber'] as num?)?.toInt() ?? 1,
      type: SetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SetType.working,
      ),
      loadKg: (map['loadKg'] as num?)?.toDouble() ?? 0,
      reps: (map['reps'] as num?)?.toDouble() ?? 0,
      completed: map['completed'] as bool? ?? true,
      isDropSet: map['isDropSet'] as bool? ?? false,
      dropStages: (map['dropStages'] as List?)
              ?.map((s) =>
                  DropStage.fromMap(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          const [],
    );
  }
}

class ExecutedExercise {
  final String name;
  final String muscle;
  final List<ExecutedSet> sets;
  final bool completed;
  final String? notes;

  const ExecutedExercise({
    required this.name,
    this.muscle = '',
    this.sets = const [],
    this.completed = true,
    this.notes,
  });

  ExecutedExercise copyWith({
    String? name,
    String? muscle,
    List<ExecutedSet>? sets,
    bool? completed,
    String? notes,
  }) {
    return ExecutedExercise(
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      sets: sets ?? this.sets,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'muscle': muscle,
        'sets': sets.map((s) => s.toMap()).toList(),
        'completed': completed,
        'notes': notes,
      };

  factory ExecutedExercise.fromMap(Map<String, dynamic> map) {
    return ExecutedExercise(
      name: map['name'] as String? ?? '',
      muscle: map['muscle'] as String? ?? '',
      sets: (map['sets'] as List?)
              ?.map((s) =>
                  ExecutedSet.fromMap(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          const [],
      completed: map['completed'] as bool? ?? true,
      notes: map['notes'] as String?,
    );
  }
}

class CompletedWorkout {
  final String? id;
  final DateTime date;
  final String plan;
  final int minutes;
  final String? chartName;
  final String? workoutName;
  final List<ExecutedExercise> executedExercises;

  const CompletedWorkout(
    this.date,
    this.plan,
    this.minutes, {
    this.id,
    this.chartName,
    this.workoutName,
    this.executedExercises = const [],
  });

  String get displayWorkoutName =>
      workoutName ?? (plan.startsWith('Treino') ? plan : 'Treino $plan');

  String get displayChartName => chartName ?? 'Training Charts 1';

  String get weekdayName {
    const days = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return days[date.weekday - 1];
  }

  CompletedWorkout copyWith({
    String? id,
    DateTime? date,
    String? plan,
    int? minutes,
    String? chartName,
    String? workoutName,
    List<ExecutedExercise>? executedExercises,
  }) {
    return CompletedWorkout(
      date ?? this.date,
      plan ?? this.plan,
      minutes ?? this.minutes,
      id: id ?? this.id,
      chartName: chartName ?? this.chartName,
      workoutName: workoutName ?? this.workoutName,
      executedExercises: executedExercises ?? this.executedExercises,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'plan': plan,
        'minutes': minutes,
        'chartName': chartName,
        'workoutName': workoutName,
        'executedExercises': executedExercises.map((e) => e.toMap()).toList(),
      };

  factory CompletedWorkout.fromMap(Map<String, dynamic> map) {
    return CompletedWorkout(
      map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      map['plan'] as String? ?? '',
      (map['minutes'] as num?)?.toInt() ?? 0,
      id: map['id'] as String?,
      chartName: map['chartName'] as String?,
      workoutName: map['workoutName'] as String?,
      executedExercises: (map['executedExercises'] as List?)
              ?.map((e) =>
                  ExecutedExercise.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}

class PersonalRecord {
  final String exercise;
  final String value;
  final DateTime date;
  const PersonalRecord(this.exercise, this.value, this.date);
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  const Achievement(this.title, this.description, this.icon, this.unlocked);
}

class StudentProfile {
  // Informações pessoais
  final String name;
  final String email;
  final String phone;
  final DateTime birthDate;
  final String? sex; // opcional
  final DateTime enrollmentDate;
  final String plan;
  final bool enrollmentActive;
  final String? photoUrl;

  // Dados físicos e objetivos (PRIVADOS)
  final double heightCm;
  final FitnessGoal goal;
  final double? targetWeight; // opcional
  final int weeklyTarget; // treinos/semana planejados
  final List<WeightEntry> weightHistory;
  final List<Assessment> assessments;

  // Treino
  final List<WorkoutPlan> workouts;
  final List<int> trainingDays; // 0 = seg ... 6 = dom
  final String nextWorkoutLabel;
  final String trainerName;
  final List<CompletedWorkout> history;

  // Progresso
  final int totalWorkouts;
  final List<int> monthlyFrequency; // últimos 6 meses
  final List<String> monthLabels;
  final int streakWeeks;
  final List<PersonalRecord> records;
  final List<String> goalsReached;
  final List<BodyMeasure> measures;
  final List<Achievement> achievements;

  const StudentProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    this.sex,
    required this.enrollmentDate,
    required this.plan,
    required this.enrollmentActive,
    this.photoUrl,
    required this.heightCm,
    required this.goal,
    this.targetWeight,
    required this.weeklyTarget,
    required this.weightHistory,
    required this.assessments,
    required this.workouts,
    required this.trainingDays,
    required this.nextWorkoutLabel,
    required this.trainerName,
    required this.history,
    required this.totalWorkouts,
    required this.monthlyFrequency,
    required this.monthLabels,
    required this.streakWeeks,
    required this.records,
    required this.goalsReached,
    required this.measures,
    required this.achievements,
  });

  double get currentWeight => weightHistory.last.kg;

  /// Treinos concluídos na semana corrente (mock: últimos 7 dias).
  int get doneThisWeek =>
      history.where((h) => DateTime.now().difference(h.date).inDays < 7).length;

  static StudentProfile sample({String? name, String? email, String? photo}) {
    return StudentProfile(
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : 'Bernardo Almeida',
      email: (email != null && email.isNotEmpty)
          ? email
          : 'bernardo@email.com',
      phone: '(55) 99999-1234',
      photoUrl: photo,
      birthDate: DateTime(1999, 4, 12),
      sex: 'Masculino',
      enrollmentDate: DateTime(2025, 3, 10),
      plan: 'Plano Trimestral',
      enrollmentActive: true,
      heightCm: 178,
      goal: FitnessGoal.hypertrophy,
      targetWeight: 82,
      weeklyTarget: 5,
      weightHistory: [
        WeightEntry(DateTime(2026, 4, 1), 74.5),
        WeightEntry(DateTime(2026, 5, 1), 75.2),
        WeightEntry(DateTime(2026, 6, 1), 76.0),
        WeightEntry(DateTime(2026, 7, 1), 76.8),
        WeightEntry(DateTime(2026, 8, 1), 77.9),
        WeightEntry(DateTime(2026, 9, 1), 78.4),
        WeightEntry(DateTime(2026, 10, 1), 79.1),
      ],
      assessments: [
        Assessment(DateTime(2026, 9, 5), 78.6, 14.2,
            'Boa evolução de massa magra. Manter a progressão de carga.'),
        Assessment(DateTime(2026, 6, 4), 76.1, 15.8,
            'Ajustar o treino de pernas e aumentar o consumo de proteína.'),
        Assessment(DateTime(2026, 3, 10), 74.5, 17.0, 'Avaliação inicial.'),
      ],
      workouts: [
        WorkoutPlan(
          id: 'a',
          name: 'A',
          focus: 'Peito e tríceps',
          exercises: [
            WorkoutExercise(
                exercise: Exercise(name: 'Supino reto', muscle: 'Peito'),
                plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
                load: '60 kg',
                restSeconds: 90),
            WorkoutExercise(
                exercise: Exercise(name: 'Supino inclinado com halteres', muscle: 'Peito'),
                plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
                load: '24 kg',
                restSeconds: 75),
            WorkoutExercise(
                exercise: Exercise(name: 'Crucifixo na máquina', muscle: 'Peito'),
                plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
                load: '40 kg',
                restSeconds: 60),
            WorkoutExercise(
                exercise: Exercise(name: 'Tríceps testa', muscle: 'Tríceps'),
                plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
                load: '25 kg',
                restSeconds: 60),
            WorkoutExercise(
                exercise: Exercise(name: 'Tríceps na polia', muscle: 'Tríceps'),
                plannedSets: PlannedSet.repeat(3, minReps: 12, maxReps: 15),
                load: '30 kg',
                restSeconds: 45),
          ],
        ),
        WorkoutPlan(
          id: 'b',
          name: 'B',
          focus: 'Costas e bíceps',
          exercises: [
            WorkoutExercise(
                exercise: Exercise(name: 'Puxada frontal', muscle: 'Costas'),
                plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
                load: '55 kg',
                restSeconds: 90),
            WorkoutExercise(
                exercise: Exercise(name: 'Remada curvada', muscle: 'Costas'),
                plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
                load: '50 kg',
                restSeconds: 90),
            WorkoutExercise(
                exercise: Exercise(name: 'Rosca direta', muscle: 'Bíceps'),
                plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
                load: '30 kg',
                restSeconds: 60),
            WorkoutExercise(
                exercise: Exercise(name: 'Rosca martelo', muscle: 'Bíceps'),
                plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
                load: '14 kg',
                restSeconds: 60),
          ],
        ),
        WorkoutPlan(
          id: 'c',
          name: 'C',
          focus: 'Pernas e ombros',
          exercises: [
            WorkoutExercise(
                exercise: Exercise(name: 'Agachamento livre', muscle: 'Quadríceps'),
                plannedSets: PlannedSet.repeat(4, minReps: 6, maxReps: 8),
                load: '80 kg',
                restSeconds: 120),
            WorkoutExercise(
                exercise: Exercise(name: 'Leg press 45°', muscle: 'Quadríceps'),
                plannedSets: PlannedSet.repeat(4, minReps: 10, maxReps: 12),
                load: '180 kg',
                restSeconds: 90),
            WorkoutExercise(
                exercise: Exercise(name: 'Desenvolvimento com halteres', muscle: 'Ombros'),
                plannedSets: PlannedSet.repeat(3, minReps: 8, maxReps: 10),
                load: '20 kg',
                restSeconds: 75),
            WorkoutExercise(
                exercise: Exercise(name: 'Elevação lateral', muscle: 'Ombros'),
                plannedSets: PlannedSet.repeat(3, minReps: 12, maxReps: 15),
                load: '8 kg',
                restSeconds: 45),
          ],
        ),
      ],
      trainingDays: [0, 1, 3, 4, 5],
      nextWorkoutLabel: 'Treino B — Costas e bíceps',
      trainerName: 'Carla Menezes',
      history: [
        CompletedWorkout(_daysAgo(1), 'A', 62),
        CompletedWorkout(_daysAgo(3), 'C', 71),
        CompletedWorkout(_daysAgo(4), 'B', 58),
        CompletedWorkout(_daysAgo(6), 'A', 64),
        CompletedWorkout(_daysAgo(8), 'C', 69),
      ],
      totalWorkouts: 148,
      monthlyFrequency: [14, 16, 18, 15, 19, 17],
      monthLabels: ['Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out'],
      streakWeeks: 7,
      records: [
        PersonalRecord('Supino reto', '70 kg × 5', DateTime(2026, 9, 18)),
        PersonalRecord('Agachamento livre', '100 kg × 5', DateTime(2026, 9, 25)),
        PersonalRecord('Levantamento terra', '120 kg × 3', DateTime(2026, 8, 30)),
      ],
      goalsReached: [
        'Treinar 4x por semana por 1 mês',
        'Chegar a 75 kg',
        'Supino com 60 kg',
      ],
      measures: [
        BodyMeasure(DateTime(2026, 9, 5), 101, 82, 98, 36.5, 58),
        BodyMeasure(DateTime(2026, 6, 4), 98, 83, 97, 35, 56.5),
        BodyMeasure(DateTime(2026, 3, 10), 95, 85, 96, 33.5, 55),
      ],
      achievements: [
        Achievement('Primeiro treino', 'Concluiu o 1º treino', Icons.flag, true),
        Achievement('Sequência de 7 semanas', 'Treinou 7 semanas seguidas',
            Icons.local_fire_department, true),
        Achievement('100 treinos', 'Chegou a 100 treinos concluídos',
            Icons.emoji_events, true),
        Achievement('Meta de peso', 'Atingir a meta de peso',
            Icons.monitor_weight, false),
        Achievement('Madrugador', '20 treinos antes das 7h', Icons.wb_sunny, false),
        Achievement('200 treinos', 'Chegar a 200 treinos', Icons.military_tech,
            false),
      ],
    );
  }
}



enum TrainerRole {
  instructor('Instrutor'),
  personal('Personal trainer'),
  admin('Administrador');

  final String label;
  const TrainerRole(this.label);
}

class StudentSummary {
  final String id;
  final String name;
  final FitnessGoal goal;
  final String currentWorkout;
  final DateTime lastAssessment;
  final DateTime nextFollowUp;
  final String planName;
  final bool enrollmentActive;
  final int doneThisWeek;
  final int weeklyTarget;

  const StudentSummary({
    required this.id,
    required this.name,
    required this.goal,
    required this.currentWorkout,
    required this.lastAssessment,
    required this.nextFollowUp,
    required this.planName,
    required this.enrollmentActive,
    required this.doneThisWeek,
    required this.weeklyTarget,
  });

  bool get needsReassessment =>
      DateTime.now().difference(lastAssessment).inDays > 60;
}

enum AppointmentType {
  followUp('Acompanhamento', Icons.visibility_outlined),
  assessment('Avaliação física', Icons.monitor_heart_outlined),
  personal('Sessão de personal', Icons.sports_gymnastics);

  final String label;
  final IconData icon;
  const AppointmentType(this.label, this.icon);
}

enum AppointmentStatus { scheduled, done, missed }

class Appointment {
  final String id;
  final int day; // 0 = seg ... 6 = dom
  final String time;
  final String student;
  final AppointmentType type;
  AppointmentStatus status;

  Appointment({
    required this.id,
    required this.day,
    required this.time,
    required this.student,
    required this.type,
    this.status = AppointmentStatus.scheduled,
  });
}

class TrainerProfile {
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final TrainerRole role;
  final String? cref;
  final List<String> specialties;
  final List<String> qualifications;
  final int experienceYears;
  final Map<String, String> availability; // dia → horário
  final bool employmentActive;

  /// Permissão para ver a situação do plano/matrícula dos alunos.
  final bool canViewBilling;

  final List<StudentSummary> students;
  final List<WorkoutPlan> plans;
  final List<Appointment> appointments;
  final List<String> newStudents;

  const TrainerProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.role,
    this.cref,
    required this.specialties,
    required this.qualifications,
    required this.experienceYears,
    required this.availability,
    required this.employmentActive,
    required this.canViewBilling,
    required this.students,
    required this.plans,
    required this.appointments,
    required this.newStudents,
  });

  static TrainerProfile sample({String? name, String? email, String? photo}) {
    return TrainerProfile(
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : 'Carla Menezes',
      email: (email != null && email.isNotEmpty)
          ? email
          : 'carla.menezes@academia.com',
      photoUrl: photo,
      phone: '(55) 98888-4321',
      role: TrainerRole.personal,
      cref: '012345-G/RS',
      specialties: ['Musculação', 'Hipertrofia', 'Funcional', 'Emagrecimento'],
      qualifications: [
        'Bacharelado em Educação Física — UFSM',
        'Pós-graduação em Fisiologia do Exercício',
        'Certificação em Avaliação Física',
      ],
      experienceYears: 8,
      availability: {
        'Seg a Sex': '06h às 12h e 15h às 20h',
        'Sábado': '08h às 12h',
      },
      employmentActive: true,
      canViewBilling: true,
      students: [
        StudentSummary(
          id: '1',
          name: 'Bernardo Almeida',
          goal: FitnessGoal.hypertrophy,
          currentWorkout: 'Treino B',
          lastAssessment: _daysAgo(34),
          nextFollowUp: _inDays(5),
          planName: 'Trimestral',
          enrollmentActive: true,
          doneThisWeek: 4,
          weeklyTarget: 5,
        ),
        StudentSummary(
          id: '2',
          name: 'Marina Souza',
          goal: FitnessGoal.weightLoss,
          currentWorkout: 'Treino A',
          lastAssessment: _daysAgo(75),
          nextFollowUp: _inDays(2),
          planName: 'Mensal',
          enrollmentActive: true,
          doneThisWeek: 3,
          weeklyTarget: 4,
        ),
        StudentSummary(
          id: '3',
          name: 'Lucas Pereira',
          goal: FitnessGoal.conditioning,
          currentWorkout: 'Treino C',
          lastAssessment: _daysAgo(20),
          nextFollowUp: _inDays(10),
          planName: 'Anual',
          enrollmentActive: true,
          doneThisWeek: 2,
          weeklyTarget: 3,
        ),
        StudentSummary(
          id: '4',
          name: 'Ana Beatriz Lima',
          goal: FitnessGoal.health,
          currentWorkout: 'Treino A',
          lastAssessment: _daysAgo(90),
          nextFollowUp: _inDays(1),
          planName: 'Mensal',
          enrollmentActive: false,
          doneThisWeek: 0,
          weeklyTarget: 3,
        ),
        StudentSummary(
          id: '5',
          name: 'Rafael Costa',
          goal: FitnessGoal.hypertrophy,
          currentWorkout: 'Treino B',
          lastAssessment: _daysAgo(45),
          nextFollowUp: _inDays(7),
          planName: 'Semestral',
          enrollmentActive: true,
          doneThisWeek: 5,
          weeklyTarget: 5,
        ),
      ],
      plans: [
        WorkoutPlan(
          id: 'p1',
          name: 'A',
          focus: 'Peito e tríceps',
          assignedStudents: ['Bernardo Almeida', 'Rafael Costa', 'Marina Souza'],
          weeklyCompletion: 0.75,
          exercises: [
            WorkoutExercise(
                exercise: Exercise(name: 'Supino reto', muscle: 'Peito'),
                plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
                load: '40 kg',
                restSeconds: 90),
            WorkoutExercise(
                exercise: Exercise(name: 'Tríceps na polia', muscle: 'Tríceps'),
                plannedSets: PlannedSet.repeat(3, minReps: 12, maxReps: 15),
                load: '20 kg',
                restSeconds: 45),
          ],
        ),
        WorkoutPlan(
          id: 'p2',
          name: 'B',
          focus: 'Costas e bíceps',
          assignedStudents: ['Bernardo Almeida', 'Lucas Pereira'],
          weeklyCompletion: 0.5,
          notes: 'Atenção à postura na remada.',
          exercises: [
            WorkoutExercise(
                exercise: Exercise(name: 'Puxada frontal', muscle: 'Costas'),
                plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
                load: '40 kg',
                restSeconds: 90),
            WorkoutExercise(
                exercise: Exercise(name: 'Rosca direta', muscle: 'Bíceps'),
                plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
                load: '20 kg',
                restSeconds: 60),
          ],
        ),
      ],
      appointments: [
        Appointment(
            id: 'a1',
            day: 0,
            time: '07:00',
            student: 'Bernardo Almeida',
            type: AppointmentType.personal),
        Appointment(
            id: 'a2',
            day: 0,
            time: '09:30',
            student: 'Marina Souza',
            type: AppointmentType.assessment),
        Appointment(
            id: 'a3',
            day: 0,
            time: '16:00',
            student: 'Lucas Pereira',
            type: AppointmentType.followUp),
        Appointment(
            id: 'a4',
            day: 1,
            time: '08:00',
            student: 'Rafael Costa',
            type: AppointmentType.personal),
        Appointment(
            id: 'a5',
            day: 2,
            time: '18:00',
            student: 'Ana Beatriz Lima',
            type: AppointmentType.assessment),
        Appointment(
            id: 'a6',
            day: 3,
            time: '07:30',
            student: 'Bernardo Almeida',
            type: AppointmentType.followUp),
        Appointment(
            id: 'a7',
            day: 4,
            time: '17:00',
            student: 'Marina Souza',
            type: AppointmentType.personal),
        Appointment(
            id: 'a8',
            day: 5,
            time: '09:00',
            student: 'Lucas Pereira',
            type: AppointmentType.personal),
      ],
      newStudents: ['Felipe Andrade', 'Juliana Rocha'],
    );
  }
}