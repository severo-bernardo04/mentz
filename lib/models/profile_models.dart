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

class Exercise {
  String name;
  String muscle;
  int sets;
  String reps;
  String load;
  int restSeconds;

  Exercise({
    required this.name,
    this.muscle = '',
    this.sets = 3,
    this.reps = '12',
    this.load = '—',
    this.restSeconds = 60,
  });

  String get restLabel => restSeconds >= 60 && restSeconds % 60 == 0
      ? '${restSeconds ~/ 60} min'
      : '${restSeconds}s';
}

class WorkoutPlan {
  String id;
  String name; // A, B, C...
  String focus; // "Peito e tríceps"
  List<Exercise> exercises;
  List<String> assignedStudents;
  String notes;
  double weeklyCompletion; // 0..1 (acompanhamento do treinador)

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.focus,
    List<Exercise>? exercises,
    List<String>? assignedStudents,
    this.notes = '',
    this.weeklyCompletion = 0,
  })  : exercises = exercises ?? [],
        assignedStudents = assignedStudents ?? [];
}

class CompletedWorkout {
  final DateTime date;
  final String plan;
  final int minutes;
  const CompletedWorkout(this.date, this.plan, this.minutes);
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

  static StudentProfile sample({String? name, String? email}) {
    return StudentProfile(
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : 'Bernardo Almeida',
      email: (email != null && email.isNotEmpty)
          ? email
          : 'bernardo@email.com',
      phone: '(55) 99999-1234',
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
            Exercise(
                name: 'Supino reto',
                muscle: 'Peito',
                sets: 4,
                reps: '8-10',
                load: '60 kg',
                restSeconds: 90),
            Exercise(
                name: 'Supino inclinado com halteres',
                muscle: 'Peito',
                sets: 3,
                reps: '10-12',
                load: '24 kg',
                restSeconds: 75),
            Exercise(
                name: 'Crucifixo na máquina',
                muscle: 'Peito',
                sets: 3,
                reps: '12',
                load: '40 kg',
                restSeconds: 60),
            Exercise(
                name: 'Tríceps testa',
                muscle: 'Tríceps',
                sets: 3,
                reps: '12',
                load: '25 kg',
                restSeconds: 60),
            Exercise(
                name: 'Tríceps na polia',
                muscle: 'Tríceps',
                sets: 3,
                reps: '15',
                load: '30 kg',
                restSeconds: 45),
          ],
        ),
        WorkoutPlan(
          id: 'b',
          name: 'B',
          focus: 'Costas e bíceps',
          exercises: [
            Exercise(
                name: 'Puxada frontal',
                muscle: 'Costas',
                sets: 4,
                reps: '10',
                load: '55 kg',
                restSeconds: 90),
            Exercise(
                name: 'Remada curvada',
                muscle: 'Costas',
                sets: 4,
                reps: '8-10',
                load: '50 kg',
                restSeconds: 90),
            Exercise(
                name: 'Rosca direta',
                muscle: 'Bíceps',
                sets: 3,
                reps: '12',
                load: '30 kg',
                restSeconds: 60),
            Exercise(
                name: 'Rosca martelo',
                muscle: 'Bíceps',
                sets: 3,
                reps: '12',
                load: '14 kg',
                restSeconds: 60),
          ],
        ),
        WorkoutPlan(
          id: 'c',
          name: 'C',
          focus: 'Pernas e ombros',
          exercises: [
            Exercise(
                name: 'Agachamento livre',
                muscle: 'Quadríceps',
                sets: 4,
                reps: '8',
                load: '80 kg',
                restSeconds: 120),
            Exercise(
                name: 'Leg press 45°',
                muscle: 'Quadríceps',
                sets: 4,
                reps: '12',
                load: '180 kg',
                restSeconds: 90),
            Exercise(
                name: 'Desenvolvimento com halteres',
                muscle: 'Ombros',
                sets: 3,
                reps: '10',
                load: '20 kg',
                restSeconds: 75),
            Exercise(
                name: 'Elevação lateral',
                muscle: 'Ombros',
                sets: 3,
                reps: '15',
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

  static TrainerProfile sample({String? name, String? email}) {
    return TrainerProfile(
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : 'Carla Menezes',
      email: (email != null && email.isNotEmpty)
          ? email
          : 'carla.menezes@academia.com',
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
            Exercise(
                name: 'Supino reto',
                muscle: 'Peito',
                sets: 4,
                reps: '8-10',
                load: '40 kg',
                restSeconds: 90),
            Exercise(
                name: 'Tríceps na polia',
                muscle: 'Tríceps',
                sets: 3,
                reps: '15',
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
            Exercise(
                name: 'Puxada frontal',
                muscle: 'Costas',
                sets: 4,
                reps: '10',
                load: '40 kg',
                restSeconds: 90),
            Exercise(
                name: 'Rosca direta',
                muscle: 'Bíceps',
                sets: 3,
                reps: '12',
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