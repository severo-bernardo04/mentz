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
    testWidgets('exibe catálogo com nomes PT/EN, grupos musculares e abre demonstração',
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

      // Verifica exibição dos nomes e do card
      expect(find.text('Supino reto'), findsOneWidget);
      expect(find.text('Barbell Flat Bench Press'), findsOneWidget);
      expect(find.text('Principal: Peitoral maior'), findsOneWidget);
      expect(find.text('Alta: Tríceps'), findsOneWidget);
      expect(find.byType(ExerciseCatalogCard), findsOneWidget);

      // Clica para abrir demonstração anatômica
      await tester.tap(find.text('Ver Demonstração Anatômica'));
      await tester.pumpAndSettle();

      // Confirma que abriu a tela de detalhes
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
        sets: 4,
        reps: '10',
        load: '22 kg',
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
}
