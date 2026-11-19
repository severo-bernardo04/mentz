import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Serviço responsável por capturar o card do treino como imagem PNG
/// e enviá-lo para o Instagram (Stories/Feed) e outros apps via compartilhamento nativo.
class WorkoutShareService {
  /// Função customizável para captura de PNG (útil em testes unitários).
  @visibleForTesting
  static Future<Uint8List?> Function(GlobalKey key, {double pixelRatio})? pngCapturer;

  /// Função customizável para salvar arquivo temporário (útil em testes unitários).
  @visibleForTesting
  static Future<String> Function(Uint8List bytes, String filename)? tempFileSaver;

  /// Função customizável para disparar o share (útil em testes unitários).
  @visibleForTesting
  static Future<bool> Function(String filePath, String text)? shareHandler;

  /// Função customizável para seleção de imagem da câmera/galeria (útil em testes unitários).
  @visibleForTesting
  static Future<Uint8List?> Function(ImageSource source)? imagePickerHandler;

  /// Abre a câmera ou galeria para obter a foto do treino tirada pelo usuário.
  /// Utiliza dimensões e compressão otimizadas (720x1280 @ 60%) para evitar que
  /// o sistema operacional reinicie o app por pressão de memória (OOM).
  static Future<Uint8List?> pickWorkoutPhoto(ImageSource source) async {
    if (imagePickerHandler != null) {
      return await imagePickerHandler!(source);
    }

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 1280,
        imageQuality: 60,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('WorkoutShareService.pickWorkoutPhoto error: $e');
      return null;
    }
  }

  /// Recupera fotos tiradas pela câmera caso o Android tenha reiniciado
  /// a Activity durante a captura de foto.
  static Future<Uint8List?> retrieveLostPhoto() async {
    try {
      if (kIsWeb) return null;
      if (Platform.isAndroid) {
        final picker = ImagePicker();
        final LostDataResponse response = await picker.retrieveLostData();
        if (response.isEmpty || response.file == null) return null;
        return await response.file!.readAsBytes();
      }
    } catch (e) {
      debugPrint('WorkoutShareService.retrieveLostPhoto error: $e');
    }
    return null;
  }

  /// Captura a imagem PNG de um widget envolvido em [RepaintBoundary] através de sua [GlobalKey].
  static Future<Uint8List?> capturePng(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    if (pngCapturer != null) {
      return await pngCapturer!(repaintKey, pixelRatio: pixelRatio);
    }

    try {
      final boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('WorkoutShareService.capturePng error: $e');
      return null;
    }
  }

  /// Salva os bytes da imagem PNG em um diretório temporário local.
  static Future<String?> saveTempPng(
    Uint8List bytes, {
    String prefix = 'mentz_workout',
  }) async {
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';

    if (tempFileSaver != null) {
      return await tempFileSaver!(bytes, filename);
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('WorkoutShareService.saveTempPng error: $e');
      return null;
    }
  }

  /// Dispara o compartilhamento da imagem para o Instagram Stories / WhatsApp / etc.
  /// Para Stories, deve-se enviar sem texto adicional (text: null), para que o Instagram
  /// abra a imagem em tela cheia (full-bleed) em vez de encolhê-la para um sticker.
  static Future<bool> shareWorkoutImage({
    required String filePath,
    String? text,
  }) async {
    if (shareHandler != null) {
      return await shareHandler!(filePath, text ?? '');
    }

    try {
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png')],
        text: text,
        subject: 'Meu Treino no Mentz',
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('WorkoutShareService.shareWorkoutImage error: $e');
      return false;
    }
  }
}
