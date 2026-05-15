// lib/screens/intro/story_intro_screen.dart
// ═══════════════════════════════════════════════════════════
// LinguaKids — Story Intro Screen
// Séquence animée : lettres jouent → sorcier kidnappe → îles grises → Lumi demande de l'aide
// AUCUN texte de lecture requis — tout visuel + son
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../widgets/lumi_mascot.dart';
import '../world_map_screen.dart';

class StoryIntroScreen extends StatefulWidget {
  const StoryIntroScreen({super.key});
  @override
  State<StoryIntroScreen> createState() => _StoryIntroScreenState();
}

class _StoryIntroScreenState extends State<StoryIntroScreen>
    with TickerProviderStateMixin {

  // Étapes du scénario
  int _step = 0; // 0=lettres jouent, 1=sorcier, 2=lettres kidnappées, 3=île grise, 4=Lumi demande aide

  // Contrôleurs principaux
  late AnimationController _letterFloatCtrl;
  late AnimationController _wizardCtrl;
  late AnimationController _greyCtrl;
  late AnimationController _lumiCtrl;
  late AnimationController _starCtrl;
  late AnimationController _btnPulseCtrl;

  late Animation<double> _letterFloat;
  late Animation<double> _wizardSlide;
  late Animation<double> _greyAnim;
  late Animation<double> _lumiFloat;
  late Animation<double> _starAnim;
  late Animation<double> _btnPulse;

  // État des lettres (pour l'animation de vol)
  final List<Offset> _letterOffsets = [
    const Offset(0.15, 0.25),
    const Offset(0.44, 0.18),
    const Offset(0.73, 0.25),
  ];
  final List<bool> _lettersVisible = [true, true, true];
  bool _islandGrey = false;

  @override
  void initState() {
    super.initState();

    _letterFloatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _wizardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _greyCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _lumiCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _starCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _btnPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

    _letterFloat = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _letterFloatCtrl, curve: Curves.easeInOut));
    _wizardSlide = Tween<double>(begin: 1.5, end: 0.0).animate(
        CurvedAnimation(parent: _wizardCtrl, curve: Curves.easeOutBack));
    _greyAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _greyCtrl, curve: Curves.easeInOut));
    _lumiFloat = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _lumiCtrl, curve: Curves.easeInOut));
    _starAnim  = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _starCtrl, curve: Curves.easeInOut));
    _btnPulse  = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _btnPulseCtrl, curve: Curves.easeInOut));

    // Déroulement automatique
    _playSequence();
  }

  Future<void> _playSequence() async {
    // Étape 0 : lettres jouent (2.5s)
    await Future.delayed(const Duration(milliseconds: 2500));

    // Étape 1 : sorcier apparaît
    setState(() => _step = 1);
    _wizardCtrl.forward();
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 1800));

    // Étape 2 : lettres s'envolent
    setState(() {
      _step = 2;
      _lettersVisible[0] = false;
      _lettersVisible[1] = false;
      _lettersVisible[2] = false;
    });
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1200));

    // Étape 3 : île devient grise
    setState(() { _step = 3; _islandGrey = true; });
    _greyCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    // Étape 4 : Lumi demande de l'aide
    setState(() => _step = 4);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _letterFloatCtrl.dispose();
    _wizardCtrl.dispose();
    _greyCtrl.dispose();
    _lumiCtrl.dispose();
    _starCtrl.dispose();
    _btnPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: LKColors.skyBlue,
      body: Stack(children: [
        // ── Fond ciel dégradé ────────────────────────────
        _buildBackground(),
        // ── Étoiles ciel ─────────────────────────────────
        _buildStars(),
        // ── Soleil ───────────────────────────────────────
        _buildSun(),
        // ── Nuages ───────────────────────────────────────
        _buildClouds(),
        // ── Île principale ───────────────────────────────
        _buildIsland(size),
        // ── Lettres flottantes ───────────────────────────
        if (_step <= 1) _buildFloatingLetters(size),
        // ── Sorcier ──────────────────────────────────────
        if (_step >= 1) _buildWizard(size),
        // ── Mer ──────────────────────────────────────────
        _buildSea(size),
        // ── Lumi avec bulle ──────────────────────────────
        if (_step == 4) _buildLumiHelpRequest(size),
        // ── Bouton START (étape finale) ───────────────────
        if (_step == 4) _buildStartButton(size),
        // ── Skip button ──────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: GestureDetector(
            onTap: _goToMap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: const Text('Passer →',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── BACKGROUND ──────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _greyAnim,
      builder: (_, __) {
        final t = _greyAnim.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(const Color(0xFF1B6FA8), const Color(0xFF4A4A6A), t)!,
                Color.lerp(const Color(0xFF42B8E0), const Color(0xFF7A8090), t)!,
                Color.lerp(const Color(0xFF87CEEB), const Color(0xFFA0AABC), t)!,
              ],
            ),
          ),
        );
      },
    );
  }

  // ── ÉTOILES ─────────────────────────────────────────────
  Widget _buildStars() {
    const positions = [
      Offset(0.10, 0.04), Offset(0.25, 0.08), Offset(0.42, 0.03),
      Offset(0.60, 0.07), Offset(0.78, 0.03), Offset(0.88, 0.09),
    ];
    return Stack(children: positions.map((p) => Positioned(
      left: MediaQuery.of(context).size.width * p.dx,
      top:  MediaQuery.of(context).size.height * p.dy,
      child: AnimatedBuilder(
        animation: _starAnim,
        builder: (_, __) => Opacity(
          opacity: _starAnim.value,
          child: Container(width: 3, height: 3,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    )).toList());
  }

  // ── SOLEIL ──────────────────────────────────────────────
  Widget _buildSun() {
    return AnimatedBuilder(
      animation: _greyAnim,
      builder: (_, __) {
        final t = _greyAnim.value;
        return Positioned(
          top: 55, right: 24,
          child: Opacity(
            opacity: 1 - t * 0.7,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFF176), Color(0xFFFFD93D)]),
                border: Border.all(color: const Color(0xFFFFA000), width: 2),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFFFD93D).withOpacity(0.5), blurRadius: 16, spreadRadius: 4)],
              ),
              child: const Center(child: Text('☀', style: TextStyle(fontSize: 24))),
            ),
          ),
        );
      },
    );
  }

  // ── NUAGES ──────────────────────────────────────────────
  Widget _buildClouds() {
    return Stack(children: [
      _cloud(left: 14, top: 52, w: 80, h: 28),
      _cloud(left: 190, top: 36, w: 58, h: 22),
    ]);
  }

  Widget _cloud({required double left, required double top,
      required double w, required double h}) {
    return AnimatedBuilder(
      animation: _greyAnim,
      builder: (_, __) => Positioned(
        left: left, top: top,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_greyMatrix(_greyAnim.value * 0.5)),
          child: SizedBox(width: w, height: h,
            child: CustomPaint(painter: _CloudPainter())),
        ),
      ),
    );
  }

  // ── ÎLE ─────────────────────────────────────────────────
  Widget _buildIsland(Size size) {
    return AnimatedBuilder(
      animation: _greyAnim,
      builder: (_, __) {
        final t = _greyAnim.value;
        return Positioned(
          bottom: size.height * 0.25,
          left: size.width * 0.10,
          right: size.width * 0.10,
          height: 155,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_greyMatrix(t)),
            child: CustomPaint(painter: _IslandPainter(greyness: t)),
          ),
        );
      },
    );
  }

  // ── LETTRES FLOTTANTES ──────────────────────────────────
  Widget _buildFloatingLetters(Size size) {
    final letters  = ['A', 'B', 'C'];
    final colors   = [const Color(0xFFFFD93D), const Color(0xFFFF8C9E), const Color(0xFF85DAFF)];
    final offsets  = [const Offset(0, 0), const Offset(0.3, -0.5), const Offset(0, 0.2)];

    return AnimatedBuilder(
      animation: _letterFloat,
      builder: (_, __) {
        return Stack(children: List.generate(3, (i) {
          final baseY = size.height * _letterOffsets[i].dy;
          final baseX = size.width  * _letterOffsets[i].dx;
          final floatY = _letterFloat.value + offsets[i].dy * 6;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            left:   _lettersVisible[i] ? baseX : baseX + size.width * 0.8,
            top:    _lettersVisible[i] ? baseY + floatY : baseY - 100,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _lettersVisible[i] ? 1.0 : 0.0,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i],
                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 2.5),
                  boxShadow: [BoxShadow(
                    color: colors[i].withOpacity(0.5), blurRadius: 14, spreadRadius: 2)],
                ),
                child: Center(
                  child: Text(letters[i],
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
                ),
              ),
            ),
          );
        }));
      },
    );
  }

  // ── SORCIER ─────────────────────────────────────────────
  Widget _buildWizard(Size size) {
    return AnimatedBuilder(
      animation: _wizardSlide,
      builder: (_, __) {
        return Positioned(
          right: size.width * _wizardSlide.value + 16,
          top:   size.height * 0.15,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Éclairs magiques
            if (_step == 2)
              const Text('⚡', style: TextStyle(fontSize: 24)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3D0070).withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA855F7), width: 2),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.5),
                  blurRadius: 20, spreadRadius: 4)],
              ),
              child: const Text('🧙', style: TextStyle(fontSize: 46)),
            ),
            const SizedBox(height: 4),
            if (_step == 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D0070).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
                ),
                child: const Text('Mwa ha ha! 😈',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: Color(0xFFE8BBFF))),
              ),
            if (_step >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D0070).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
                ),
                child: const Text('🎒 A B C',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD93D))),
              ),
          ]),
        );
      },
    );
  }

  // ── MER ─────────────────────────────────────────────────
  Widget _buildSea(Size size) {
    return AnimatedBuilder(
      animation: _greyAnim,
      builder: (_, __) {
        final t = _greyAnim.value;
        return Positioned(
          bottom: 0, left: 0, right: 0,
          height: size.height * 0.28,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_greyMatrix(t * 0.6)),
            child: CustomPaint(painter: _SeaPainter()),
          ),
        );
      },
    );
  }

  // ── LUMI AIDE ─────────────────────────────────────────────
  Widget _buildLumiHelpRequest(Size size) {
    return AnimatedBuilder(
      animation: _lumiFloat,
      builder: (_, __) {
        return Positioned(
          bottom: size.height * 0.22,
          left: 20,
          child: Transform.translate(
            offset: Offset(0, _lumiFloat.value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LumiMascot(mood: LumiMood.encourage, size: 56),
                const SizedBox(width: 10),
                // Bulle de pensée
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 170),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: LKColors.sun, width: 2.5),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0,4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Geste de pointage vers les îles grises
                      const Text('🏝️ → ❓', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('🆘', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Les lettres ont disparu !',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: Colors.orange.shade800))),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('👆', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        const Text('Tu peux m\'aider ?',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: LKColors.textOnGreen)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── BOUTON START ─────────────────────────────────────────
  Widget _buildStartButton(Size size) {
    return Positioned(
      bottom: 40,
      left: 0, right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _btnPulse,
          builder: (_, __) => Transform.scale(
            scale: _btnPulse.value,
            child: GestureDetector(
              onTap: _goToMap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD93D), Color(0xFFFFA000)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFFF8C00), width: 3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.55),
                        blurRadius: 22, spreadRadius: 4, offset: const Offset(0, 6)),
                    const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,3)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🗝️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Text('PARTIR À L\'AVENTURE !',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                          color: Color(0xFF7A3800), letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToMap() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => const WorldMapScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ));
  }

  // ── Helper : matrice greyscale ───────────────────────────
  List<double> _greyMatrix(double t) {
    final s = 1 - t * 0.85;
    return [
      s + (1-s)*0.2126, (1-s)*0.2126, (1-s)*0.2126, 0, 0,
      (1-s)*0.7152, s + (1-s)*0.7152, (1-s)*0.7152, 0, 0,
      (1-s)*0.0722, (1-s)*0.0722, s + (1-s)*0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

// ── Custom Painters ──────────────────────────────────────────
class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.92);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height*0.35, size.width, size.height*0.65),
      Radius.circular(size.height*0.35)), p);
    canvas.drawCircle(Offset(size.width*0.28, size.height*0.36), size.height*0.40, p);
    canvas.drawCircle(Offset(size.width*0.55, size.height*0.26), size.height*0.46, p);
    canvas.drawCircle(Offset(size.width*0.76, size.height*0.38), size.height*0.32, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _IslandPainter extends CustomPainter {
  final double greyness;
  const _IslandPainter({required this.greyness});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final green  = Color.lerp(const Color(0xFF5DCAA5), const Color(0xFF8A9FA0), greyness)!;
    final dark   = Color.lerp(const Color(0xFF3DAD8A), const Color(0xFF6A8080), greyness)!;
    final light  = Color.lerp(const Color(0xFF7DDBB8), const Color(0xFFAABDBD), greyness)!;
    final sand   = Color.lerp(const Color(0xFFF5D06A), const Color(0xFF9A8050), greyness)!;

    // Corps île
    final path = Path();
    path.moveTo(w*0.08, h*0.50);
    path.cubicTo(w*-0.02, h*0.25, w*-0.02, h*0.06, w*0.18, h*0.03);
    path.cubicTo(w*0.33, h*-0.01, w*0.57, h*-0.01, w*0.74, h*0.03);
    path.cubicTo(w*1.00, h*0.06, w*1.02, h*0.25, w*0.98, h*0.50);
    path.cubicTo(w*0.96, h*0.70, w*0.86, h*0.85, w*0.70, h*0.90);
    path.cubicTo(w*0.55, h*0.96, w*0.35, h*0.96, w*0.20, h*0.90);
    path.cubicTo(w*0.04, h*0.84, w*0.06, h*0.68, w*0.08, h*0.50);
    path.close();

    canvas.drawPath(path, Paint()..shader = LinearGradient(
      colors: [light, green, dark], stops: const [0.0, 0.45, 1.0],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0,0,w,h)));

    // Lumière dessus
    final top = Path();
    top.moveTo(w*0.08, h*0.50);
    top.cubicTo(w*-0.02, h*0.25, w*-0.02, h*0.06, w*0.18, h*0.03);
    top.cubicTo(w*0.33, h*-0.01, w*0.57, h*-0.01, w*0.74, h*0.03);
    top.cubicTo(w*1.00, h*0.06, w*1.02, h*0.25, w*0.98, h*0.50);
    top.cubicTo(w*0.95, h*0.35, w*0.72, h*0.28, w*0.50, h*0.30);
    top.cubicTo(w*0.28, h*0.32, w*0.08, h*0.42, w*0.08, h*0.50);
    top.close();
    canvas.drawPath(top, Paint()..color = Colors.white.withOpacity(0.35));

    // Sable
    final sandPath = Path();
    sandPath.moveTo(w*0.08, h*0.72);
    sandPath.cubicTo(w*0.10, h*0.80, w*0.20, h*0.90, w*0.35, h*0.93);
    sandPath.cubicTo(w*0.50, h*0.96, w*0.62, h*0.95, w*0.74, h*0.90);
    sandPath.cubicTo(w*0.86, h*0.85, w*0.96, h*0.72, w*0.96, h*0.72);
    sandPath.close();
    canvas.drawPath(sandPath, Paint()..color = sand);

    // Contour
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
  }
  @override bool shouldRepaint(_IslandPainter o) => o.greyness != greyness;
}

class _SeaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, size.height*0.15, size.width, size.height),
      Paint()..color = const Color(0xFF1A7FA8));
    final p = Paint()..color = const Color(0xFF4DC8E8);
    final path = Path();
    path.moveTo(-20, size.height*0.10);
    for (double x = -20; x <= size.width + 50; x += 50) {
      path.quadraticBezierTo(x+12, size.height*0.10-14, x+25, size.height*0.10);
      path.quadraticBezierTo(x+38, size.height*0.10+14, x+50, size.height*0.10);
    }
    path.lineTo(size.width+20, size.height);
    path.lineTo(-20, size.height);
    path.close();
    canvas.drawPath(path, p);
    // Écume
    for (double x = 10; x < size.width; x += 60) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(x+20, size.height*0.13), width: 44, height: 11),
        Paint()..color = Colors.white.withOpacity(0.28));
    }
  }
  @override bool shouldRepaint(_) => false;
}