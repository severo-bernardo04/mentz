import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/routes/app_navigation.dart';
import 'features/auth/auth_gate.dart';
import 'services/settings_service.dart';
import 'services/timer_overlay_service.dart';
import 'widgets/timer_overlay_window.dart';
import 'widgets/workout_timer_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Cronômetro sobre outros apps (Android), quando o Mentz sai da frente
  TimerOverlayService().attach();
  runApp(const MyApp());
}

/// Ponto de entrada da janela flutuante do Android, iniciado pelo pacote
/// `flutter_overlay_window` em um isolate separado do app.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TimerOverlayWindow(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final isDark = SettingsService().isDarkMode;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SettingsService.lightTheme,
          darkTheme: SettingsService.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          navigatorKey: appNavigatorKey,
          navigatorObservers: [appRouteObserver],
          // Cronômetro do treino em andamento, por cima de todas as telas
          builder: (context, child) =>
              WorkoutTimerOverlay(child: child ?? const SizedBox.shrink()),
          home: const AuthGate(),
        );
      },
    );
  }
}