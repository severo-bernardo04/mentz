import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mentz/widgets/app_logo.dart';
import 'package:mentz/features/training_history/widgets/workout_share_card.dart';
import 'package:mentz/features/training_history/widgets/workout_share_dialog.dart';
import 'package:mentz/features/training_history/workout_session_detail_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/workout_share_service.dart';

/// Foto de fundo do cartão. A logo do Mentz também é um Image, mas vem de
/// asset (AssetImage), então fica de fora.
final _backgroundPhoto = find.byWidgetPredicate(
  (w) => w is Image && w.image is! AssetImage,
);

void main() {
  // 1x1 PNG transparente válido para testes
  final testImageBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  final sampleSession = CompletedWorkout(
    DateTime(2026, 11, 18, 10, 30),
    'Treino A - Peito e Tríceps',
    48,
    chartName: 'Hipertrofia ABC',
    workoutName: 'Peito & Tríceps',
    executedExercises: const [
      ExecutedExercise(
        name: 'Supino Reto com Barra',
        completed: true,
        sets: [
          ExecutedSet(setNumber: 1, reps: 12, loadKg: 60.0),
          ExecutedSet(setNumber: 2, reps: 10, loadKg: 70.0),
          ExecutedSet(setNumber: 3, reps: 8, loadKg: 80.0),
        ],
      ),
      ExecutedExercise(
        name: 'Supino Inclinado com Halteres',
        completed: true,
        sets: [
          ExecutedSet(setNumber: 1, reps: 10, loadKg: 24.0),
          ExecutedSet(setNumber: 2, reps: 10, loadKg: 24.0),
        ],
      ),
      ExecutedExercise(
        name: 'Tríceps Corda',
        completed: true,
        sets: [
          ExecutedSet(setNumber: 1, reps: 12, loadKg: 35.0),
          ExecutedSet(setNumber: 2, reps: 12, loadKg: 35.0),
        ],
      ),
    ],
  );

  tearDown(() {
    WorkoutShareService.pngCapturer = null;
    WorkoutShareService.tempFileSaver = null;
    WorkoutShareService.shareHandler = null;
    WorkoutShareService.imagePickerHandler = null;
  });

  group('WorkoutShareCard Tests', () {
    testWidgets('exibe informações principais do treino e convite para foto quando não há imagem',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutShareCard(session: sampleSession),
          ),
        ),
      );

      // Marca e branding
      expect(find.text('MENTZ'), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('#MentzApp'), findsOneWidget);

      // Ícone de upload para foto
      expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);

      // Dados do treino
      expect(find.text('Peito & Tríceps'), findsOneWidget);
      expect(find.text('Hipertrofia ABC'), findsOneWidget);

      // Estatísticas
      expect(find.text('48 min'), findsOneWidget);
      expect(find.text('DURAÇÃO'), findsOneWidget);
      expect(find.text('3/3 feitos'), findsOneWidget);
      expect(find.text('EXERCÍCIOS'), findsOneWidget);

      // Exercícios executados
      expect(find.text('Supino Reto com Barra'), findsOneWidget);
      expect(find.text('Supino Inclinado com Halteres'), findsOneWidget);
      expect(find.text('Tríceps Corda'), findsOneWidget);

      // Métricas reais persistidas calculadas do treino
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('3.4 ton'), findsOneWidget);
      expect(find.text('7 sets'), findsOneWidget);
      expect(find.text('SÉRIES'), findsOneWidget);
      expect(find.text('Carga máx: 80 kg'), findsOneWidget);

      // Resumo real de séries e pico de carga por exercício
      expect(find.text('3 séries • 80 kg'), findsOneWidget);
      expect(find.text('2 séries • 24 kg'), findsOneWidget);
      expect(find.text('2 séries • 35 kg'), findsOneWidget);
    });

    testWidgets('exibe foto do usuário no fundo com as informações de treino sobrepostas',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutShareCard(
              session: sampleSession,
              backgroundImageBytes: testImageBytes,
            ),
          ),
        ),
      );

      // Fundo deve conter a imagem
      expect(_backgroundPhoto, findsOneWidget);

      // Informações sobrepostas na imagem
      expect(find.text('MENTZ'), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('Peito & Tríceps'), findsOneWidget);
      expect(find.text('48 min'), findsOneWidget);
      expect(find.text('3/3 feitos'), findsOneWidget);
      expect(find.text('#MentzApp'), findsOneWidget);

      // Não deve mais exibir o ícone de upload de foto pois a foto já existe
      expect(find.byIcon(Icons.file_upload_outlined), findsNothing);
    });
  });

  group('WorkoutShareService Tests', () {
    test('saveTempPng, shareWorkoutImage e pickWorkoutPhoto invocam os delegates customizados',
        () async {
      var savedBytesLength = 0;
      var passedFilePath = '';
      var passedText = '';
      var pickedSource = ImageSource.gallery;

      WorkoutShareService.tempFileSaver = (bytes, filename) async {
        savedBytesLength = bytes.length;
        return '/mock/path/$filename';
      };

      WorkoutShareService.shareHandler = (filePath, text) async {
        passedFilePath = filePath;
        passedText = text;
        return true;
      };

      WorkoutShareService.imagePickerHandler = (source) async {
        pickedSource = source;
        return testImageBytes;
      };

      final savedPath = await WorkoutShareService.saveTempPng(testImageBytes);
      expect(savedPath, startsWith('/mock/path/mentz_workout_'));
      expect(savedBytesLength, testImageBytes.length);

      final shareSuccess = await WorkoutShareService.shareWorkoutImage(
        filePath: savedPath!,
        text: 'Teste de compartilhamento',
      );
      expect(shareSuccess, isTrue);
      expect(passedFilePath, savedPath);
      expect(passedText, 'Teste de compartilhamento');

      final pickedBytes = await WorkoutShareService.pickWorkoutPhoto(ImageSource.camera);
      expect(pickedBytes, testImageBytes);
      expect(pickedSource, ImageSource.camera);
    });
  });

  group('WorkoutShareDialog Tests', () {
    testWidgets('permite tirar foto com a câmera e exibe a imagem de fundo com as informações sobrepostas',
        (tester) async {
      var shareInvoked = false;
      ImageSource? sourcePassed;

      WorkoutShareService.pngCapturer = (key, {pixelRatio = 3.0}) async =>
          Uint8List.fromList([1, 2, 3]);
      WorkoutShareService.tempFileSaver = (bytes, filename) async => '/temp/$filename';
      WorkoutShareService.shareHandler = (path, text) async {
        shareInvoked = true;
        return true;
      };
      WorkoutShareService.imagePickerHandler = (source) async {
        sourcePassed = source;
        return testImageBytes;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showWorkoutShareDialog(
                  context,
                  session: sampleSession,
                ),
                child: const Text('Abrir Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Story do Treino'), findsOneWidget);
      expect(find.byType(WorkoutShareCard), findsOneWidget);
      expect(find.byKey(const Key('take_photo_camera_button')), findsOneWidget);
      expect(find.byKey(const Key('pick_photo_gallery_button')), findsOneWidget);
      expect(find.byKey(const Key('share_instagram_button')), findsOneWidget);

      // Clica em 'Tirar Foto' com a Câmera
      await tester.tap(find.byKey(const Key('take_photo_camera_button')));
      await tester.pumpAndSettle();

      expect(sourcePassed, ImageSource.camera);
      // Card agora tem a imagem de fundo
      expect(_backgroundPhoto, findsOneWidget);
      expect(find.byKey(const Key('remove_photo_button')), findsOneWidget);
      expect(find.text('Foto adicionada! Pronto para compartilhar'), findsOneWidget);

      // Compartilha nos Stories com a foto + dados sobrepostos
      await tester.tap(find.byKey(const Key('share_instagram_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      expect(shareInvoked, isTrue);
    });

    testWidgets('exibe indicador de loading apenas no botão acionado (Galeria vs Câmera)',
        (tester) async {
      Completer<Uint8List?> pickerCompleter = Completer<Uint8List?>();
      ImageSource? lastSource;

      WorkoutShareService.imagePickerHandler = (source) {
        lastSource = source;
        return pickerCompleter.future;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutShareDialog(session: sampleSession),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cameraButtonFinder = find.byKey(const Key('take_photo_camera_button'));
      final galleryButtonFinder = find.byKey(const Key('pick_photo_gallery_button'));

      // 1. Clica no botão Galeria
      await tester.tap(galleryButtonFinder);
      await tester.pump(); // Inicia setState com _loadingSource = gallery

      expect(lastSource, ImageSource.gallery);
      // Spinner deve estar no botão da Galeria e NÃO no de Câmera
      expect(
        find.descendant(of: galleryButtonFinder, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cameraButtonFinder, matching: find.byType(CircularProgressIndicator)),
        findsNothing,
      );

      // Completa o carregamento da galeria
      pickerCompleter.complete(testImageBytes);
      await tester.pumpAndSettle();

      // Nenhum botão deve ter spinner agora
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_backgroundPhoto, findsOneWidget);

      // 2. Agora clica no botão Câmera ('Nova Foto')
      pickerCompleter = Completer<Uint8List?>();
      await tester.tap(cameraButtonFinder);
      await tester.pump(); // Inicia setState com _loadingSource = camera

      expect(lastSource, ImageSource.camera);
      // Spinner deve estar no botão da Câmera e NÃO no de Galeria
      expect(
        find.descendant(of: cameraButtonFinder, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: galleryButtonFinder, matching: find.byType(CircularProgressIndicator)),
        findsNothing,
      );

      pickerCompleter.complete(testImageBytes);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('botões ficam ancorados no rodapé e o card fica visível acima deles',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutShareDialog(session: sampleSession),
        ),
      );
      await tester.pumpAndSettle();

      final cardRect = tester.getRect(find.byType(WorkoutShareCard));
      final shareBtnRect = tester.getRect(find.byKey(const Key('share_instagram_button')));
      final cameraBtnRect = tester.getRect(find.byKey(const Key('take_photo_camera_button')));

      // Card fica visível no corpo da tela
      expect(cardRect.top, lessThan(100.0));
      // Botões devem estar na parte inferior (rodapé) da tela, e não no meio
      expect(cameraBtnRect.top, greaterThan(650.0));
      expect(shareBtnRect.top, greaterThan(cameraBtnRect.bottom));
    });
  });

  group('WorkoutSessionDetailPage Integration Tests', () {
    testWidgets('possui botões de compartilhamento na AppBar e no final da tela',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutSessionDetailPage(session: sampleSession),
        ),
      );

      expect(find.byKey(const Key('share_workout_icon_button')), findsOneWidget);
      expect(find.byKey(const Key('share_workout_button')), findsOneWidget);

      // Clicar no botão da AppBar abre o diálogo de share
      await tester.tap(find.byKey(const Key('share_workout_icon_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutShareDialog), findsOneWidget);
    });
  });
}
