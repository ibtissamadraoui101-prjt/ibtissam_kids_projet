// lib/main.dart
// ✅ AJOUT : initialisation SoundService au démarrage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/progress_service.dart';
import 'services/tts_service.dart';
import 'services/sound_service.dart';   // ✅ NOUVEAU
import 'screens/onboarding_screen.dart';
import 'screens/world_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation portrait uniquement ──
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialisé');

  // ── Progression locale ──
  await ProgressService().init();

  // ── TTS ──
  TtsService().init();

  // ── Son ✅ NOUVEAU ──
  await SoundService().init();

  runApp(const LinguaKidsApp());
}

class LinguaKidsApp extends StatelessWidget {
  const LinguaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                'LinguaKids Maroc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3:     true,
        colorScheme:      ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        // ── Retirer le splash par défaut (on a nos propres sons) ──
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const _RootRouter(),
    );
  }
}

/// Route racine — décide si onboarding ou carte du monde
class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    // ✅ Musique de fond dès l'ouverture
    Future.delayed(const Duration(milliseconds: 500), () {
      if (ProgressService().hasStudent) {
        SoundService().startMusic('world_map');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        if (ProgressService().hasStudent) {
          return const WorldMapScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}
