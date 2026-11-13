import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/exercises/controllers/exercise_catalog_controller.dart';
import 'package:mentz/features/exercises/exercise_detail_page.dart';
import 'package:mentz/features/exercises/exercises_catalog_page.dart';
import 'package:mentz/features/exercises/widgets/exercise_catalog_card.dart';
import 'package:mentz/features/exercises/widgets/muscle_anatomy_painter.dart';
import 'package:mentz/features/exercises/widgets/muscle_anatomy_view.dart';
import 'package:mentz/features/exercises/widgets/muscle_legend_bar.dart';
import 'package:mentz/features/home/home_page.dart';
import 'package:mentz/features/training/widgets/exercise_sheet.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/exercise_catalog_service.dart';

void main() {
  late ExerciseCatalogService service;

  setUp(() {
    service = ExerciseCatalogService();
    service.clearForTest();
  });

  Widget createTestApp(Widget home) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: home,
    );
  }

  group('ExerciseCatalogService & Controller Unit Tests', () {
    test('carregamento dos exercícios reais e grupos musculares', () async {
      service.setExercisesForTest([
        Exercise(
          name: 'Supino reto',
          nameEn: 'Barbell Flat Bench Press',
          muscle: 'Peito',
          primaryMuscle: 'Peitoral maior',
          highActivationMuscles: const ['Tríceps', 'Deltoide anterior'],
          secondaryMuscles: const ['Serrátil anterior'],
        ),
        Exercise(
          name: 'Agachamento livre',
          nameEn: 'Barbell Back Squat',
          muscle: 'Quadríceps',
          primaryMuscle: 'Quadríceps',
          highActivationMuscles: const ['Glúteos'],
          secondaryMuscles: const ['Isquiotibiais'],
        ),
      ]);

      final controller = ExerciseCatalogController(service: service);
      await controller.load();

      expect(controller.loading, false);
      expect(controller.errorMessage, isNull);
      expect(controller.exercises.length, 2);
      expect(controller.availableMuscleGroups, containsAll(['Todos', 'Peito', 'Quadríceps']));
    });

    test('busca em tempo real por nome em português e inglês e filtro por músculo', () async {
      service.setExercisesForTest([
        Exercise(
          name: 'Supino reto',
          nameEn: 'Barbell Flat Bench Press',
          muscle: 'Peito',
          primaryMuscle: 'Peitoral maior',
        ),
        Exercise(
          name: 'Puxada frontal',
          nameEn: 'Lat Pulldown',
          muscle: 'Costas',
          primaryMuscle: 'Grande dorsal',
        ),
        Exercise(
          name: 'Rosca direta',
          nameEn: 'Barbell Biceps Curl',
          muscle: 'Bíceps',
          primaryMuscle: 'Bíceps',
        ),
      ]);

      final controller = ExerciseCatalogController(service: service);
      await controller.load();

      // Busca por nome PT
      controller.setQuery('supino');
      expect(controller.filteredExercises.length, 1);
      expect(controller.filteredExercises.first.name, 'Supino reto');

      // Busca por nome EN
      controller.setQuery('Pulldown');
      expect(controller.filteredExercises.length, 1);
      expect(controller.filteredExercises.first.name, 'Puxada frontal');

      // Limpa busca e filtra por grupo muscular
      controller.setQuery('');
      controller.setMuscleGroup('Bíceps');
      expect(controller.filteredExercises.length, 1);
      expect(controller.filteredExercises.first.name, 'Rosca direta');
    });
  });

  group('MuscleActivationResolver & Legend Tests', () {
    test('correspondência correta entre músculos cadastrados e regiões anatômicas com as 3 cores', () {
      final benchPress = Exercise(
        name: 'Supino reto',
        nameEn: 'Barbell Flat Bench Press',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: const ['Tríceps', 'Deltoide anterior'],
        secondaryMuscles: const ['Serrátil anterior', 'Core'],
      );

      // Peito deve ser principal (Vermelho)
      final chestRole = MuscleActivationResolver.getRole(benchPress, 'chest');
      expect(chestRole, MuscleRole.primary);
      expect(chestRole.color, const Color(0xFFD32F2F));

      // Tríceps deve ser alta ativação (Laranja)
      final tricepsRole = MuscleActivationResolver.getRole(benchPress, 'triceps');
      expect(tricepsRole, MuscleRole.highActivation);
      expect(tricepsRole.color, const Color(0xFFF57C00));

      // Ombros (deltoide anterior) deve ser alta ativação (Laranja)
      final shoulderRole = MuscleActivationResolver.getRole(benchPress, 'shoulders');
      expect(shoulderRole, MuscleRole.highActivation);
      expect(shoulderRole.color, const Color(0xFFF57C00));

      // Core / Abdômen deve ser secundário (Amarelo)
      final absRole = MuscleActivationResolver.getRole(benchPress, 'abs');
      expect(absRole, MuscleRole.secondary);
      expect(absRole.color, const Color(0xFFFBC02D));

      // Quadríceps não deve estar ativado (Inativo)
      final quadsRole = MuscleActivationResolver.getRole(benchPress, 'quads');
      expect(quadsRole, MuscleRole.none);
    });
  });

  group('ExercisesCatalogPage & Detail Widget Tests', () {
    testWidgets('exibe catálogo simplificado (nome e músculo principal) e abre demonstração',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ex = Exercise(
        name: 'Supino reto',
        nameEn: 'Barbell Flat Bench Press',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: const ['Tríceps', 'Deltoide anterior'],
        secondaryMuscles: const ['Core'],
        equipment: 'Barra e banco',
        instructions: 'Desça a barra controladamente até o peito e empurre.',
      );
      service.setExercisesForTest([ex]);

      await tester.pumpWidget(createTestApp(ExercisesCatalogPage(service: service)));
      await tester.pumpAndSettle();

      // Verifica exibição simplificada: apenas nome e músculo principal na listagem
      expect(find.text('Supino reto'), findsOneWidget);
      expect(find.text('Peitoral maior'), findsOneWidget);
      expect(find.text('Barbell Flat Bench Press'), findsNothing);
      expect(find.text('Alta: Tríceps'), findsNothing);
      expect(find.text('Secundário: Core'), findsNothing);
      expect(find.text('Ver Demonstração Anatômica'), findsNothing);
      expect(find.byType(MuscleAnatomyView), findsNothing);
      expect(find.byType(ExerciseCatalogCard), findsOneWidget);

      // Toca no card para abrir demonstração anatômica
      await tester.tap(find.byType(ExerciseCatalogCard));
      await tester.pumpAndSettle();

      // Confirma que abriu a tela de detalhes com o boneco anatômico
      expect(find.byType(ExerciseDetailPage), findsOneWidget);
      expect(find.text('Demonstração Anatômica'), findsOneWidget);
      expect(find.byType(MuscleAnatomyView), findsOneWidget);
      expect(find.byType(MuscleLegendBar), findsOneWidget);

      // Verifica presença da legenda obrigatória com as 3 cores
      expect(find.text('Músculo Principal'), findsWidgets);
      expect(find.text('Alta Ativação'), findsWidgets);
      expect(find.text('Músculo Secundário'), findsWidgets);

      // Alterna para Vista Posterior
      await tester.tap(find.text('Vista Posterior (Costas)'));
      await tester.pumpAndSettle();

      // Retorna
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisesCatalogPage), findsOneWidget);
    });

    testWidgets('exibe estado vazio quando busca não retorna exercícios', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      service.setExercisesForTest([]);

      await tester.pumpWidget(createTestApp(ExercisesCatalogPage(service: service)));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum exercício encontrado para os critérios pesquisados.'),
        findsOneWidget,
      );
    });

    testWidgets('seleção de exercício integra com fluxo do ExerciseSheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ex = Exercise(
        name: 'Desenvolvimento com halteres',
        nameEn: 'Dumbbell Shoulder Press',
        muscle: 'Ombros',
        primaryMuscle: 'Deltoides',
        highActivationMuscles: const ['Tríceps'],
      );
      service.setExercisesForTest([ex]);

      // Abre o ExerciseSheet
      await tester.pumpWidget(createTestApp(const Scaffold(body: ExerciseSheet())));
      await tester.pumpAndSettle();

      final catalogButton =
          find.byKey(const Key('exercise_sheet_choose_from_catalog_button'));
      expect(catalogButton, findsOneWidget);

      // Clica para abrir o catálogo em modo de seleção
      await tester.tap(catalogButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExercisesCatalogPage), findsOneWidget);
      expect(find.text('Desenvolvimento com halteres'), findsOneWidget);

      // Clica em Selecionar
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();

      // Confirma que voltou ao ExerciseSheet e preencheu os campos automaticamente
      expect(find.byType(ExerciseSheet), findsOneWidget);
      expect(find.text('Desenvolvimento com halteres'), findsOneWidget);
    });

    testWidgets('navegação a partir da HomePage para o Catálogo de Exercícios', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const HomePage(userName: 'Bernardo')));
      await tester.pumpAndSettle();

      // Encontra o banner na home
      final banner = find.byKey(const Key('home_exercises_banner_card'));
      expect(banner, findsOneWidget);

      await tester.tap(banner);
      await tester.pumpAndSettle();

      expect(find.byType(ExercisesCatalogPage), findsOneWidget);

      // Retorna sem afetar o estado da Home
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('Séries planejadas', () {
    test('tryParse aceita faixas válidas', () {
      final range = PlannedSet.tryParse(' 8 - 10 ');

      expect(range?.minReps, 8);
      expect(range?.maxReps, 10);
      expect(range?.type, SetType.working);
    });

    test('tryParse recusa mínimo maior que o máximo e formatos inválidos', () {
      for (final text in ['10-8', '0-5', '12', 'abc', '']) {
        expect(PlannedSet.tryParse(text), isNull, reason: text);
      }
    });

    test('apenas Reconhecimento aceita valor único', () {
      final feeder = PlannedSet.tryParse('2', type: SetType.feeder);

      expect(feeder?.minReps, 2);
      expect(feeder?.maxReps, 2);
      expect(feeder?.repsLabel, '2');
      expect(feeder?.repsInput, '2');
      expect(PlannedSet.tryParse('2', type: SetType.working), isNull);
      expect(PlannedSet.tryParse('2', type: SetType.warmup), isNull);
      expect(PlannedSet.tryParse('0', type: SetType.feeder), isNull);
      expect(PlannedSet.tryParse('1-3', type: SetType.feeder)?.maxReps, 3);
    });

    test('o modelo não aceita faixa invertida nem drop set em Reconhecimento', () {
      expect(() => PlannedSet(minReps: 10, maxReps: 8), throwsAssertionError);
      expect(
        () => PlannedSet(
          type: SetType.feeder,
          minReps: 8,
          maxReps: 10,
          isDropSet: true,
        ),
        throwsAssertionError,
      );
    });

    test('setsLabel agrupa faixas seguidas iguais', () {
      final uniform = WorkoutExercise(
        exercise: Exercise(name: 'Supino reto'),
        plannedSets: PlannedSet.repeat(4, minReps: 8, maxReps: 10),
      );
      final mixed = WorkoutExercise(
        exercise: Exercise(name: 'Agachamento'),
        plannedSets: const [
          PlannedSet(type: SetType.warmup, minReps: 15, maxReps: 20),
          PlannedSet(minReps: 6, maxReps: 8),
          PlannedSet(minReps: 6, maxReps: 8),
        ],
      );

      expect(uniform.setsLabel, '4 × 8–10');
      expect(mixed.setsLabel, '1 × 15–20 + 2 × 6–8');
    });

    test('toMap e fromMap preservam as séries planejadas', () {
      final remada = Exercise(id: 'remada-curvada', name: 'Remada curvada');
      final original = WorkoutExercise(
        exercise: remada,
        plannedSets: const [
          PlannedSet(
            type: SetType.warmup,
            minReps: 12,
            maxReps: 15,
            isDropSet: true,
          ),
          PlannedSet(minReps: 8, maxReps: 10),
        ],
      );

      final restored = WorkoutExercise.fromMap(
        original.toMap(),
        findExercise: (id) => id == remada.id ? remada : null,
      );

      expect(restored.name, 'Remada curvada');
      expect(restored.plannedSets.length, 2);
      expect(restored.plannedSets.first.type, SetType.warmup);
      expect(restored.plannedSets.first.isDropSet, isTrue);
      expect(restored.plannedSets.last.repsLabel, '8–10');
    });

    test('o catálogo não guarda faixa de repetições nem descanso', () {
      final map = Exercise(name: 'Supino reto').toMap();

      expect(map.containsKey('plannedSets'), isFalse);
      expect(map.containsKey('restSeconds'), isFalse);
    });

    test('o mesmo exercício pode ter faixas diferentes em cada treino', () {
      final bench = Exercise(name: 'Supino reto');
      final strength = WorkoutExercise(
        exercise: bench,
        plannedSets: PlannedSet.repeat(5, minReps: 4, maxReps: 6),
      );
      final volume = WorkoutExercise(
        exercise: bench,
        plannedSets: PlannedSet.repeat(3, minReps: 10, maxReps: 12),
      );

      expect(strength.setsLabel, '5 × 4–6');
      expect(volume.setsLabel, '3 × 10–12');
      expect(identical(strength.exercise, volume.exercise), isTrue);
    });
  });
}
