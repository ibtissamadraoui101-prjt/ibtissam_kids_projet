// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';          // ← le fichier qu'on vient de créer
import 'services/tts_service.dart';
import 'services/progress_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/world_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avec les bonnes options selon la plateforme
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialisé');
  } catch (e) {
    // Si Firebase échoue, l'app continue en mode hors-ligne
    debugPrint('⚠️ Firebase non disponible : $e');
  }

  // Initialiser les services locaux (toujours nécessaires)
  await ProgressService().init();

  try {
    await TtsService().init();
  } catch (e) {
    debugPrint('⚠️ TTS non disponible : $e');
  }

  runApp(const LinguaKidsApp());
}

class LinguaKidsApp extends StatelessWidget {
  const LinguaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaKids Maroc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: ProgressService().hasStudent
          ? const WorldMapScreen()
          : const OnboardingScreen(),
    );
  }
}