import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/profile/trainer/tabs/agenda_tab.dart';
import 'package:mentz/features/profile/trainer/widgets/student_card.dart';
import 'package:mentz/models/app_user.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/exercise_catalog_service.dart';
import 'package:mentz/services/trainer_service.dart';

void main() {
  group('modelos', () {
    test('AppUser lê os dados profissionais do campo trainer', () {
      final user = AppUser.fromMap('t1', {
        'name': 'Carla',
        'email': 'c@c.com',
        'role': 'trainer',
        'trainer': {
          'role': 'personal',
          'cref': '012345-G/RS',
          'specialties': ['Hipertrofia', 'Reabilitação'],
          'qualifications': ['Educação Física - UFSM'],
          'experienceYears': 6,
          'availability': {'Seg a Sex': '06h às 12h'},
          'employmentActive': true,
          'canViewBilling': true,
        },
        'seenStudentIds': ['s1'],
      });

      expect(user.trainerRole, TrainerRole.personal);
      expect(user.cref, '012345-G/RS');
      expect(user.specialties, ['Hipertrofia', 'Reabilitação']);
      expect(user.qualifications, ['Educação Física - UFSM']);
      expect(user.experienceYears, 6);
      expect(user.availability, {'Seg a Sex': '06h às 12h'});
      expect(user.employmentActive, isTrue);
      expect(user.canViewBilling, isTrue);
      expect(user.seenStudentIds, ['s1']);
    });

    test('AppUser sem o campo trainer não inventa dados profissionais', () {
      final user = AppUser.fromMap('t1', {'name': 'Carla', 'role': 'trainer'});

      expect(user.trainerRole, isNull);
      expect(user.cref, isNull);
      expect(user.specialties, isEmpty);
      expect(user.availability, isEmpty);
      expect(user.employmentActive, isNull);
      expect(user.canViewBilling, isFalse);
      expect(user.seenStudentIds, isEmpty);
    });

    test('StudentSummary só preenche o que está no documento', () {
      final s = StudentSummary.fromMap('s1', {'name': 'Ana'});

      expect(s.name, 'Ana');
      expect(s.goal, isNull);
      expect(s.lastAssessment, isNull);
      expect(s.enrollmentActive, isNull);
      expect(s.needsReassessment, isFalse);
    });

    test('StudentSummary pede reavaliação após 60 dias', () {
      final s = StudentSummary.fromMap('s1', {
        'name': 'Ana',
        'goal': 'hypertrophy',
        'lastAssessmentAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 90)),
        ),
      });

      expect(s.goal, FitnessGoal.hypertrophy);
      expect(s.needsReassessment, isTrue);
    });

    test('Appointment usa valores padrão para dados inválidos', () {
      final a = Appointment.fromMap('a1', {
        'day': 12,
        'time': '08:00',
        'student': 'Ana',
        'type': 'inexistente',
        'status': 'inexistente',
      });

      expect(a.day, 6);
      expect(a.type, AppointmentType.followUp);
      expect(a.status, AppointmentStatus.scheduled);
    });

    test('WorkoutPlan vai para o mapa e volta com os mesmos dados', () {
      final bench = Exercise(id: 'supino-reto', name: 'Supino reto');
      final plan = WorkoutPlan(
        id: 'p1',
        name: 'A',
        focus: 'Peito e tríceps',
        exercises: [WorkoutExercise(exercise: bench, restSeconds: 90)],
        assignedStudents: ['Ana'],
        notes: 'Aquecer antes',
        weeklyCompletion: 0.5,
      );

      final copy = WorkoutPlan.fromMap(
        'p1',
        plan.toMap(),
        findExercise: (id) => id == 'supino-reto' ? bench : null,
      );

      expect(copy.name, 'A');
      expect(copy.focus, 'Peito e tríceps');
      expect(copy.exercises.single.name, 'Supino reto');
      expect(copy.exercises.single.restSeconds, 90);
      expect(copy.assignedStudents, ['Ana']);
      expect(copy.notes, 'Aquecer antes');
      expect(copy.weeklyCompletion, 0.5);
    });
  });

  group('TrainerService', () {
    late FakeFirebaseFirestore firestore;
    late TrainerService service;

    setUp(() async {
      ExerciseCatalogService().setExercisesForTest([
        Exercise(id: 'supino-reto', name: 'Supino reto', muscle: 'Peito'),
      ]);

      firestore = FakeFirebaseFirestore();
      await firestore.doc('users/trainer-1').set({
        'name': 'Carla',
        'role': 'trainer',
      });
      await firestore.doc('users/s1').set({
        'name': 'bruno',
        'role': 'student',
        'trainerId': 'trainer-1',
      });
      await firestore.doc('users/s2').set({
        'name': 'Ana',
        'role': 'student',
        'trainerId': 'trainer-1',
      });
      await firestore.doc('users/s3').set({
        'name': 'Carlos',
        'role': 'student',
        'trainerId': 'trainer-2',
      });

      service = TrainerService();
      service.startForTest(firestore, uid: 'trainer-1');
      await pumpEventQueue();
    });

    tearDown(() => service.resetForTest());

    WorkoutPlan buildPlan(String id, {String name = 'A'}) {
      final bench = ExerciseCatalogService().findById('supino-reto')!;
      return WorkoutPlan(
        id: id,
        name: name,
        focus: 'Peito',
        exercises: [WorkoutExercise(exercise: bench)],
      );
    }

    test('termina de carregar mesmo sem fichas nem agenda', () {
      expect(service.loading, isFalse);
      expect(service.plans, isEmpty);
      expect(service.appointments, isEmpty);
      expect(service.errorMessage, isNull);
    });

    test('lista só os alunos vinculados ao treinador, em ordem alfabética', () {
      expect(service.students.map((s) => s.name), ['Ana', 'bruno']);
    });

    test('acompanha novos vínculos em tempo real', () async {
      await firestore.doc('users/s4').set({
        'name': 'Davi',
        'trainerId': 'trainer-1',
      });
      await pumpEventQueue();

      expect(service.students.map((s) => s.name), ['Ana', 'bruno', 'Davi']);
    });

    test('salva a ficha na coleção do treinador e a recarrega', () async {
      await service.savePlan(buildPlan('p1'));
      await pumpEventQueue();

      final doc = await firestore.doc('users/trainer-1/plans/p1').get();
      expect(doc.data()!['name'], 'A');
      expect(doc.data()!['exercises'], hasLength(1));

      expect(service.plans, hasLength(1));
      expect(service.plans.single.exercises.single.name, 'Supino reto');
    });

    test('editar uma ficha substitui a anterior em vez de duplicar', () async {
      await service.savePlan(buildPlan('p1', name: 'A'));
      await service.savePlan(buildPlan('p1', name: 'B'));
      await pumpEventQueue();

      expect(service.plans, hasLength(1));
      expect(service.plans.single.name, 'B');
    });

    test('exclui a ficha', () async {
      await service.savePlan(buildPlan('p1'));
      await service.deletePlan('p1');
      await pumpEventQueue();

      expect(service.plans, isEmpty);
      expect(
        (await firestore.doc('users/trainer-1/plans/p1').get()).exists,
        isFalse,
      );
    });

    test('não mostra fichas de outro treinador', () async {
      await firestore.doc('users/trainer-2/plans/x').set({
        'name': 'Z',
        'focus': '',
        'exercises': [],
      });
      await pumpEventQueue();

      expect(service.plans, isEmpty);
    });

    test('registra a falta sem alterar o resto do compromisso', () async {
      await service.saveAppointment(
        Appointment(
          id: 'a1',
          day: 2,
          time: '08:00',
          student: 'Ana',
          type: AppointmentType.assessment,
        ),
      );
      await pumpEventQueue();
      expect(service.appointments.single.status, AppointmentStatus.scheduled);

      await service.setAppointmentStatus('a1', AppointmentStatus.missed);
      await pumpEventQueue();

      final a = service.appointments.single;
      expect(a.status, AppointmentStatus.missed);
      expect(a.student, 'Ana');
      expect(a.time, '08:00');
      expect(a.day, 2);
      expect(a.type, AppointmentType.assessment);
    });

    test('marcar o aluno como visto guarda o id sem apagar o perfil', () async {
      await service.markStudentSeen('s1');
      await service.markStudentSeen('s2');
      await service.markStudentSeen('s1');

      final data = (await firestore.doc('users/trainer-1').get()).data()!;
      expect(data['seenStudentIds'], unorderedEquals(['s1', 's2']));
      expect(data['name'], 'Carla');
      expect(data['role'], 'trainer');
    });

    test('ao parar de acompanhar, limpa os dados da memória', () async {
      await service.savePlan(buildPlan('p1'));
      await pumpEventQueue();
      expect(service.plans, isNotEmpty);

      service.stopWatching('trainer-1');

      expect(service.students, isEmpty);
      expect(service.plans, isEmpty);
      expect(service.appointments, isEmpty);
      expect(service.loading, isFalse);
    });

    test('gravar sem treinador acompanhado falha com erro claro', () {
      service.stopWatching('trainer-1');

      expect(() => service.deletePlan('p1'), throwsStateError);
    });
  });

  group('widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
      await tester.pumpAndSettle();
    }

    testWidgets('cartão do aluno funciona só com nome', (tester) async {
      await pump(
        tester,
        StudentCard(
          student: const StudentSummary(id: 's1', name: 'Ana'),
          showBilling: true,
          onTap: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Objetivo não informado'), findsOneWidget);
      expect(find.text('Reavaliar'), findsNothing);
      expect(find.textContaining('Próx.'), findsNothing);
    });

    testWidgets('cartão do aluno aguenta nome vazio', (tester) async {
      await pump(
        tester,
        StudentCard(
          student: const StudentSummary(id: 's1', name: ''),
          showBilling: false,
          onTap: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('agenda avisa qual compromisso mudou de situação', (
        tester,
        ) async {
      final appointment = Appointment(
        id: 'a1',
        day: (DateTime.now().weekday - 1).clamp(0, 6),
        time: '08:00',
        student: 'Ana',
        type: AppointmentType.followUp,
      );

      Appointment? changed;
      AppointmentStatus? newStatus;

      await pump(
        tester,
        AgendaTab(
          trainer: const TrainerProfile(name: 'Carla', email: 'c@c.com'),
          appointments: [appointment],
          newStudents: const [],
          onStatusChange: (a, s) {
            changed = a;
            newStatus = s;
          },
          onDismissNewStudent: (_) {},
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<AppointmentStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar falta'));
      await tester.pumpAndSettle();

      expect(changed?.id, 'a1');
      expect(newStatus, AppointmentStatus.missed);
    });

    testWidgets('agenda mostra o aviso de novos alunos e avisa o "Ciente"', (
        tester,
        ) async {
      String? dismissed;

      await pump(
        tester,
        AgendaTab(
          trainer: const TrainerProfile(name: 'Carla', email: 'c@c.com'),
          appointments: const [],
          newStudents: const ['Ana'],
          onStatusChange: (_, _) {},
          onDismissNewStudent: (n) => dismissed = n,
        ),
      );

      expect(find.text('Novos alunos'), findsOneWidget);

      await tester.tap(find.text('Ciente'));
      await tester.pumpAndSettle();

      expect(dismissed, 'Ana');
    });
  });
}