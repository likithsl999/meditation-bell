import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/meditation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storage = await StorageService.create();
  final audio = AudioService();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<AudioService>.value(value: audio),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage, audio),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => MeditationProvider(audio, storage),
        ),
      ],
      child: const MeditationBellApp(),
    ),
  );
}

class MeditationBellApp extends StatelessWidget {
  const MeditationBellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meditation Bell',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/stats': (_) => const StatsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B9E8A),
      brightness: brightness,
      surface: isDark ? const Color(0xFF0F1714) : const Color(0xFFF5FAF8),
      surfaceContainerHigh:
          isDark ? const Color(0xFF1C2825) : const Color(0xFFE8F0EC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}
