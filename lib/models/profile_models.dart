import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modelos dos perfis de aluno e treinador e dos treinos.

enum UserRole { student, trainer }

// ───────────────────────── Utilitários ─────────────────────────

/// Texto exibido no lugar de um dado que o usuário ainda não cadastrou.
const notInformed = 'Não informado';

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

  /// Lê uma faixa digitada como "8-10". Séries de Reconhecimento também
  /// aceitam um valor único, como "2". Retorna null se o formato for inválido,
  /// se começar em zero ou se o mínimo for maior que o máximo.
  static PlannedSet? tryParse(String text, {SetType type = SetType.working}) {
    final match = RegExp(
      r'^\s*(\d{1,3})\s*(?:[-–]\s*(\d{1,3})\s*)?$',
    ).firstMatch(text);
    if (match == null) return null;
    if (match.group(2) == null && type != SetType.feeder) return null;

    final min = int.parse(match.group(1)!);
    final max = int.parse(match.group(2) ?? match.group(1)!);
    if (min < 1 || min > max) return null;

    return PlannedSet(type: type, minReps: min, maxReps: max);
  }

  /// Faixa para exibição (ex: "8–10").
  String get repsLabel => minReps == maxReps ? '$minReps' : '$minReps–$maxReps';

  /// Faixa no formato aceito por [tryParse] (ex: "8-10").
  String get repsInput => type == SetType.feeder && minReps == maxReps
      ? '$minReps'
      : '$minReps-$maxReps';

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
  /// Identificador fixo no catálogo, usado para referenciar o exercício.
  String? id;
  String name;
  String muscle;
  String? nameEn;
  String? primaryMuscle;
  List<String> highActivationMuscles;
  List<String> secondaryMuscles;
  String? equipment;
  String? instructions;

  Exercise({
    this.id,
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
    String? id,
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
      id: id ?? this.id,
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
        'id': id,
        'name': name,
        'muscle': muscle,
        'nameEn': nameEn,
        'primaryMuscle': primaryMuscle,
        'highActivationMuscles': highActivationMuscles,
        'secondaryMuscles': secondaryMuscles,
        'equipment': equipment,
        'instructions': instructions,
      };

  /// [id] é o identificador do documento no Firestore.
  factory Exercise.fromMap(String id, Map<String, dynamic> map) {
    return Exercise(
      id: id,
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

/// Busca um exercício do catálogo pelo identificador.
typedef ExerciseLookup = Exercise? Function(String id);

const _defaultPlannedSets = [
  PlannedSet(minReps: 10, maxReps: 12),
  PlannedSet(minReps: 10, maxReps: 12),
  PlannedSet(minReps: 10, maxReps: 12),
];

/// Exercício dentro de um treino: referencia o catálogo e guarda o que é
/// próprio daquele treino, como as séries, a faixa de repetições e o descanso.
/// A carga não fica aqui: ela só é informada durante a execução.
class WorkoutExercise {
  Exercise exercise;

  /// Séries planejadas, na ordem de execução. Nunca fica vazia.
  List<PlannedSet> plannedSets;

  /// Descanso sugerido em segundos. É opcional: null quando não há sugestão.
  int? restSeconds;

  WorkoutExercise({
    required this.exercise,
    this.plannedSets = _defaultPlannedSets,
    this.restSeconds,
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

  /// Descanso para exibição (ex: "45s", "2 min" ou "1 min 35s").
  /// É null quando o exercício não tem descanso sugerido.
  String? get restLabel {
    final rest = restSeconds;
    if (rest == null) return null;

    final minutes = rest ~/ 60;
    final seconds = rest % 60;

    if (minutes == 0) return '${seconds}s';
    return seconds == 0 ? '$minutes min' : '$minutes min ${seconds}s';
  }

  /// Guarda só a referência ao catálogo, sem duplicar os dados do exercício.
  Map<String, dynamic> toMap() {
    assert(exercise.id != null, 'Só exercícios do catálogo podem ser salvos.');

    return {
      'exerciseId': exercise.id,
      'plannedSets': plannedSets.map((s) => s.toMap()).toList(),
      if (restSeconds != null) 'restSeconds': restSeconds,
    };
  }

  /// Recupera os dados do exercício com [findExercise]. Se ele não existir
  /// mais no catálogo, mantém a série planejada com um nome provisório.
  factory WorkoutExercise.fromMap(
    Map<String, dynamic> map, {
    required ExerciseLookup findExercise,
  }) {
    final exerciseId = map['exerciseId'] as String? ?? '';
    final planned = (map['plannedSets'] as List?)
        ?.map((s) => PlannedSet.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    return WorkoutExercise(
      exercise: findExercise(exerciseId) ??
          Exercise(id: exerciseId, name: 'Exercício indisponível'),
      plannedSets: planned == null || planned.isEmpty
          ? _defaultPlannedSets
          : planned,
      restSeconds: (map['restSeconds'] as num?)?.toInt(),
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
  /// Referência ao catálogo, usada para calcular a evolução por músculo.
  final String? exerciseId;

  /// Nome e músculo guardados como foram no dia do treino.
  final String name;
  final String muscle;
  final List<ExecutedSet> sets;
  final bool completed;
  final String? notes;

  const ExecutedExercise({
    this.exerciseId,
    required this.name,
    this.muscle = '',
    this.sets = const [],
    this.completed = true,
    this.notes,
  });

  ExecutedExercise copyWith({
    String? exerciseId,
    String? name,
    String? muscle,
    List<ExecutedSet>? sets,
    bool? completed,
    String? notes,
  }) {
    return ExecutedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      sets: sets ?? this.sets,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        if (exerciseId != null) 'exerciseId': exerciseId,
        'name': name,
        'muscle': muscle,
        'sets': sets.map((s) => s.toMap()).toList(),
        'completed': completed,
        if (notes != null) 'notes': notes,
      };

  factory ExecutedExercise.fromMap(Map<String, dynamic> map) {
    return ExecutedExercise(
      exerciseId: map['exerciseId'] as String?,
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

  /// Planilha e dia do ciclo treinados, usados para calcular o próximo treino.
  final String? chartId;
  final String? dayId;
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
    this.chartId,
    this.dayId,
    this.chartName,
    this.workoutName,
    this.executedExercises = const [],
  });

  String get displayWorkoutName =>
      workoutName ?? (plan.startsWith('Treino') ? plan : 'Treino $plan');

  String get displayChartName => chartName ?? 'Planilha';

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
    String? chartId,
    String? dayId,
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
      chartId: chartId ?? this.chartId,
      dayId: dayId ?? this.dayId,
      chartName: chartName ?? this.chartName,
      workoutName: workoutName ?? this.workoutName,
      executedExercises: executedExercises ?? this.executedExercises,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'plan': plan,
        'minutes': minutes,
        if (chartId != null) 'chartId': chartId,
        if (dayId != null) 'dayId': dayId,
        if (chartName != null) 'chartName': chartName,
        if (workoutName != null) 'workoutName': workoutName,
        'executedExercises': executedExercises.map((e) => e.toMap()).toList(),
      };

  /// [id] é o identificador do documento no Firestore.
  factory CompletedWorkout.fromMap(String id, Map<String, dynamic> map) {
    return CompletedWorkout(
      (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      map['plan'] as String? ?? '',
      (map['minutes'] as num?)?.toInt() ?? 0,
      id: id,
      chartId: map['chartId'] as String?,
      dayId: map['dayId'] as String?,
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
  // Informações pessoais: nome e e-mail vêm da conta; o resto só se cadastrado
  final String name;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final String? sex;
  final DateTime? enrollmentDate;
  final String? plan;
  final bool? enrollmentActive;
  final String? photoUrl;

  // Dados físicos e objetivos (PRIVADOS)
  final double? heightCm;
  final FitnessGoal? goal;
  final double? targetWeight;
  final int? weeklyTarget; // treinos/semana planejados
  final List<WeightEntry> weightHistory;
  final List<Assessment> assessments;

  // Treino
  final List<WorkoutPlan> workouts;
  final List<int> trainingDays; // 0 = seg ... 6 = dom
  final String? trainerName;

  // Progresso
  final List<PersonalRecord> records;
  final List<String> goalsReached;
  final List<BodyMeasure> measures;
  final List<Achievement> achievements;

  const StudentProfile({
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.sex,
    this.enrollmentDate,
    this.plan,
    this.enrollmentActive,
    this.photoUrl,
    this.heightCm,
    this.goal,
    this.targetWeight,
    this.weeklyTarget,
    this.weightHistory = const [],
    this.assessments = const [],
    this.workouts = const [],
    this.trainingDays = const [],
    this.trainerName,
    this.records = const [],
    this.goalsReached = const [],
    this.measures = const [],
    this.achievements = const [],
  });

  /// Peso mais recente; null se nenhum foi registrado.
  double? get currentWeight =>
      weightHistory.isEmpty ? null : weightHistory.last.kg;
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
  // Nome e e-mail vêm da conta; o resto só aparece se tiver sido cadastrado
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final TrainerRole? role;
  final String? cref;
  final List<String> specialties;
  final List<String> qualifications;
  final int? experienceYears;
  final Map<String, String> availability; // dia → horário
  final bool? employmentActive;

  /// Permissão para ver a situação do plano/matrícula dos alunos.
  final bool canViewBilling;

  final List<StudentSummary> students;
  final List<WorkoutPlan> plans;
  final List<Appointment> appointments;
  final List<String> newStudents;

  const TrainerProfile({
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.role,
    this.cref,
    this.specialties = const [],
    this.qualifications = const [],
    this.experienceYears,
    this.availability = const {},
    this.employmentActive,
    this.canViewBilling = false,
    this.students = const [],
    this.plans = const [],
    this.appointments = const [],
    this.newStudents = const [],
  });
}