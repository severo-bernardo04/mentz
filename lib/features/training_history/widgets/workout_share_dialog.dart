import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/snackbars.dart';
import '../../../models/profile_models.dart';
import '../../../services/workout_share_service.dart';
import 'workout_share_card.dart';

/// Abre a tela cheia de compartilhamento com preview do Story e ações de foto
/// e envio para o Instagram Stories, adaptando-se ao tema claro e escuro.
Future<void> showWorkoutShareDialog(
  BuildContext context, {
  required CompletedWorkout session,
  Uint8List? initialPhotoBytes,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => WorkoutShareDialog(
        session: session,
        initialPhotoBytes: initialPhotoBytes,
      ),
    ),
  );
}

class WorkoutShareDialog extends StatefulWidget {
  final CompletedWorkout session;
  final Uint8List? initialPhotoBytes;

  const WorkoutShareDialog({
    super.key,
    required this.session,
    this.initialPhotoBytes,
  });

  @override
  State<WorkoutShareDialog> createState() => _WorkoutShareDialogState();
}

class _WorkoutShareDialogState extends State<WorkoutShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  Uint8List? _photoBytes;
  bool _isSharing = false;
  ImageSource? _loadingSource;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _photoBytes = widget.initialPhotoBytes;
    if (_photoBytes == null) {
      _checkLostPhoto();
    }
  }

  /// Caso o Android tenha reiniciado a Activity durante a câmera, recupera a foto tirada
  Future<void> _checkLostPhoto() async {
    final lost = await WorkoutShareService.retrieveLostPhoto();
    if (lost != null && mounted) {
      setState(() => _photoBytes = lost);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _loadingSource = source);
    try {
      final bytes = await WorkoutShareService.pickWorkoutPhoto(source);
      if (bytes != null && mounted) {
        setState(() => _photoBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        context.showSnack('Erro ao obter foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSource = null);
      }
    }
  }

  Future<void> _share() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
      _isExporting = true;
    });

    try {
      // Aguarda o frame renderizar no modo exportação (full-bleed, cantos retos e Safe Zones)
      await WidgetsBinding.instance.endOfFrame;

      // 1. Captura a imagem renderizada em alta resolução 1080x1920 (9:16)
      final Uint8List? pngBytes = await WorkoutShareService.capturePng(
        _cardKey,
        pixelRatio: 3.0,
      );

      if (pngBytes == null) {
        if (mounted) {
          context.showSnack('Não foi possível gerar a imagem para compartilhamento.');
        }
        return;
      }

      // 2. Salva temporariamente no armazenamento do app
      final String? filePath = await WorkoutShareService.saveTempPng(pngBytes);

      if (filePath == null) {
        if (mounted) {
          context.showSnack('Erro ao preparar o arquivo de imagem.');
        }
        return;
      }

      // 3. Dispara o compartilhamento para Instagram Stories
      // Importante: text deve ser null para que o Instagram abra a imagem como fundo completo (Stories),
      // e não como um sticker pequeno com legenda de texto ao lado.
      final success = await WorkoutShareService.shareWorkoutImage(
        filePath: filePath,
        text: null,
      );

      if (mounted && success) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnack('Erro ao compartilhar: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isLoadingCamera = _loadingSource == ImageSource.camera;
    final isLoadingGallery = _loadingSource == ImageSource.gallery;
    final isBusy = _loadingSource != null || _isSharing;

    // Cores adaptativas conforme o tema (Claro vs Escuro)
    final bgColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF161926) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withAlpha(22) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Story do Treino',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _photoBytes == null
                              ? 'Adicione uma foto de fundo'
                              : 'Foto adicionada! Pronto para compartilhar',
                          style: TextStyle(
                            color: _photoBytes == null
                                ? textSecondary
                                : const Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: _photoBytes == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_photoBytes != null)
                    IconButton(
                      key: const Key('remove_photo_button'),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      tooltip: 'Remover foto',
                      onPressed: () => setState(() => _photoBytes = null),
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textPrimary,
                      size: 26,
                    ),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Container(
                  width: 360,
                  height: 640,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withAlpha(160)
                            : Colors.black.withAlpha(25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: WorkoutShareCard(
                      session: widget.session,
                      backgroundImageBytes: _photoBytes,
                      onTakePhoto: isBusy ? null : () => _pickPhoto(ImageSource.camera),
                      isExport: _isExporting,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ações de Foto: Tirar Foto (Câmera) e Escolher da Galeria
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            key: const Key('take_photo_camera_button'),
                            icon: isLoadingCamera
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt_rounded, size: 20),
                            label: Text(
                              _photoBytes == null ? 'Tirar Foto' : 'Nova Foto',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: isBusy
                                ? null
                                : () => _pickPhoto(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            key: const Key('pick_photo_gallery_button'),
                            icon: isLoadingGallery
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569),
                                    ),
                                  )
                                : Icon(
                                    Icons.photo_library_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569),
                                  ),
                            label: Text(
                              'Galeria',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                            onPressed: isBusy
                                ? null
                                : () => _pickPhoto(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withAlpha(35)
                                    : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botão Principal: Compartilhar nos Stories (Gradiente Instagram)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF833AB4), // Roxo Instagram
                            Color(0xFFFD1D1D), // Vermelho Instagram
                            Color(0xFFFCB045), // Laranja/Dourado Instagram
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE1306C)
                                .withAlpha(isDark ? 80 : 100),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        key: const Key('share_instagram_button'),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isSharing
                              ? 'Preparando Story...'
                              : 'Compartilhar nos Stories',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        onPressed: isBusy ? null : _share,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
