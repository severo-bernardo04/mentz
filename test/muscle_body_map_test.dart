import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/widgets/muscle_body_map.dart';
import 'package:mentz/features/workout_session/widgets/muscle_score_list.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/muscle_analysis_service.dart';
import 'package:mentz/services/settings_service.dart';
import 'package:muscle_mapper/muscle_mapper.dart';

void main() {
  MuscleContribution primary(String muscle) => MuscleContribution(
        exerciseName: 'Exercício',
        muscle: muscle,
        group: MuscleAnalysisService.groupOf(muscle),
        role: MuscleRole.primary,
      );

  // Peito com 6 pontos, Tríceps com 3
  final scores = [
    MuscleScore('Peito', [primary('Peitoral maior'), primary('Peitoral maior')]),
    MuscleScore('Tríceps', [primary('Tríceps')]),
  ];

  group('Grupamentos no boneco', () {
    test('todo grupamento conhecido tem região no boneco', () {
      for (final group in MuscleAnalysisService.knownGroups) {
        expect(
          MuscleMapperGroups.musclesOf(group),
          isNotEmpty,
          reason: '$group não tem região no boneco',
        );
      }
    });

    test('lombar fica em Costas e trapézio separado', () {
      expect(MuscleMapperGroups.groupOf(Muscle.lowerBack), 'Costas');
      expect(MuscleMapperGroups.groupOf(Muscle.lats), 'Costas');
      expect(MuscleMapperGroups.groupOf(Muscle.upperTrapezius), 'Trapézio');
    });

    test('regiões sem grupamento no app não respondem ao toque', () {
      expect(MuscleMapperGroups.groupOf(Muscle.neck), isNull);
      expect(MuscleMapperGroups.groupOf(Muscle.tibialis), isNull);
    });

    test('o mais pontuado fica com cor cheia e os outros proporcionais', () {
      final intensities = MuscleMapperGroups.intensitiesOf(scores);

      expect(intensities[Muscle.upperPectoralis], 1.0);
      // 0,25 + 0,75 × (3 / 6)
      expect(intensities[Muscle.longHeadTriceps], closeTo(0.625, 0.001));
      expect(intensities.containsKey(Muscle.lats), isFalse);
    });

    test('nomes específicos acendem só a parte certa do músculo', () {
      expect(
        MuscleMapperGroups.musclesOfName('Deltoide posterior'),
        {Muscle.posteriorDeltoid},
      );
      expect(MuscleMapperGroups.musclesOfName('Grande dorsal'), {Muscle.lats});
      // Sem nome específico, acende o grupamento inteiro
      expect(
        MuscleMapperGroups.musclesOfName('Tríceps'),
        MuscleGroup.triceps.subMuscles,
      );
    });

    test('no exercício, cada região fica com o papel mais forte', () {
      final bench = Exercise(
        id: 'supino',
        name: 'Supino reto',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: ['Tríceps', 'Deltoide anterior'],
        // O peitoral aparece de novo como secundário: vale o principal
        secondaryMuscles: ['Peitoral superior', 'Core'],
      );

      final roles = MuscleMapperGroups.rolesOf(bench);

      expect(roles[Muscle.upperPectoralis], MuscleRole.primary);
      expect(roles[Muscle.longHeadTriceps], MuscleRole.highActivation);
      expect(roles[Muscle.anteriorDeltoid], MuscleRole.highActivation);
      expect(roles.containsKey(Muscle.posteriorDeltoid), isFalse);
      expect(roles[Muscle.upperAbdominals], MuscleRole.secondary);
    });

    test('grupamento fora da lista conhecida não pinta nada', () {
      final intensities = MuscleMapperGroups.intensitiesOf([
        MuscleScore('Pescoço', [primary('Pescoço')]),
      ]);

      expect(intensities, isEmpty);
    });
  });

  group('Tela', () {
    tearDown(() => SettingsService().resetForTest());

    Future<void> pumpOverview(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MuscleScoreOverview(scores: scores),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('mostra o boneco de frente e de costas acima da lista', (
      tester,
    ) async {
      await pumpOverview(tester);

      expect(find.byKey(const Key('muscle_body_map_front')), findsOneWidget);
      expect(find.byKey(const Key('muscle_body_map_back')), findsOneWidget);
      expect(find.byType(MuscleScoreList), findsOneWidget);

      final front = tester.widget<MuscleMapper>(
        find.byKey(const Key('muscle_body_map_front')),
      );
      expect(front.gender, AnatomyGender.male);
      expect(front.activeMuscles, contains(Muscle.upperPectoralis));
    });

    testWidgets('usa o boneco feminino quando o perfil é feminino', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({'sex': 'Feminino'});
      SettingsService().startForTest(firestore, uid: 'u1');
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      await pumpOverview(tester);

      final back = tester.widget<MuscleMapper>(
        find.byKey(const Key('muscle_body_map_back')),
      );
      expect(back.gender, AnatomyGender.female);
    });
  });
}
