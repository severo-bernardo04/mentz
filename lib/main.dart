import 'package:flutter/material.dart';

import 'features/auth/login_page.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().loadSettings();
  runApp(const MyApp());
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
          home: const LoginPage(),
        );
      },
    );
  }
}