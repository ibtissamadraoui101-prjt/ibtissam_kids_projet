// lib/main.dart
// 🎮 SPLASH + MASCOTTE DRAGON
// ✅ Même mascotte dragon que l'onboarding (CustomPainter)
// ✅ Étoiles orbitales, fond étoilé, TTS bienvenue
// ✅ Tous les init dans try-catch (iOS safe)

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
import 'screens/mascot_showcase_screen.dart';
import 'screens/daily_learning_screen.dart';

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

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialisé');
  } catch (e) {
    debugPrint('⚠️ Firebase: $e');
  }

  try {
    await ProgressService().init();
  } catch (e) {
    debugPrint('⚠️ ProgressService: $e');
  }

  try {
    TtsService().init();
  } catch (e) {
    debugPrint('⚠️ TTS: $e');
  }

  try {
    await SoundService().init();
    debugPrint('✅ SoundService initialisé');
  } catch (e) {
    debugPrint('⚠️ SoundService (app continue sans son): $e');
  }

  try {
    await SpeechService().init();
  } catch (e) {
    debugPrint('⚠️ SpeechService: $e');
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          bodyLarge:
              GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500),
          titleLarge:
              GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900),
          titleMedium:
              GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
          labelLarge:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: const _SplashGate(),
      routes: {
        '/mascot-test': (_) => const MascotShowcaseScreen(),
        '/daily-learning': (_) => const DailyLearningScreen(),
      },
    );
  }
}

// ════════════════════════════════════════════════════════
//  SPLASH GATE — affiche splash 3.5s puis route
// ════════════════════════════════════════════════════════
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const _RootRouter();
    return const _SplashScreen();
  }
}

// ════════════════════════════════════════════════════════
//  ÉCRAN SPLASH avec mascotte dragon
// ════════════════════════════════════════════════════════
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  // Orbit des étoiles
  late final AnimationController _orbitCtrl;
  late final Animation<double> _orbitAnim;

  // Dragon bounce
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  // Texte fade in
  late final AnimationController _textCtrl;
  late final Animation<double> _textAnim;

  // Scale entrée globale
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  // Points de chargement
  late final AnimationController _dotsCtrl;

  // Étoile filante
  late final AnimationController _shootCtrl;

  @override
  void initState() {
    super.initState();

    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _orbitAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_orbitCtrl);

    _bounceCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    _entryCtrl.forward();

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textAnim = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    Future.delayed(
        const Duration(milliseconds: 500), () => _textCtrl.forward());

    _dotsCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _shootCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(period: const Duration(seconds: 5));

    // Son de bienvenue + TTS
    Future.delayed(const Duration(milliseconds: 400), () {
      try {
        SoundService().startMusic('world_map');
      } catch (_) {}
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      try {
        TtsService().speak('Bonjour ! Bienvenue dans LinguaKids !');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _bounceCtrl.dispose();
    _entryCtrl.dispose();
    _textCtrl.dispose();
    _dotsCtrl.dispose();
    _shootCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _orbitAnim,
          _bounceAnim,
          _textAnim,
          _entryAnim,
          _dotsCtrl,
          _shootCtrl
        ]),
        builder: (_, __) => Stack(children: [
          // ── Fond ciel nocturne ──
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF1A237E),
                  Color(0xFF1565C0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: CustomPaint(size: size, painter: _StarsBgPainter()),
          ),

          // ── Étoile filante ──
          _buildShootingStar(size),

          // ── Nuages décoratifs ──
          _buildClouds(size),

          // ── Contenu centré ──
          Center(
            child: ScaleTransition(
              scale: _entryAnim,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ── Dragon + étoiles orbitales ──
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(alignment: Alignment.center, children: [
                    // Halo
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    // Étoiles orbitales
                    ..._buildOrbitStars(),
                    // Dragon bouncing
                    Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: CustomPaint(
                        size: const Size(150, 170),
                        painter: _DragonPainter(),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Titre ──
                FadeTransition(
                  opacity: _textAnim,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - _textAnim.value)),
                    child: Column(children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                        ).createShader(r),
                        child: const Text('LinguaKids',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 3))
                              ],
                            )),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child:
                            const Text('🇲🇦 Apprends le français avec joie !',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                )),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Bulle de parole mascotte ──
                FadeTransition(
                  opacity: _textAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                        'Salut ! Je suis Dino 🐉\nPrêt pour l\'aventure ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Points de chargement animés ──
                FadeTransition(
                  opacity: _textAnim,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = (_dotsCtrl.value + i * 0.33) % 1.0;
                      final scale = 0.5 + math.sin(phase * math.pi) * 0.6;
                      final alpha = 0.3 + math.sin(phase * math.pi) * 0.7;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              Colors.amber.withValues(alpha: alpha.clamp(0, 1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        transform: Matrix4.diagonal3Values(scale, scale, 1),
                      );
                    }),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildOrbitStars() {
    const emojis = ['⭐', '✨', '💫'];
    const sizes = [20.0, 16.0, 18.0];
    return List.generate(3, (i) {
      final angle = _orbitAnim.value + (i * 2 * math.pi / 3);
      final rx = 95.0;
      final ry = 40.0; // ellipse orbit
      final x = rx * math.cos(angle);
      final y = ry * math.sin(angle);
      return Transform.translate(
        offset: Offset(x, y),
        child: Text(emojis[i],
            style: TextStyle(fontSize: sizes[i], shadows: [
              Shadow(color: Colors.amber.withValues(alpha: 0.8), blurRadius: 8)
            ])),
      );
    });
  }

  Widget _buildShootingStar(Size size) {
    final t = _shootCtrl.value;
    if (t > 0.25) return const SizedBox.shrink();
    return Positioned(
      left: size.width * 0.8 - t * size.width * 0.65,
      top: size.height * 0.04 + t * size.height * 0.10,
      child: Opacity(
        opacity: ((0.25 - t) / 0.25).clamp(0, 1),
        child: Container(
          width: 55 + t * 35,
          height: 2,
          decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [Colors.white, Colors.transparent])),
        ),
      ),
    );
  }

  Widget _buildClouds(Size size) => IgnorePointer(
        child: Stack(children: [
          Positioned(top: 60, left: -10, child: _cloud(160, 60, 0.08)),
          Positioned(top: 40, right: -5, child: _cloud(140, 55, 0.07)),
          Positioned(
              top: size.height * 0.7, left: 10, child: _cloud(120, 45, 0.06)),
        ]),
      );

  Widget _cloud(double w, double h, double opacity) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(h),
        ),
      );
}

// ════════════════════════════════════════════════════════
//  MASCOTTE DRAGON (identique à onboarding)
// ════════════════════════════════════════════════════════
class _DragonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Corps
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 20), width: 80, height: 85),
        Paint()..color = const Color(0xFF9C27B0));

    // Ventre
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 25), width: 46, height: 60),
        Paint()..color = const Color(0xFFE1BEE7));

    // Aile gauche
    final wingL = Path()
      ..moveTo(cx - 36, cy + 12)
      ..cubicTo(cx - 72, cy - 18, cx - 68, cy + 32, cx - 36, cy + 40);
    canvas.drawPath(wingL, Paint()..color = const Color(0xFFCE93D8));

    // Aile droite
    final wingR = Path()
      ..moveTo(cx + 36, cy + 12)
      ..cubicTo(cx + 72, cy - 18, cx + 68, cy + 32, cx + 36, cy + 40);
    canvas.drawPath(wingR, Paint()..color = const Color(0xFFCE93D8));

    // Tête
    canvas.drawCircle(
        Offset(cx, cy - 30), 36, Paint()..color = const Color(0xFFAB47BC));

    // Cornes
    final hornPaint = Paint()..color = const Color(0xFF7B1FA2);
    final hornL = Path()
      ..moveTo(cx - 16, cy - 58)
      ..lineTo(cx - 25, cy - 78)
      ..lineTo(cx - 9, cy - 60);
    canvas.drawPath(hornL, hornPaint);
    final hornR = Path()
      ..moveTo(cx + 16, cy - 58)
      ..lineTo(cx + 25, cy - 78)
      ..lineTo(cx + 9, cy - 60);
    canvas.drawPath(hornR, hornPaint);

    // Oreilles
    canvas.drawCircle(
        Offset(cx - 32, cy - 52), 10, Paint()..color = const Color(0xFFAB47BC));
    canvas.drawCircle(
        Offset(cx + 32, cy - 52), 10, Paint()..color = const Color(0xFFAB47BC));

    // Blancs des yeux
    final white = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 13, cy - 33), 13, white);
    canvas.drawCircle(Offset(cx + 13, cy - 33), 13, white);

    // Pupilles
    canvas.drawCircle(
        Offset(cx - 12, cy - 32), 7, Paint()..color = const Color(0xFF1A237E));
    canvas.drawCircle(
        Offset(cx + 14, cy - 32), 7, Paint()..color = const Color(0xFF1A237E));

    // Reflets
    canvas.drawCircle(Offset(cx - 10, cy - 36), 3, white);
    canvas.drawCircle(Offset(cx + 16, cy - 36), 3, white);

    // Sourire
    final smilePath = Path()
      ..moveTo(cx - 11, cy - 17)
      ..quadraticBezierTo(cx, cx - 28, cx + 11, cy - 17);
    canvas.drawPath(
        smilePath,
        Paint()
          ..color = const Color(0xFF6A1B9A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    // Joues
    canvas.drawCircle(Offset(cx - 23, cy - 25), 8,
        Paint()..color = const Color(0xFFF48FB1).withValues(alpha: 0.6));
    canvas.drawCircle(Offset(cx + 23, cy - 25), 8,
        Paint()..color = const Color(0xFFF48FB1).withValues(alpha: 0.6));

    // Narines
    final nose = Paint()..color = const Color(0xFF7B1FA2);
    canvas.drawCircle(Offset(cx - 5, cy - 22), 3, nose);
    canvas.drawCircle(Offset(cx + 5, cy - 22), 3, nose);

    // Queue
    final tailPath = Path()
      ..moveTo(cx + 32, cy + 52)
      ..cubicTo(cx + 62, cy + 62, cx + 72, cy + 40, cx + 56, cy + 22);
    canvas.drawPath(
        tailPath,
        Paint()
          ..color = const Color(0xFF9C27B0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        Offset(cx + 56, cy + 22), 6, Paint()..color = const Color(0xFFCE93D8));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════
//  FOND ÉTOILÉ
// ════════════════════════════════════════════════════════
class _StarsBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);
    for (int i = 0; i < 100; i++) {
      final r = rng.nextDouble() * 1.6 + 0.3;
      final a = 0.15 + rng.nextDouble() * 0.6;
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        r,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════
//  ROUTEUR PRINCIPAL
// ════════════════════════════════════════════════════════
class _RootRouter extends StatefulWidget {
  const _RootRouter();
  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      try {
        if (ProgressService().hasStudent) {
          SoundService().startMusic('world_map');
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        if (ProgressService().hasStudent) return const WorldMapScreen();
        return const OnboardingScreen();
      },
    );
  }
}
