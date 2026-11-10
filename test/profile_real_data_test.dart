import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/profile/student/tabs/personal_tab.dart';
import 'package:mentz/features/profile/student/tabs/physical_tab.dart';
import 'package:mentz/features/profile/student/tabs/progress_tab.dart';
import 'package:mentz/features/profile/student/tabs/workout_tab.dart';
import 'package:mentz/features/profile/trainer/tabs/professional_tab.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';

void main() {
  const student = StudentProfile(name: 'Stefan', email: 'a@a.com');
  const trainer = TrainerProfile(name: 'Carla', email: 'c@c.com');

  Future<void> pump(WidgetTester tester, Widget tab) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: tab)));
    await tester.pumpAndSettle();
  }

  setUp(() => TrainingHistoryService().clearForTest());

  testWidgets('dados pessoais mostram só o que está cadastrado', (tester) async {
    await pump(tester, const PersonalTab(student: student));

    expect(find.text('Stefan'), findsOneWidget);
    expect(find.text('a@a.com'), findsOneWidget);
    expect(find.text(notInformed), findsWidgets);
    expect(find.text('Plano Trimestral'), findsNothing);
    expect(find.textContaining('1999'), findsNothing);
  });

  testWidgets('o telefone cadastrado aparece no perfil', (tester) async {
    await pump(
      tester,
      const PersonalTab(
        student: StudentProfile(
          name: 'Stefan',
          email: 'a@a.com',
          phone: '(55) 99999-0000',
        ),
      ),
    );

    expect(find.text('(55) 99999-0000'), findsOneWidget);
  });

  testWidgets('aba física funciona sem dados corporais', (tester) async {
    await pump(tester, const PhysicalTab(student: student, isOwnerView: true));

    expect(tester.takeException(), isNull);
    expect(find.text('Nenhum peso registrado.'), findsOneWidget);
    expect(find.text('Nenhuma avaliação registrada.'), findsOneWidget);
  });

  testWidgets('aba de treino funciona sem ficha', (tester) async {
    await pump(tester, const WorkoutTab(student: student));

    expect(tester.takeException(), isNull);
    expect(find.text('Nenhuma ficha de treino.'), findsOneWidget);
    expect(find.text('Carla Menezes'), findsNothing);
  });

  testWidgets('progresso usa o histórico real', (tester) async {
    TrainingHistoryService().setSessionsForTest([
      CompletedWorkout(DateTime.now(), 'A', 60, id: 's1'),
      CompletedWorkout(DateTime.now(), 'B', 50, id: 's2'),
    ]);

    await pump(tester, const ProgressTab(student: student));

    expect(tester.takeException(), isNull);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Nenhum recorde registrado.'), findsOneWidget);
  });

  testWidgets('perfil do treinador funciona sem dados profissionais', (
    tester,
  ) async {
    await pump(tester, const ProfessionalTab(trainer: trainer));

    expect(tester.takeException(), isNull);
    expect(find.text('Carla'), findsOneWidget);
    expect(find.textContaining('CREF'), findsNothing);
    expect(find.text('Nenhuma especialidade cadastrada.'), findsOneWidget);
  });
}
