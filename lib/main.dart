// lib/main.dart
// ✅ v3.1 — Chanson d'accueil douce au lancement
//
// NOUVEAUTÉS :
//   • Écran de splash animé (étoiles + mascotte) pendant 2.5s
//   • TTS chanson d'accueil : "Bonjour ! Bienvenue dans LinguaKids !"
//   • Musique douce qui démarre en fade-in dès le splash
//   • Police Nunito (ronde, enfantine)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'firebase_options.dart';
import 'services/progress_service.dart';
import 'services/tts_service.dart';
import 'services/sound_service.dart';
import 'services/speech_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/world_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ProgressService().init();
  TtsService().init();
  await SoundService().init();
  await SpeechService().init();

  runApp(const LinguaKidsApp());
}

class LinguaKidsApp extends StatelessWidget {
  const LinguaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      // ✅ NOUVEAU : splash d'accueil avant le routeur
      home: const _SplashGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SPLASH GATE — affiche le splash puis route vers l'app
// ─────────────────────────────────────────────────────────
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Durée du splash : 8.8 secondes
    Future.delayed(const Duration(milliseconds: 8800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const _WelcomeSplash();
    return const _RootRouter();
  }
}

// ─────────────────────────────────────────────────────────
// ÉCRAN SPLASH avec chanson d'accueil douce
// ─────────────────────────────────────────────────────────
class _WelcomeSplash extends StatefulWidget {
  const _WelcomeSplash();
  @override
  State<_WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<_WelcomeSplash>
    with TickerProviderStateMixin {

  // Animation mascotte (bounce)
  late final AnimationController _mascotCtrl;
  late final Animation<double>   _mascotAnim;

  // Animation étoiles orbitales
  late final AnimationController _starsCtrl;
  late final Animation<double>   _starsAnim;

  // Animation texte (fade in)
  late final AnimationController _textCtrl;
  late final Animation<double>   _textAnim;

  // Animation fond (scale in)
  late final AnimationController _bgCtrl;
  late final Animation<double>   _bgAnim;

  @override
  void initState() {
    super.initState();

    // Fond scale in
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOutCubic);
    _bgCtrl.forward();

    // Mascotte bounce
    _mascotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _mascotAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: 1.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.92), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0),  weight: 1),
    ]).animate(CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeOut));

    // Étoiles rotation
    _starsCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _starsAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_starsCtrl);

    // Texte fade in
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textAnim = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    // Séquence : fond → mascotte → son + TTS → texte
    Future.delayed(const Duration(milliseconds: 300), () {
      _mascotCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      // ✅ CHANSON D'ACCUEIL : musique douce + TTS chaleureux
      SoundService().startMusic('welcome'); // ou 'onboarding' selon ton fichier
      TtsService().speak('Bonjour ! Bienvenue dans LinguaKids !');
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _mascotCtrl.dispose();
    _starsCtrl.dispose();
    _textCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mascotAnim, _starsAnim, _textAnim, _bgAnim]),
        builder: (_, __) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E27), Color(0xFF0D2137), Color(0xFF1565C0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(children: [

              // ── Étoiles de fond (fixes, petites) ──────────────
              ..._buildBackgroundStars(size),

              // ── Étoiles orbitales animées ─────────────────────
              ..._buildOrbitStars(size),

              // ── Contenu centré ────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Mascotte (emoji owl ou rocket)
                    Transform.scale(
                      scale: _mascotAnim.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.6),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🦉', style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nom de l'app
                    Opacity(
                      opacity: _textAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _textAnim.value)),
                        child: Column(children: [
                          const Text(
                            'LinguaKids',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: const Text(
                              '🇲🇦 Apprends le français avec joie !',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Points de chargement animés
                    Opacity(
                      opacity: _textAnim.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final delay = i * 0.33;
                          final phase = (_starsCtrl.value + delay) % 1.0;
                          final scale = 0.6 + math.sin(phase * math.pi) * 0.6;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withOpacity(
                                  (0.4 + math.sin(phase * math.pi) * 0.6).clamp(0.0, 1.0)),
                            ),
                            transform: Matrix4.diagonal3Values(scale, scale, 1),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // Étoiles fixes en arrière-plan
  List<Widget> _buildBackgroundStars(Size size) {
    final rng = math.Random(99);
    return List.generate(30, (i) {
      final x  = rng.nextDouble() * size.width;
      final y  = rng.nextDouble() * size.height;
      final s  = 1.5 + rng.nextDouble() * 2.5;
      final op = 0.2 + rng.nextDouble() * 0.5;
      return Positioned(
        left: x, top: y,
        child: Container(
          width: s, height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(op),
          ),
        ),
      );
    });
  }

  // Étoiles orbitales qui tournent autour de la mascotte
  List<Widget> _buildOrbitStars(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 60; // centre mascotte
    final emojis = ['⭐', '🌟', '✨'];
    return List.generate(3, (i) {
      final angle  = _starsAnim.value + (i * 2 * math.pi / 3);
      final radius = 90.0;
      final x = cx + radius * math.cos(angle) - 15;
      final y = cy + radius * math.sin(angle) - 15;
      return Positioned(
        left: x, top: y,
        child: Text(emojis[i], style: const TextStyle(fontSize: 22)),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────
// ROUTEUR PRINCIPAL
// ─────────────────────────────────────────────────────────
class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    // Lance la musique de fond selon le contexte
    Future.delayed(const Duration(milliseconds: 300), () {
      if (ProgressService().hasStudent) {
        SoundService().startMusic('world_map');
      }
      // Si pas d'élève → la musique reste celle du splash/onboarding
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