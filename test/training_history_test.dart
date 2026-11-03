import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/home/home_page.dart';
import 'package:mentz/features/training_history/controllers/training_history_controller.dart';
import 'package:mentz/features/training_history/training_history_page.dart';
import 'package:mentz/features/training_history/widgets/workout_session_card.dart';
import 'package:mentz/features/training_history/workout_session_detail_page.dart';
import 'package:mentz/features/training_history/workout_spreadsheet_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';

void main() {
  late TrainingHistoryService service;

  setUp(() {
    service = TrainingHistoryService();
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

  group('TrainingHistoryService & Controller Unit Tests', () {
    test('carregamento das sessões e ordenação cronológica decrescente', () async {
      final now = DateTime.now();
      final s1 = CompletedWorkout(
        now.subtract(const Duration(days: 5)),
        'A',
        50,
        id: 's1',
        chartName: 'Planilha Alpha',
        workoutName: 'Treino A',
      );
      final s2 = CompletedWorkout(
        now.subtract(const Duration(days: 1)),
        'B',
        60,
        id: 's2',
        chartName: 'Planilha Alpha',
        workoutName: 'Treino B',
      );
      final s3 = CompletedWorkout(
        now.subtract(const Duration(days: 3)),
        'C',
        55,
        id: 's3',
        chartName: 'Planilha Alpha',
        workoutName: 'Treino C',
      );

      service.setSessionsForTest([s1, s2, s3]);

      final controller = TrainingHistoryController(service: service);
      await controller.load();

      expect(controller.loading, false);
      expect(controller.errorMessage, isNull);
      expect(controller.sessions.length, 3);
      // Deve estar ordenado da mais recente para a mais antiga: s2 (1 dia), s3 (3 dias), s1 (5 dias)
      expect(controller.sessions[0].id, 's2');
      expect(controller.sessions[1].id, 's3');
      expect(controller.sessions[2].id, 's1');
    });

    test('filtragem por plano e consulta de execuções anteriores', () async {
      final now = DateTime.now();
      service.setSessionsForTest([
        CompletedWorkout(now.subtract(const Duration(days: 1)), 'A', 60),
        CompletedWorkout(now.subtract(const Duration(days: 2)), 'B', 50),
        CompletedWorkout(now.subtract(const Duration(days: 4)), 'A', 65),
      ]);

      final controller = TrainingHistoryController(service: service);
      await controller.load();

      expect(controller.filteredSessions.length, 3);

      controller.setFilter('A');
      expect(controller.filteredSessions.length, 2);
      expect(controller.filteredSessions.every((s) => s.plan == 'A'), isTrue);

      controller.setFilter('B');
      expect(controller.filteredSessions.length, 1);
      expect(controller.filteredSessions.first.plan, 'B');

      // Consulta no service para histórico específico
      final aSessions = service.getSessionsForWorkout('A');
      expect(aSessions.length, 2);
    });
  });

  group('TrainingHistoryPage Widget Tests', () {
    testWidgets('exibe estado vazio quando não há sessões', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(TrainingHistoryPage(service: service)));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum treino realizado ainda'), findsOneWidget);
    });

    testWidgets('exibe sessões de treino com dados corretos de data, duração e treino',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date = DateTime(2026, 10, 22);
      service.setSessionsForTest([
        CompletedWorkout(
          date,
          'A',
          62,
          chartName: 'Planilha Hipertrofia',
          workoutName: 'FULL BODY 1',
          executedExercises: const [
            ExecutedExercise(
              name: 'Supino Reto',
              muscle: 'Peito',
              sets: [
                ExecutedSet(setNumber: 1, load: '60 kg', reps: '10'),
              ],
            ),
          ],
        ),
      ]);

      await tester.pumpWidget(createTestApp(TrainingHistoryPage(service: service)));
      await tester.pumpAndSettle();

      expect(find.text('FULL BODY 1'), findsOneWidget);
      expect(find.text('Planilha Hipertrofia'), findsOneWidget);
      expect(find.text('62 min'), findsOneWidget);
      expect(find.text(formatDate(date)), findsOneWidget);
      expect(find.byType(WorkoutSessionCard), findsOneWidget);
    });

    testWidgets('abertura e retorno dos detalhes da sessão', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date = DateTime(2026, 10, 20);
      final session = CompletedWorkout(
        date,
        'B',
        55,
        chartName: 'Planilha ABC',
        workoutName: 'Treino B — Costas',
        executedExercises: const [
          ExecutedExercise(
            name: 'Puxada Frontal',
            muscle: 'Costas',
            sets: [
              ExecutedSet(
                setNumber: 1,
                type: SetType.warmup,
                load: '40 kg',
                reps: '12',
              ),
              ExecutedSet(
                setNumber: 2,
                type: SetType.working,
                load: '60 kg',
                reps: '10',
              ),
            ],
          ),
          ExecutedExercise(
            name: 'Remada Curvada',
            completed: false,
            notes: 'Desconforto na pegada',
            sets: [
              ExecutedSet(
                setNumber: 1,
                load: '50 kg',
                reps: '5',
                completed: false,
              ),
            ],
          ),
        ],
      );

      service.setSessionsForTest([session]);

      await tester.pumpWidget(createTestApp(TrainingHistoryPage(service: service)));
      await tester.pumpAndSettle();

      // Clica no card da sessão
      await tester.tap(find.byType(WorkoutSessionCard));
      await tester.pumpAndSettle();

      // Verifica abertura de WorkoutSessionDetailPage com dados reais
      expect(find.byType(WorkoutSessionDetailPage), findsOneWidget);
      expect(find.text('Detalhes do Treino'), findsOneWidget);
      expect(find.text('Puxada Frontal'), findsOneWidget);
      expect(find.text('Remada Curvada'), findsOneWidget);
      expect(find.text('Não concluído'), findsOneWidget);
      expect(find.text('Desconforto na pegada'), findsOneWidget);
      expect(find.text('Aquecimento'), findsOneWidget);

      // Retorna para a tela de histórico
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainingHistoryPage), findsOneWidget);
    });
  });

  group('WorkoutSpreadsheetPage & Navigation Tests', () {
    testWidgets('exibe planilha estilo Excel com abas dos dias do ciclo', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final date1 = DateTime(2026, 10, 15);
      final date2 = DateTime(2026, 10, 22);

      service.setSessionsForTest([
        CompletedWorkout(
          date1,
          'A',
          60,
          chartName: 'Planilha 1',
          executedExercises: const [
            ExecutedExercise(
              name: 'Supino Reto',
              sets: [ExecutedSet(setNumber: 1, load: '55 kg', reps: '10')],
            ),
          ],
        ),
        CompletedWorkout(
          date2,
          'A',
          62,
          chartName: 'Planilha 1',
          executedExercises: const [
            ExecutedExercise(
              name: 'Supino Reto',
              sets: [ExecutedSet(setNumber: 1, load: '60 kg', reps: '10')],
            ),
          ],
        ),
      ]);

      await tester.pumpWidget(
        createTestApp(WorkoutSpreadsheetPage(service: service, initialPlan: 'A')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planilha de Execuções'), findsOneWidget);
      expect(find.text('Treino A'), findsWidgets);
      expect(find.text('Exercício'), findsOneWidget);
      expect(find.text('Supino Reto'), findsOneWidget);
    });

    testWidgets('navegação para o Histórico a partir do grid de atalhos da HomePage',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const HomePage(userName: 'Bernardo')));
      await tester.pumpAndSettle();

      // Encontra o atalho de Histórico
      final historyCard = find.byKey(const Key('home_history_shortcut_card'));
      expect(historyCard, findsOneWidget);

      await tester.tap(historyCard);
      await tester.pumpAndSettle();

      // Confirma que a página de Histórico foi aberta
      expect(find.byType(TrainingHistoryPage), findsOneWidget);

      // Retorna para a HomePage sem interferir no estado
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
