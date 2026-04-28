// lib/screens/world_map_screen.dart
// 🎮 CARTE DU MONDE — Style Candy Crush : îles 3D flottantes, océan animé,
//    ciel avec nuages, étoiles filantes, boutons brillants

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'island_levels_screen.dart';
import 'teacher/teacher_login_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});
  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {

  // ── Animations ────────────────────────────────────────
  late final AnimationController _oceanCtrl;   // vagues ondulantes
  late final AnimationController _cloudCtrl;   // nuages qui dérivent
  late final AnimationController _floatCtrl;   // îles qui flottent
  late final AnimationController _starCtrl;    // animation étoile
  late final AnimationController _shootCtrl;   // étoile filante

  late final Animation<double> _oceanAnim;
  late final Animation<double> _cloudAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _starAnim;
  late final Animation<double> _shootAnim;

  int _prevStars = 0;

  // Config des 5 îles
  static const _islands = [
    _IslandConfig('CP',  '🌊', [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
        'Les bases', 0),
    _IslandConfig('CE1', '🌿', [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF81C784)],
        'Progresser', 9),
    _IslandConfig('CE2', '🔥', [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFFF7043)],
        'Phrases', 27),
    _IslandConfig('CM1', '🌙', [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFCE93D8)],
        'Histoires', 54),
    _IslandConfig('CM2', '🚀', [Color(0xFF7F0000), Color(0xFFD32F2F), Color(0xFFEF9A9A)],
        'Maîtrise', 90),
  ];

  @override
  void initState() {
    super.initState();
    _prevStars = ProgressService().student?.totalStars ?? 0;

    _oceanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _cloudCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _starCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shootCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(period: const Duration(seconds: 8));

    _oceanAnim = CurvedAnimation(parent: _oceanCtrl, curve: Curves.easeInOut);
    _cloudAnim = CurvedAnimation(parent: _cloudCtrl, curve: Curves.linear);
    _floatAnim = Tween<double>(begin: -7, end: 7)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _starAnim  = Tween<double>(begin: 1.0, end: 1.6)
        .animate(CurvedAnimation(parent: _starCtrl, curve: Curves.elasticOut));
    _shootAnim = CurvedAnimation(parent: _shootCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _oceanCtrl.dispose(); _cloudCtrl.dispose(); _floatCtrl.dispose();
    _starCtrl.dispose();  _shootCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        // Déclencher animation étoile si nouvelles étoiles
        final cur = ProgressService().student?.totalStars ?? 0;
        if (cur > _prevStars) { _prevStars = cur; _starCtrl.forward(from: 0); }

        final islands = ProgressService().buildIslands();
        final size    = MediaQuery.of(context).size;

        return Scaffold(
          body: Stack(children: [
            // ── Ciel dégradé ──────────────────────────────
            _buildSky(size),
            // ── Nuages animés ──────────────────────────────
            AnimatedBuilder(animation: _cloudAnim, builder: (_, __) => _buildClouds(size)),
            // ── Étoile filante ─────────────────────────────
            AnimatedBuilder(animation: _shootAnim, builder: (_, __) => _buildShootingStar(size)),
            // ── Vagues de l'océan ──────────────────────────
            AnimatedBuilder(animation: _oceanAnim, builder: (_, __) => _buildOcean(size)),
            // ── Contenu scrollable ─────────────────────────
            SafeArea(child: Column(children: [
              _buildTopBar(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, __) => ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: islands.length,
                    itemBuilder: (_, i) {
                      final cfg = _islands[i];
                      final isl = islands[i];
                      // Flottement décalé par île
                      final bob = isl.isUnlocked ? _floatAnim.value * (i % 2 == 0 ? 1 : -0.7) : 0.0;
                      return _IslandCard(
                        island: isl,
                        config: cfg,
                        bobOffset: bob,
                        onTap: () => _onIslandTap(context, isl),
                      );
                    },
                  ),
                ),
              ),
            ])),
          ]),
        );
      },
    );
  }

  // ─── Ciel ─────────────────────────────────────────────
  Widget _buildSky(Size size) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0A0E27),  // nuit profonde
          Color(0xFF0D2137),  // bleu nuit
          Color(0xFF1A4A6E),  // bleu océan
          Color(0xFF1565C0),  // bleu vif
          Color(0xFF1E88E5),  // bleu clair
        ],
        stops: [0.0, 0.2, 0.45, 0.7, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: CustomPaint(size: size, painter: _StarsPainter()),
  );

  // ─── Nuages ───────────────────────────────────────────
  Widget _buildClouds(Size size) {
    final progress = _cloudAnim.value;
    return IgnorePointer(
      child: Stack(children: [
        _floatingCloud(size, progress, 0.0,  0.08, 180, 60,  0.12),
        _floatingCloud(size, progress, 0.3,  0.14, 140, 50,  0.08),
        _floatingCloud(size, progress, 0.65, 0.06, 200, 70,  0.10),
        _floatingCloud(size, progress, 0.15, 0.22, 120, 45,  0.07),
        _floatingCloud(size, progress, 0.55, 0.30, 160, 55,  0.09),
      ]),
    );
  }

  Widget _floatingCloud(Size s, double t, double startFrac, double topFrac,
      double w, double h, double opacity) {
    final x = ((startFrac + t * 0.15) % 1.1 - 0.05) * s.width;
    final y = s.height * topFrac;
    return Positioned(
      left: x, top: y,
      child: Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(h),
        ),
      ),
    );
  }

  // ─── Étoile filante ───────────────────────────────────
  Widget _buildShootingStar(Size size) {
    final t = _shootAnim.value;
    if (t > 0.4) return const SizedBox.shrink();
    final x = size.width * 0.8 - t * size.width * 0.7;
    final y = size.height * 0.05 + t * size.height * 0.15;
    return Positioned(
      left: x, top: y,
      child: Opacity(
        opacity: (0.4 - t) / 0.4,
        child: Container(
          width: 60 + t * 40, height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white, Colors.white.withValues(alpha: 0)]),
          ),
        ),
      ),
    );
  }

  // ─── Océan ────────────────────────────────────────────
  Widget _buildOcean(Size size) => Positioned(
    bottom: 0, left: 0, right: 0,
    child: CustomPaint(
      size: Size(size.width, 180),
      painter: _OceanPainter(progress: _oceanAnim.value),
    ),
  );

  // ─── Barre du haut ────────────────────────────────────
  Widget _buildTopBar() {
    final student = ProgressService().student;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        // Avatar + nom
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(student?.avatarEmoji ?? '🦁',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 7),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  student?.name ?? 'Mon héros',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if ((student?.currentStreak ?? 0) > 0)
                  Row(children: [
                    const Text('🔥', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text('${student!.currentStreak}j',
                      style: TextStyle(
                          color: Colors.orange.shade200, fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  ]),
              ]),
            ]),
          ),
        ),

        const Spacer(),

        // Compteur étoiles animé
        AnimatedBuilder(
          animation: _starAnim,
          builder: (_, __) => Transform.scale(
            scale: _starAnim.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.55),
                    blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 5),
                Text(
                  '${student?.totalStars ?? 0}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ]),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Bouton enseignant
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TeacherLoginScreen())),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.school_outlined, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  // ─── Tap sur une île ──────────────────────────────────
  void _onIslandTap(BuildContext ctx, Island island) {
    if (!island.isUnlocked) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
          '🔒 Il te faut ${island.starsToUnlock} ⭐ pour débloquer ${island.label} !'),
        backgroundColor: const Color(0xFF1A237E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    TtsService().speak('Île ${island.label} !');
    Navigator.push(ctx, PageRouteBuilder(
      pageBuilder: (_, a, __) => IslandLevelsScreen(niveauLabel: island.label),
      transitionsBuilder: (_, a, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: a, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 420),
    ));
  }
}

// ─── Card d'une île ───────────────────────────────────────
class _IslandCard extends StatelessWidget {
  final Island island;
  final _IslandConfig config;
  final double bobOffset;
  final VoidCallback onTap;

  const _IslandCard({
    required this.island, required this.config,
    required this.bobOffset, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked   = !island.isUnlocked;
    final colors   = locked
        ? [const Color(0xFF1C2633), const Color(0xFF2D3A4A)]
        : config.colors;
    final progress = island.completionRate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: Offset(0, bobOffset),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                // Ombre profonde → effet surélevé
                BoxShadow(color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 14, offset: const Offset(0, 10)),
                // Halo coloré
                if (!locked)
                  BoxShadow(color: colors[1].withValues(alpha: 0.35),
                      blurRadius: 24, spreadRadius: 1, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(children: [
                // ── Fond dégradé ──
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // ── Texture décorative ──
                Positioned.fill(
                  child: CustomPaint(painter: _IslandTexturePainter(locked: locked)),
                ),

                // ── Reflet brillant en haut ──
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // ── Contenu ──
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    // ── Île emoji flottante ──
                    Container(
                      width: 78, height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text(locked ? '🔒' : config.emoji,
                            style: const TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ── Texte + progression ──
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        Row(children: [
                          Text(config.label,
                            style: TextStyle(
                              color: locked ? Colors.white.withValues(alpha: 0.4) : Colors.white,
                              fontSize: 26, fontWeight: FontWeight.w900,
                              shadows: locked ? [] : [
                                Shadow(color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 4)],
                            )),
                          const SizedBox(width: 8),
                          if (!locked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${island.totalLevels} niveaux',
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                        ]),
                        const SizedBox(height: 3),

                        // Tagline
                        Text(
                          locked
                            ? '🌟 ${island.starsToUnlock} étoiles requises'
                            : config.tagline,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: locked ? 0.5 : 0.85),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (!locked) ...[
                          // Barre de progression
                          Stack(children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)]),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      blurRadius: 4)],
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 6),

                          // Mini étoiles + compteur
                          Row(children: [
                            Expanded(
                              child: Wrap(spacing: 2, children: List.generate(
                                (island.totalLevels * 3).clamp(0, 12),
                                (s) => Text(
                                  s < island.starsEarned ? '⭐' : '☆',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: s < island.starsEarned
                                        ? Colors.amber
                                        : Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              )),
                            ),
                            Text('${island.starsEarned}/${island.totalLevels * 3}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          ]),
                        ],
                      ],
                    )),

                    // ── Flèche / Cadenas ──
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: locked
                          ? Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.3), size: 22)
                          : Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                    blurRadius: 8)],
                              ),
                              child: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 16),
                            ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Config d'une île ────────────────────────────────────
class _IslandConfig {
  final String label, emoji, tagline;
  final List<Color> colors;
  final int starsToUnlock;
  const _IslandConfig(this.label, this.emoji, this.colors,
      this.tagline, this.starsToUnlock);
}

// ─── Texture décorative sur les cartes ───────────────────
class _IslandTexturePainter extends CustomPainter {
  final bool locked;
  const _IslandTexturePainter({required this.locked});
  @override
  void paint(Canvas canvas, Size size) {
    if (locked) return;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.04);
    // Cercles décoratifs dans les coins
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 60, p);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 40, p);
    // Lignes obliques
    final lp = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Étoiles du fond ─────────────────────────────────────
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    for (int i = 0; i < 80; i++) {
      final r = rng.nextDouble() * 1.6 + 0.3;
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.55;
      final a = 0.2 + rng.nextDouble() * 0.6;
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Colors.white.withValues(alpha: a));
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Vagues de l'océan ───────────────────────────────────
class _OceanPainter extends CustomPainter {
  final double progress;
  const _OceanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    void wave(double yBase, double amp, double freq, double phase, Color color) {
      final p = Paint()..color = color..style = PaintingStyle.fill;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final y = yBase + amp * math.sin((x / size.width * freq + phase) * 2 * math.pi);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, p);
    }

    wave(size.height * 0.5,  12, 2.0, progress,        Colors.blue.shade900.withValues(alpha: 0.4));
    wave(size.height * 0.6,  10, 2.5, progress + 0.15, Colors.blue.shade800.withValues(alpha: 0.5));
    wave(size.height * 0.72,  8, 3.0, progress + 0.3,  const Color(0xFF1565C0).withValues(alpha: 0.6));
    wave(size.height * 0.82,  6, 3.5, progress + 0.45, const Color(0xFF1E88E5).withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _OceanPainter o) => o.progress != progress;
}