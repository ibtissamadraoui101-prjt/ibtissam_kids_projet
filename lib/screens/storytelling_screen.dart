// ============================================================
// lib/screens/storytelling_screen.dart
//
// 🎬  ÉCRAN STORYTELLING — LinguaKids Maroc
// ============================================================
// CE FICHIER FAIT QUOI :
//   8 scènes animées d'introduction — 100% visuel, zéro texte français.
//   Raconte l'histoire : Bouzid vole les lettres → Zaki les récupère.
//   Appelé depuis OnboardingScreen après que l'enfant a entré son prénom.
//
// L'HISTOIRE (sans lire) :
//   0 — Logo + Zaki sur planète étoilée
//   1 — Le monde était beau, coloré, heureux
//   2 — Bouzid le sorcier marocain arrive (éclairs, yeux jaunes)
//   3 — Les lettres s'envolent dans un vortex violet
//   4 — Zaki est choqué, triste (larmes douces)
//   5 — Zaki décide de sauver les îles (yeux de feu)
//   6 — Première île restaurée (confettis, étoiles)
//   7 — Bouton Jouer → WorldMapScreen
//
// NAVIGATION :
//   • Tap n'importe où → scène suivante
//   • Bouton ⏭ → sauter à la scène 7
//   • Auto-advance selon durée de chaque scène
//   • Fin → Navigator.pushReplacement → WorldMapScreen
//
// APPELÉ DEPUIS :
//   • onboarding_screen.dart → après createStudent()
//
// DÉPENDANCES (toutes présentes dans le projet) :
//   • mascot_widget.dart   (lib/widgets/)
//   • mascot_model.dart    (lib/models/)
//   • island_model.dart    (lib/models/) — pour StoryScene
//   • tts_service.dart     (lib/services/)
//   • world_map_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/mascot_model.dart';
import '../models/island_model.dart';
import '../widgets/mascot_widget.dart';
import '../services/tts_service.dart';
import 'world_map_screen.dart';

class StorytellingScreen extends StatefulWidget {
  const StorytellingScreen({super.key});

  @override
  State<StorytellingScreen> createState() => _StorytellingScreenState();
}

class _StorytellingScreenState extends State<StorytellingScreen>
    with TickerProviderStateMixin {

  int _scene = 0;
  static const int _total = 8;

  late AnimationController _fadeCtrl;
  late AnimationController _sceneCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _sceneCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fade      = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _fadeCtrl.forward();
    _scheduleAuto();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _sceneCtrl.dispose();
    super.dispose();
  }

  void _scheduleAuto() {
    final ms = StoryScene.values[_scene.clamp(0, StoryScene.values.length - 1)].autoAdvanceMs;
    if (ms <= 0) return;
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted && _scene < _total - 1) _goTo(_scene + 1);
    });
  }

  Future<void> _goTo(int n) async {
    if (n >= _total) { _finish(); return; }
    HapticFeedback.lightImpact();
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() => _scene = n);
    _sceneCtrl.reset();
    _sceneCtrl.forward();
    await _fadeCtrl.forward();
    _scheduleAuto();
  }

  void _finish() {
    // TTS "C'est parti !" via le TtsService existant
    TtsService().speak('C\'est parti !');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WorldMapScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = StoryScene.values[_scene.clamp(0, StoryScene.values.length - 1)].gradientColors;

    return Scaffold(
      body: GestureDetector(
        onTap: () => _scene < _total - 1 ? _goTo(_scene + 1) : _finish(),
        child: FadeTransition(
          opacity: _fade,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildScene(_scene),
                  // Dots navigation
                  Positioned(
                    bottom: 16, left: 0, right: 0,
                    child: _NavDots(current: _scene, total: _total),
                  ),
                  // Bouton passer
                  if (_scene < _total - 1)
                    Positioned(
                      top: 12, right: 14,
                      child: _SkipBtn(onTap: () => _goTo(_total - 1)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScene(int s) {
    switch (s) {
      case 0: return const _S0Title();
      case 1: return const _S1Beautiful();
      case 2: return const _S2Bouzid();
      case 3: return const _S3Letters();
      case 4: return const _S4Sad();
      case 5: return const _S5Determined();
      case 6: return const _S6Restored();
      case 7: return _S7Go(onPlay: _finish);
      default: return const SizedBox();
    }
  }
}

// ════════════════════════════════════════════════════════════
// SCÈNES
// ════════════════════════════════════════════════════════════

// ── 0 : Titre ─────────────────────────────────────────────
class _S0Title extends StatelessWidget {
  const _S0Title();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const _StarField(),
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Planète avec Zaki dessus
          Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF311B92)],
                center: Alignment(-0.3, -0.3),
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.55), blurRadius: 40, spreadRadius: 8),
              ],
            ),
            child: const Center(
              child: MascotWidget(mood: ZakiMood.waving, size: 110, showBubble: false),
            ),
          ),
          const SizedBox(height: 22),
          // Nom de l'app — dégradé or
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF9800)],
            ).createShader(b),
            child: const Text('LinguaKids',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 36),
          // Points clignotants "tap pour continuer"
          const _TapDots(),
        ]),
      ),
    ]);
  }
}

// ── 1 : Monde beau ────────────────────────────────────────
class _S1Beautiful extends StatelessWidget {
  const _S1Beautiful();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Soleil
      const Positioned(top: 24, left: 0, right: 0, child: Center(child: _AnimSun())),
      // Notes musicales flottantes
      const Positioned(top: 105, left: 28,  child: _FloatNote('♪', 0)),
      const Positioned(top: 145, left: 75,  child: _FloatNote('♫', 300)),
      const Positioned(top: 112, right: 36, child: _FloatNote('♩', 600)),
      const Positioned(top: 150, right: 68, child: _FloatNote('🎵', 900)),
      // Îles colorées (dessinées)
      Positioned(
        bottom: 55, left: 0, right: 0,
        child: SizedBox(height: 200, child: CustomPaint(painter: _IslandsPainter())),
      ),
      // Zaki heureux
      const Center(child: MascotWidget(mood: ZakiMood.storyHappy, size: 120)),
    ]);
  }
}

// ── 2 : Bouzid ────────────────────────────────────────────
class _S2Bouzid extends StatelessWidget {
  const _S2Bouzid();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const _StormClouds(),
      const Positioned(top: 78, left: 36,  child: _Lightning()),
      const Positioned(top: 98, right: 46, child: _Lightning(delay: 350)),
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _BouzidWidget(),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _MagicSpark(color: const Color(0xFFCE93D8), delay: 0),
            const SizedBox(width: 14),
            _MagicSpark(color: const Color(0xFFE040FB), delay: 180),
            const SizedBox(width: 14),
            _MagicSpark(color: const Color(0xFF9C27B0), delay: 360),
          ]),
        ]),
      ),
    ]);
  }
}

// ── 3 : Lettres volées ────────────────────────────────────
class _S3Letters extends StatelessWidget {
  const _S3Letters();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _Vortex(),
        SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _GreyIsland(), SizedBox(width: 10),
          _GreyIsland(), SizedBox(width: 10),
          _GreyIsland(), SizedBox(width: 10),
          _GreyIsland(),
        ]),
      ])),
      const Positioned(left: 28,  top: 110, child: _FlyLetter('A', 0)),
      const Positioned(right: 28, top: 80,  child: _FlyLetter('B', 200)),
      const Positioned(left: 58,  top: 195, child: _FlyLetter('🔊', 400)),
      const Positioned(right: 46, top: 175, child: _FlyLetter('C', 600)),
      const Positioned(left: 118, top: 58,  child: _FlyLetter('M', 100)),
    ]);
  }
}

// ── 4 : Zaki triste ───────────────────────────────────────
class _S4Sad extends StatelessWidget {
  const _S4Sad();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.18,
          right: MediaQuery.of(context).size.width * 0.08,
          child: _ThoughtBubble(child: const Text('🏝️💀', style: TextStyle(fontSize: 28))),
        ),
        const MascotWidget(mood: ZakiMood.storySad, size: 150, showBubble: false),
      ]),
    );
  }
}

// ── 5 : Zaki décidé ───────────────────────────────────────
class _S5Determined extends StatelessWidget {
  const _S5Determined();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Halo doré
      Center(
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFFFFD700).withOpacity(0.38), Colors.transparent,
            ]),
          ),
        ),
      ),
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const MascotWidget(mood: ZakiMood.storyHero, size: 160),
          const SizedBox(height: 18),
          // Flèche île morte → île vivante
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🏝️', style: TextStyle(fontSize: 32, color: Colors.grey.shade400)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFD700), size: 30),
            ),
            const Text('🏝️', style: TextStyle(fontSize: 32)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFD700), size: 30),
            ),
            const Text('👑', style: TextStyle(fontSize: 32)),
          ]),
        ]),
      ),
    ]);
  }
}

// ── 6 : Île restaurée ─────────────────────────────────────
class _S6Restored extends StatelessWidget {
  const _S6Restored();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Center(child: _SunBurst()),
      // Confettis
      ...List.generate(6, (i) => Positioned(
        left: (i * 58.0 + 10) % (MediaQuery.of(context).size.width - 30),
        top: -30,
        child: _Confetti(
          emoji: ['🌟','⭐','✨','🎉','🎊','🌈'][i],
          delay: i * 180,
        ),
      )),
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 240, height: 180,
            child: CustomPaint(painter: _RestoredIslandPainter()),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => _StarPop(delay: i * 200)),
          ),
        ]),
      ),
    ]);
  }
}

// ── 7 : Go ! ──────────────────────────────────────────────
class _S7Go extends StatelessWidget {
  final VoidCallback onPlay;
  const _S7Go({required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const MascotWidget(mood: ZakiMood.storyVictory, size: 130),
          const SizedBox(height: 14),
          // 5 îles à sauver
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: ['🔊','🔤','🔡','📖','👑']
              .asMap().entries
              .map((e) => _IslandPop(emoji: e.value, delay: e.key * 140))
              .toList(),
          ),
          const SizedBox(height: 28),
          _PlayBtn(onTap: onPlay),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS COMMUNS DES SCÈNES
// ════════════════════════════════════════════════════════════

// ── Points navigation ─────────────────────────────────────
class _NavDots extends StatelessWidget {
  final int current, total;
  const _NavDots({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 22 : 8, height: 8,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Bouton passer ─────────────────────────────────────────
class _SkipBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('⏭ ', style: TextStyle(fontSize: 13)),
        Text('Passer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    ),
  );
}

// ── Champ d'étoiles ───────────────────────────────────────
class _StarField extends StatefulWidget {
  const _StarField();
  @override
  State<_StarField> createState() => _StarFieldState();
}
class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final _stars = List.generate(65, (i) => _S(
    x: math.Random().nextDouble(), y: math.Random().nextDouble(),
    sz: math.Random().nextDouble() * 2.8 + 1,
    ph: math.Random().nextDouble() * math.pi * 2,
    sp: 1.4 + math.Random().nextDouble() * 2.4,
  ));
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => CustomPaint(size: MediaQuery.of(context).size, painter: _SFP(_stars, _c.value)),
  );
}
class _S { final double x,y,sz,ph,sp; _S({required this.x,required this.y,required this.sz,required this.ph,required this.sp}); }
class _SFP extends CustomPainter {
  final List<_S> s; final double t;
  _SFP(this.s, this.t);
  @override void paint(Canvas c, Size sz) {
    for (final st in s) {
      final op = 0.15 + 0.85 * (0.5 + 0.5 * math.sin(t * st.sp * math.pi * 2 + st.ph));
      c.drawCircle(Offset(st.x * sz.width, st.y * sz.height), st.sz, Paint()..color = Colors.white.withOpacity(op));
    }
  }
  @override bool shouldRepaint(_SFP o) => o.t != t;
}

// ── Points clignotants ────────────────────────────────────
class _TapDots extends StatefulWidget {
  const _TapDots();
  @override
  State<_TapDots> createState() => _TapDotsState();
}
class _TapDotsState extends State<_TapDots> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _c,
    child: Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 10, height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.5)),
      )),
    ),
  );
}

// ── Soleil animé ──────────────────────────────────────────
class _AnimSun extends StatefulWidget {
  const _AnimSun();
  @override
  State<_AnimSun> createState() => _AnimSunState();
}
class _AnimSunState extends State<_AnimSun> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF176),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.28 + 0.28 * _c.value), blurRadius: 18 + 18 * _c.value, spreadRadius: 4 + 12 * _c.value)],
      ),
    ),
  );
}

// ── Note musicale flottante ───────────────────────────────
class _FloatNote extends StatefulWidget {
  final String note; final int delay;
  const _FloatNote(this.note, this.delay);
  @override
  State<_FloatNote> createState() => _FloatNoteState();
}
class _FloatNoteState extends State<_FloatNote> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _y, _op;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _y  = Tween(begin: 0.0,  end: -115.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _op = Tween(begin: 0.85, end: 0.0).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.repeat(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _y.value),
      child: Opacity(opacity: _op.value.clamp(0.0,1.0), child: Text(widget.note, style: const TextStyle(fontSize: 24, color: Color(0xFFFFD700)))),
    ),
  );
}

// ── Nuages orageux ────────────────────────────────────────
class _StormClouds extends StatefulWidget {
  const _StormClouds();
  @override
  State<_StormClouds> createState() => _StormCloudsState();
}
class _StormCloudsState extends State<_StormClouds> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => CustomPaint(size: Size(MediaQuery.of(context).size.width, 200), painter: _CloudP(_c.value)),
  );
}
class _CloudP extends CustomPainter {
  final double t; _CloudP(this.t);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF2D0030);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s.width*0.3+t*10,60), width:200,height:60), const Radius.circular(40)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s.width*0.7-t*10,40), width:160,height:50), const Radius.circular(35)), p);
  }
  @override bool shouldRepaint(_CloudP o) => o.t != t;
}

// ── Éclair ────────────────────────────────────────────────
class _Lightning extends StatefulWidget {
  final int delay;
  const _Lightning({this.delay = 0});
  @override
  State<_Lightning> createState() => _LightningState();
}
class _LightningState extends State<_Lightning> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.repeat(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Opacity(opacity: _c.value > 0.5 ? 1.0 : 0.0, child: const Text('⚡', style: TextStyle(fontSize: 38))),
  );
}

// ── Bouzid ────────────────────────────────────────────────
class _BouzidWidget extends StatefulWidget {
  const _BouzidWidget();
  @override
  State<_BouzidWidget> createState() => _BouzidWidgetState();
}
class _BouzidWidgetState extends State<_BouzidWidget> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, -12 * _c.value),
      child: CustomPaint(size: const Size(220, 280), painter: _BouzidP()),
    ),
  );
}
class _BouzidP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final dark = Paint()..color = const Color(0xFF2D0050);
    // Robe
    final robe = Path()
      ..moveTo(cx-60,140)..quadraticBezierTo(cx-80,260,cx,275)
      ..quadraticBezierTo(cx+80,260,cx+60,140)..close();
    canvas.drawPath(robe, dark);
    // Corps
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,165),width:70,height:90), const Radius.circular(20)), dark);
    // Étoile
    final star = Path();
    for (int i=0;i<5;i++){
      final oa=(i*72-90)*math.pi/180; final ia=oa+36*math.pi/180;
      final ox=cx+22*math.cos(oa); final oy=155+22*math.sin(oa);
      final ix=cx+9*math.cos(ia);  final iy=155+9*math.sin(ia);
      if(i==0) star.moveTo(ox,oy); else star.lineTo(ox,oy);
      star.lineTo(ix,iy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.8));
    // Chapeau brim
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,72),width:130,height:24), Paint()..color = const Color(0xFF1A0030));
    // Chapeau haut
    final hat = Path()..moveTo(cx-55,72)..quadraticBezierTo(cx-40,10,cx,8)..quadraticBezierTo(cx+40,10,cx+55,72)..close();
    canvas.drawPath(hat, Paint()..color = const Color(0xFF1A0030));
    // Tête
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,115),width:90,height:96), Paint()..color = const Color(0xFF3D0060));
    // Yeux jaunes
    canvas.drawOval(Rect.fromCenter(center:Offset(cx-22,106),width:26,height:22), Paint()..color = const Color(0xFFFFFF00));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx+22,106),width:26,height:22), Paint()..color = const Color(0xFFFFFF00));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx-22,107),width:9,height:18),  Paint()..color = Colors.black);
    canvas.drawOval(Rect.fromCenter(center:Offset(cx+22,107),width:9,height:18),  Paint()..color = Colors.black);
    // Sourcils méchants
    final brow = Paint()..color=const Color(0xFF9C27B0)..strokeWidth=5..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    canvas.drawLine(Offset(cx-34,93),Offset(cx-10,100),brow);
    canvas.drawLine(Offset(cx+34,93),Offset(cx+10,100),brow);
    // Sourire dents
    final smile = Paint()..color=const Color(0xFFCE93D8)..strokeWidth=3.5..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final sp = Path()..moveTo(cx-28,128)..quadraticBezierTo(cx,145,cx+28,128);
    canvas.drawPath(sp, smile);
    final tooth = Paint()..color = Colors.white;
    for (int i=0;i<3;i++) canvas.drawRect(Rect.fromLTWH(cx-20+i*14.0,128,11,10), tooth);
    // Mains + étincelles
    canvas.drawCircle(Offset(cx-82,185),18, dark);
    canvas.drawCircle(Offset(cx+82,185),18, dark);
    canvas.drawCircle(Offset(cx-98,170),6,  Paint()..color=const Color(0xFFE040FB));
    canvas.drawCircle(Offset(cx+98,170),6,  Paint()..color=const Color(0xFFE040FB));
    canvas.drawCircle(Offset(cx-104,188),4, Paint()..color=const Color(0xFFCE93D8));
    canvas.drawCircle(Offset(cx+104,188),4, Paint()..color=const Color(0xFFCE93D8));
  }
  @override bool shouldRepaint(_BouzidP _) => false;
}

// ── Étincelle magique ─────────────────────────────────────
class _MagicSpark extends StatefulWidget {
  final Color color; final int delay;
  const _MagicSpark({required this.color, required this.delay});
  @override
  State<_MagicSpark> createState() => _MagicSparkState();
}
class _MagicSparkState extends State<_MagicSpark> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.scale(
      scale: 0.5 + 0.8 * _c.value,
      child: Container(width:20,height:20,decoration:BoxDecoration(shape:BoxShape.circle,color:widget.color)),
    ),
  );
}

// ── Vortex ────────────────────────────────────────────────
class _Vortex extends StatefulWidget {
  const _Vortex();
  @override
  State<_Vortex> createState() => _VortexState();
}
class _VortexState extends State<_Vortex> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.rotate(
      angle: _c.value * 2 * math.pi,
      child: Container(
        width:110,height:110,
        decoration: BoxDecoration(
          shape:BoxShape.circle,
          border:Border.all(color:const Color(0xFF9C27B0).withOpacity(0.6),width:6),
          boxShadow:[BoxShadow(color:const Color(0xFF9C27B0).withOpacity(0.28),blurRadius:20,spreadRadius:5)],
        ),
        child:Container(
          margin:const EdgeInsets.all(13),
          decoration:BoxDecoration(
            shape:BoxShape.circle,
            border:Border.all(color:const Color(0xFFCE93D8).withOpacity(0.5),width:4),
          ),
          child:Container(margin:const EdgeInsets.all(11),decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0x806A1B9A))),
        ),
      ),
    ),
  );
}

// ── Lettre volée ──────────────────────────────────────────
class _FlyLetter extends StatefulWidget {
  final String letter; final int delay;
  const _FlyLetter(this.letter, this.delay);
  @override
  State<_FlyLetter> createState() => _FlyLetterState();
}
class _FlyLetterState extends State<_FlyLetter> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<Offset> _pos;
  late Animation<double> _op;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    _pos = Tween<Offset>(begin: Offset.zero, end: const Offset(0.4, -3)).animate(CurvedAnimation(parent:_c,curve:Curves.easeIn));
    _op  = Tween(begin: 1.0, end: 0.0).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.repeat(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SlideTransition(
    position: _pos,
    child: FadeTransition(opacity: _op, child: Text(widget.letter, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white))),
  );
}

// ── Île grise ─────────────────────────────────────────────
class _GreyIsland extends StatelessWidget {
  const _GreyIsland();
  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
    child: const Opacity(opacity: 0.42, child: Text('🏝️', style: TextStyle(fontSize: 38))),
  );
}

// ── Bulle de pensée ───────────────────────────────────────
class _ThoughtBubble extends StatefulWidget {
  final Widget child;
  const _ThoughtBubble({required this.child});
  @override
  State<_ThoughtBubble> createState() => _ThoughtBubbleState();
}
class _ThoughtBubbleState extends State<_ThoughtBubble> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
    child: Container(
      width: 76, height: 76,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,3))]),
      child: Center(child: widget.child),
    ),
  );
}

// ── Rayons (victoire) ─────────────────────────────────────
class _SunBurst extends StatefulWidget {
  const _SunBurst();
  @override
  State<_SunBurst> createState() => _SunBurstState();
}
class _SunBurstState extends State<_SunBurst> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.rotate(angle: _c.value * 2 * math.pi, child: CustomPaint(size: const Size(250, 250), painter: _RayP())),
  );
}
class _RayP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width/2; final cy = s.height/2;
    final p = Paint()..color=const Color(0xFFFFD700).withOpacity(0.28)..strokeWidth=4..strokeCap=StrokeCap.round;
    for (int i=0;i<8;i++) {
      final a = i * math.pi / 4;
      c.drawLine(Offset(cx+38*math.cos(a),cy+38*math.sin(a)), Offset(cx+108*math.cos(a),cy+108*math.sin(a)), p);
    }
  }
  @override bool shouldRepaint(_RayP _) => false;
}

// ── Confetti ──────────────────────────────────────────────
class _Confetti extends StatefulWidget {
  final String emoji; final int delay;
  const _Confetti({required this.emoji, required this.delay});
  @override
  State<_Confetti> createState() => _ConfettiState();
}
class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _y, _rot;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
    _y   = Tween(begin:0.0, end:880.0).animate(_c);
    _rot = Tween(begin:0.0, end:4*math.pi).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.repeat(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _y.value),
      child: Transform.rotate(angle: _rot.value, child: Text(widget.emoji, style: const TextStyle(fontSize: 21))),
    ),
  );
}

// ── Étoile qui pop ────────────────────────────────────────
class _StarPop extends StatefulWidget {
  final int delay;
  const _StarPop({required this.delay});
  @override
  State<_StarPop> createState() => _StarPopState();
}
class _StarPopState extends State<_StarPop> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text('⭐', style: TextStyle(fontSize: 40))),
  );
}

// ── Île qui pop (scène 7) ─────────────────────────────────
class _IslandPop extends StatefulWidget {
  final String emoji; final int delay;
  const _IslandPop({required this.emoji, required this.delay});
  @override
  State<_IslandPop> createState() => _IslandPopState();
}
class _IslandPopState extends State<_IslandPop> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(widget.emoji, style: const TextStyle(fontSize: 33))),
  );
}

// ── Bouton Jouer ──────────────────────────────────────────
class _PlayBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayBtn({required this.onTap});
  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}
class _PlayBtnState extends State<_PlayBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.scale(
      scale: 1.0 + 0.04 * _c.value,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 12, offset: const Offset(0,6))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🚀', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Jouer !', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFFFF6F00))),
          ]),
        ),
      ),
    ),
  );
}

// ─── Painters ────────────────────────────────────────────
class _IslandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mer
    canvas.drawRect(Rect.fromLTWH(0, size.height*0.58, size.width, size.height*0.42), Paint()..color = const Color(0x551976D2));
    _isle(canvas, size.width*0.22, size.height*0.53, 68, const Color(0xFF66BB6A), const Color(0xFF81C784));
    _isle(canvas, size.width*0.65, size.height*0.48, 78, const Color(0xFF42A5F5), const Color(0xFF64B5F6));
    // Arc-en-ciel
    for (int i=0; i<5; i++) {
      canvas.drawArc(
        Rect.fromCenter(center:Offset(size.width/2, size.height*0.78), width:size.width*1.38-i*18.0, height:size.height*0.78-i*14.0),
        math.pi, math.pi, false,
        Paint()..color=[const Color(0x80FF5252),const Color(0x80FF9800),const Color(0x80FFD740),const Color(0x8069F0AE),const Color(0x8040C4FF)][i]..strokeWidth=5..style=PaintingStyle.stroke,
      );
    }
  }
  void _isle(Canvas c, double cx, double cy, double r, Color top, Color mid) {
    c.drawOval(Rect.fromCenter(center:Offset(cx,cy+r*0.48), width:r*1.98, height:r*0.48), Paint()..color=const Color(0xFF5D4037));
    c.drawOval(Rect.fromCenter(center:Offset(cx,cy),         width:r*1.78, height:r*1.08), Paint()..color=top);
    c.drawOval(Rect.fromCenter(center:Offset(cx,cy-r*0.1),   width:r*1.48, height:r*0.84), Paint()..color=mid);
  }
  @override bool shouldRepaint(_IslandsPainter _) => false;
}

class _RestoredIslandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width/2; final cy = size.height*0.6;
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,cy+19), width:186,height:19), Paint()..color=Colors.black.withOpacity(0.18));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,cy),    width:186,height:44), Paint()..color=const Color(0xFF5D4037));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,cy-29), width:166,height:72), Paint()..color=const Color(0xFF66BB6A));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,cy-39), width:148,height:63), Paint()..color=const Color(0xFF81C784));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx,cy-8),  width:168,height:27), Paint()..color=const Color(0xFFFFD54F).withOpacity(0.46));
    // Palmier
    canvas.drawLine(Offset(cx-29,cy-29), Offset(cx-33,cy-88), Paint()..color=const Color(0xFF4E342E)..strokeWidth=6..strokeCap=StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center:Offset(cx-44,cy-95), width:40,height:20), Paint()..color=const Color(0xFF2E7D32));
    canvas.drawOval(Rect.fromCenter(center:Offset(cx-30,cy-101),width:36,height:18), Paint()..color=const Color(0xFF388E3C));
    // Notes
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final n in [('♪',Offset(cx+8,cy-79)),('♫',Offset(cx+38,cy-94))]) {
      tp.text = TextSpan(text:n.$1, style:const TextStyle(fontSize:22,color:Color(0xFFFFD700)));
      tp.layout(); tp.paint(canvas, n.$2);
    }
  }
  @override bool shouldRepaint(_RestoredIslandPainter _) => false;
}