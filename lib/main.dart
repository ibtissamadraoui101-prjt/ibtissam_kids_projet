// lib/main.dart
// ✅ AMÉLIORATIONS v3 :
//   • Police Nunito (plus ronde, plus enfantine que Roboto)
//   • Thème couleurs plus vif / joyeux
//   • HapticFeedback global sur tous les navigations
//   • Initialisation SpeechService au démarrage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/progress_service.dart';
import 'services/tts_service.dart';
import 'services/sound_service.dart';
import 'services/speech_service.dart';   // ✅ NOUVEAU
import 'screens/onboarding_screen.dart';
import 'screens/world_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Portrait uniquement ──
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Barre de statut transparente ──
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
  ));

  // ── Firebase ──
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Services ──
  await ProgressService().init();
  TtsService().init();
  await SoundService().init();
  await SpeechService().init();   // ✅ NOUVEAU

  runApp(const LinguaKidsApp());
}

class LinguaKidsApp extends StatelessWidget {
  const LinguaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ NOUVEAU : thème Nunito — police ronde et enfantine
    final baseTextTheme = GoogleFonts.nunitoTextTheme();

    return MaterialApp(
      title: 'LinguaKids Maroc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        // ✅ Police Nunito partout
        textTheme: baseTextTheme.copyWith(
          bodyLarge:   GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium:  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500),
          titleLarge:  GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900),
          titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
          labelLarge:  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
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