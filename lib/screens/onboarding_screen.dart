// lib/screens/world_map_screen.dart
// 🎮 REDESIGN TOTAL — Carte du monde style jeu premium
// Fond peint avec ciel + montagnes + étoiles · Cartes îles 3D avec slab button
// Vrai look Candy Crush / Duolingo

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'island_levels_screen.dart';
import 'teacher/teacher_login_screen.dart';

// ─── Palette de l'île ────────────────────────────────────
class _IslDef {
  final String label, emoji, name, subtitle;
  final Color top, mid, bot, slab;
  final int need;
  const _IslDef(this.label, this.emoji, this.name, this.subtitle,
      this.top, this.mid, this.bot, this.slab, this.need);
}

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});
  @override State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bgCtrl;
  late final AnimationController _bobCtrl;
  late final AnimationController _glowCtrl;

  static const _defs = [
    _IslDef('CP',  '🌸', 'ÎLE DU PRINTEMPS',  'Alphabet · Couleurs · Animaux',
        Color(0xFFFFF9C4), Color(0xFFFFCA28), Color(0xFFFF8F00), Color(0xFFE65100), 0),
    _IslDef('CE1', '🌿', 'ÎLE DE LA FORÊT',    'Famille · Météo · Jours',
        Color(0xFFCCFF90), Color(0xFF76FF03), Color(0xFF2E7D32), Color(0xFF1B5E20), 10),
    _IslDef('CE2', '🔥', 'ÎLE DU VOLCAN',      'École · Maison · Verbes',
        Color(0xFFFFCCBC), Color(0xFFFF6D00), Color(0xFFD84315), Color(0xFF7F0000), 25),
    _IslDef('CM1', '💜', 'ÎLE MAGIQUE',        'Émotions · Métiers · Temps',
        Color(0xFFE1BEE7), Color(0xFFCE93D8), Color(0xFF6A1B9A), Color(0xFF38006B), 45),
    _IslDef('CM2', '🚀', 'ÎLE DES ÉTOILES',   'Passé · Futur · Expressions',
        Color(0xFFB3E5FC), Color(0xFF29B6F6), Color(0xFF0D47A1), Color(0xFF002171), 72),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _bobCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _bobCtrl.dispose(); _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        final islands = ProgressService().buildIslands();
        final student = ProgressService().student;
        return Scaffold(
          body: Stack(children: [
            _Bg(ctrl: _bgCtrl),
            SafeArea(child: Column(children: [
              _TopBar(student: student),
              const SizedBox(height: 8),
              _Title(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _bobCtrl,
                  builder: (_, __) => ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: _defs.length,
                    itemBuilder: (_, i) {
                      final def = _defs[i];
                      final isl = islands[i];
                      final bob = isl.isUnlocked
                          ? math.sin(_bobCtrl.value * math.pi) * 5 * (i % 2 == 0 ? 1 : -1)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Transform.translate(
                          offset: Offset(0, bob),
                          child: _IslandCard(
                            def: def, island: isl,
                            glowAnim: _glowCtrl,
                            onTap: () => _tap(context, isl, def),
                          ),
                        ),
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

  void _tap(BuildContext ctx, Island isl, _IslDef def) {
    if (!isl.isUnlocked) {
      HapticFeedback.vibrate();
      _showLockSnack(ctx, isl, def);
      return;
    }
    HapticFeedback.mediumImpact();
    TtsService().speak('${def.name} !');
    Navigator.push(ctx, _slide(() => IslandLevelsScreen(niveauLabel: isl.label)));
  }

  void _showLockSnack(BuildContext ctx, Island isl, _IslDef def) {
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🔒', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Il te faut ${isl.starsToUnlock} ⭐ pour débloquer ${def.name} !',
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
      ]),
      backgroundColor: const Color(0xFF1A0A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  static PageRouteBuilder _slide(Widget Function() builder) => PageRouteBuilder(
    pageBuilder: (_, a, __) => builder(),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
      child: FadeTransition(opacity: a, child: child),
    ),
    transitionDuration: const Duration(milliseconds: 450),
  );
}

// ─── Fond peint ───────────────────────────────────────────
class _Bg extends StatelessWidget {
  final AnimationController ctrl;
  const _Bg({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _BgPainter(t: ctrl.value),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  const _BgPainter({required this.t});
  @override
  void paint(Canvas canvas, Size s) {
    // ── Ciel dégradé violet-nuit ──
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()..shader = LinearGradient(colors: const [
        Color(0xFF10002B), Color(0xFF240046), Color(0xFF3C096C),
        Color(0xFF5A0080), Color(0xFF7B2FBE),
      ], stops: const [0, 0.25, 0.5, 0.75, 1],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // ── Étoiles ──
    final rng = math.Random(42);
    final sp = Paint()..color = Colors.white;
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * s.width;
      final y = rng.nextDouble() * s.height * 0.6;
      final r = rng.nextDouble() * 1.5 + 0.3;
      final a = 0.3 + 0.7 * math.sin(t * math.pi * 2 + i * 0.5 + 0.1).abs();
      canvas.drawCircle(Offset(x, y), r, sp..color = Colors.white.withValues(alpha: a));
    }

    // ── Montagnes arrière-plan ──
    _mtn(canvas, s, 0.65, const Color(0xFF3C096C));
    _mtn(canvas, s, 0.75, const Color(0xFF5A0080));
    _mtn(canvas, s, 0.82, const Color(0xFF7B2FBE));
  }

  void _mtn(Canvas c, Size s, double base, Color col) {
    final p = Path();
    p.moveTo(0, s.height);
    final rng = math.Random(col.value);
    double x = 0;
    while (x <= s.width + 60) {
      final h = s.height * base - rng.nextDouble() * 80;
      p.lineTo(x, h);
      x += 40 + rng.nextDouble() * 60;
    }
    p.lineTo(s.width, s.height);
    p.close();
    c.drawPath(p, Paint()..color = col);
  }

  @override
  bool shouldRepaint(covariant _BgPainter o) => o.t != t;
}

// ─── Barre du haut ────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final Student? student;
  const _TopBar({this.student});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        // Avatar + nom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(student?.avatarEmoji ?? '🦁', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student?.name ?? 'Héros',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 14)),
              if ((student?.currentStreak ?? 0) > 0)
                Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 11)),
                  Text(' ${student!.currentStreak} jour${student!.currentStreak > 1 ? "s" : ""}',
                    style: TextStyle(color: Colors.orange.shade200,
                        fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
            ]),
          ]),
        ),
        const Spacer(),
        // Étoiles
        _GoldChip('⭐ ${student?.totalStars ?? 0}'),
        const SizedBox(width: 8),
        // Enseignant
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TeacherLoginScreen())),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 20))),
          ),
        ),
      ]),
    );
  }
}

class _GoldChip extends StatelessWidget {
  final String text;
  const _GoldChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFD600), Color(0xFFFF8F00)]),
      borderRadius: BorderRadius.circular(20),
      border: const Border(bottom: BorderSide(color: Color(0xFFE65100), width: 3)),
      boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Text(text, style: const TextStyle(color: Colors.white,
        fontWeight: FontWeight.w900, fontSize: 15)),
  );
}

// ─── Titre décoratif ──────────────────────────────────────
class _Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(children: [
      ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFFFFD600), Color(0xFFFF6D00), Color(0xFFFF4081)],
        ).createShader(r),
        child: const Text('✦ CARTE DU MONDE ✦',
          style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w900, letterSpacing: 2,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6,
                  offset: Offset(0, 2))])),
      ),
      const SizedBox(height: 3),
      Text('Choisis ton île pour commencer !',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
    ]),
  );
}

// ─── Carte d'une île ──────────────────────────────────────
class _IslandCard extends StatelessWidget {
  final _IslDef def;
  final Island island;
  final AnimationController glowAnim;
  final VoidCallback onTap;
  const _IslandCard({required this.def, required this.island,
      required this.glowAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = !island.isUnlocked;
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Bannière titre ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: locked ? const Color(0xFF37474F) : def.mid,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: const Border(bottom: BorderSide(color: Colors.black26, width: 1)),
          ),
          child: Row(children: [
            Text(locked ? '🔒' : def.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Text(locked ? 'VERROUILLÉ' : def.name,
              style: TextStyle(
                color: locked ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w900, fontSize: 13,
                letterSpacing: 1.5,
                shadows: locked ? [] : const [Shadow(blurRadius: 4, color: Colors.black38)],
              ))),
            if (!locked)
              Text('${island.starsEarned}/${island.totalLevels * 3} ⭐',
                style: const TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),

        // ── Corps de la carte ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: locked
                  ? [const Color(0xFF263238), const Color(0xFF37474F)]
                  : [def.top, def.mid],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: locked ? [
              const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 6)),
            ] : [
              BoxShadow(color: def.mid.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
              const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 10)),
            ],
          ),
          child: Row(children: [
            // ── Paysage illustré ──
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: locked
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: locked ? Colors.white12 : Colors.white.withValues(alpha: 0.5),
                    width: 1.5),
              ),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(locked ? '🔒' : def.emoji, style: const TextStyle(fontSize: 32)),
                if (locked)
                  Text('${island.starsToUnlock} ⭐',
                    style: const TextStyle(color: Colors.white38, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ])),
            ),
            const SizedBox(width: 16),

            // ── Info + bouton ──
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(def.subtitle,
                style: TextStyle(
                  color: locked ? Colors.white24 : Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                )),
              const SizedBox(height: 8),
              if (!locked) ...[
                // Barre progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: island.completionRate,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
                const SizedBox(height: 10),
                _SlabButton(
                  label: island.starsEarned > 0 ? '▶ CONTINUER' : '▶ COMMENCER',
                  faceColor: def.mid,
                  slabColor: def.slab,
                  onTap: onTap,
                ),
              ] else ...[
                Row(children: [
                  const Text('🔒', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('${island.starsToUnlock} étoiles requises',
                    style: const TextStyle(color: Colors.white38,
                        fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ],
            ])),
          ]),
        ),

        // ── Socle 3D ──
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: locked ? const Color(0xFF263238) : def.slab,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
        ),
      ]),
    );
  }
}

// ─── Bouton slab 3D ───────────────────────────────────────
class _SlabButton extends StatefulWidget {
  final String label;
  final Color faceColor, slabColor;
  final VoidCallback onTap;
  const _SlabButton({required this.label, required this.faceColor,
      required this.slabColor, required this.onTap});
  @override
  State<_SlabButton> createState() => _SlabButtonState();
}

class _SlabButtonState extends State<_SlabButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      height: 38,
      margin: EdgeInsets.only(top: _pressed ? 3 : 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(Colors.white, widget.faceColor, 0.5)!,
            widget.faceColor,
          ],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: _pressed ? null : Border(
          bottom: BorderSide(color: widget.slabColor, width: 4),
        ),
        boxShadow: _pressed ? [] : [
          BoxShadow(color: widget.slabColor.withValues(alpha: 0.6),
              blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Center(child: Text(widget.label,
        style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w900, letterSpacing: 1.5,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)]))),
    ),
  );
}