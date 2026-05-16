// lib/screens/onboarding_screen.dart
// ═══════════════════════════════════════════════════════════
// 🌴 ÉCRAN D'ACCUEIL — LinguaKids Maroc
// CORRIGÉ :
//   • const StorytellingScreen() → StorytellingScreen() (pas const)
//   • Même chose pour WorldMapScreen()
//   • ProgressService().student (pas .currentStudent)
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'world_map_screen.dart';
import 'storytelling_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final TextEditingController _nameCtrl = TextEditingController();
  bool _isLoading     = false;
  int  _selectedMascot = 0;

  static const List<_MascotData> _mascottes = [
    _MascotData(emoji: '🦁', name: 'Lion',      color: Color(0xFFFFB300), bg: Color(0xFFFFF3E0)),
    _MascotData(emoji: '🐸', name: 'Grenouille', color: Color(0xFF43A047), bg: Color(0xFFE8F5E9)),
    _MascotData(emoji: '🦊', name: 'Renard',    color: Color(0xFFFF6F00), bg: Color(0xFFFFF3E0)),
    _MascotData(emoji: '🐧', name: 'Pingouin',  color: Color(0xFF1565C0), bg: Color(0xFFE3F2FD)),
    _MascotData(emoji: '🐰', name: 'Lapin',     color: Color(0xFFEC407A), bg: Color(0xFFFCE4EC)),
  ];

  late AnimationController _mascotCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _btnCtrl;
  late Animation<double>   _mascotAnim;
  late Animation<double>   _btnAnim;

  final List<_StarDeco> _starDecos = List.generate(8, (i) => _StarDeco(
    x:     0.05 + (i * 0.13) % 0.90,
    y:     0.02 + (i * 0.07) % 0.25,
    size:  16.0 + (i % 3) * 8,
    phase: i * 0.7,
  ));

  @override
  void initState() {
    super.initState();
    _mascotCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _mascotAnim = Tween(begin: 0.0, end: -14.0).animate(
        CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeInOut));

    _starsCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat();

    _btnCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _btnAnim = Tween(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mascotCtrl.dispose();
    _starsCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  // ── Démarrer l'aventure ─────────────────────────────────
  Future<void> _start() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      HapticFeedback.lightImpact();
      _showNameError();
      return;
    }

    HapticFeedback.mediumImpact();
    TtsService().speak('Bienvenue $name !');
    setState(() => _isLoading = true);

    // Vérifier si c'est le premier lancement AVANT createStudent
    final isFirst = !ProgressService().hasStudent;

    await ProgressService().createStudent(
      name,
      emoji: _mascottes[_selectedMascot].emoji,
    );

    if (!mounted) return;

    // ✅ CORRIGÉ : pas de const devant StorytellingScreen() ni WorldMapScreen()
    // car ce sont des variables (isFirst peut changer) — const interdit ici
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          isFirst ? const StorytellingScreen() : const WorldMapScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 700),
    ));
  }

  void _showNameError() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Text('✏️', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text("Écris ton prénom d'abord !",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
      backgroundColor: const Color(0xFFFF8F00),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // Fond tropical
        const _TropicalBackground(),
        // Étoiles scintillantes
        AnimatedBuilder(
          animation: _starsCtrl,
          builder: (_, __) => Stack(
            children: _starDecos.map((s) {
              final opacity = 0.4 + 0.6 *
                (0.5 + 0.5 * math.sin(_starsCtrl.value * math.pi * 2 + s.phase));
              return Positioned(
                left: s.x * size.width,
                top:  s.y * size.height,
                child: Opacity(opacity: opacity,
                  child: Text('✦', style: TextStyle(
                    fontSize: s.size, color: const Color(0xFFFFD700)))),
              );
            }).toList(),
          ),
        ),
        // Contenu
        SafeArea(
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    const SizedBox(height: 8),
                    _buildHeroMascot(),
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildFeatureBtns(),
                    const SizedBox(height: 18),
                    _buildNameField(),
                    const SizedBox(height: 18),
                    _buildMascotPicker(),
                    const SizedBox(height: 22),
                    _buildStartBtn(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0,3))],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('👨‍👩‍👧', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Parents',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                  color: Color(0xFFE65100))),
          ]),
        ),
        ListenableBuilder(
          listenable: ProgressService(),
          builder: (_, __) {
            final stars = ProgressService().student?.totalStars ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.5),
                  blurRadius: 8, offset: const Offset(0,3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('$stars',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                      color: Color(0xFF7A4F00))),
              ]),
            );
          },
        ),
      ]),
    );
  }

  // ── MASCOTTE PRINCIPALE ──────────────────────────────────
  Widget _buildHeroMascot() {
    final mascot = _mascottes[_selectedMascot];
    return AnimatedBuilder(
      animation: _mascotAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _mascotAnim.value),
        child: SizedBox(height: 160,
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  mascot.color.withOpacity(0.25), Colors.transparent]),
              ),
            ),
            Container(width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [BoxShadow(
                  color: mascot.color.withOpacity(0.3),
                  blurRadius: 20, spreadRadius: 4)],
              ),
              child: Center(child: Text(mascot.emoji,
                  style: const TextStyle(fontSize: 68))),
            ),
            Positioned(top: 10, right: 32,
              child: _SpinStar(color: mascot.color, size: 22, delay: 0)),
            Positioned(top: 18, left: 30,
              child: _SpinStar(color: const Color(0xFFFFD700), size: 18, delay: 300)),
            Positioned(bottom: 20, right: 28,
              child: _SpinStar(color: const Color(0xFFFFD700), size: 16, delay: 600)),
          ]),
        ),
      ),
    );
  }

  // ── TITRE ────────────────────────────────────────────────
  Widget _buildTitle() {
    return Column(children: [
      RichText(text: const TextSpan(
        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        children: [
          TextSpan(text: 'L', style: TextStyle(color: Color(0xFFFF5252))),
          TextSpan(text: 'i', style: TextStyle(color: Color(0xFFFF9800))),
          TextSpan(text: 'n', style: TextStyle(color: Color(0xFFFFD740))),
          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF69F0AE))),
          TextSpan(text: 'u', style: TextStyle(color: Color(0xFF40C4FF))),
          TextSpan(text: 'a', style: TextStyle(color: Color(0xFFE040FB))),
          TextSpan(text: 'K', style: TextStyle(color: Color(0xFFFF5252))),
          TextSpan(text: 'i', style: TextStyle(color: Color(0xFFFF9800))),
          TextSpan(text: 'd', style: TextStyle(color: Color(0xFF69F0AE))),
          TextSpan(text: 's', style: TextStyle(color: Color(0xFF40C4FF))),
        ],
      )),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.4),
            blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Text('Apprends le français en jouant !',
          style: TextStyle(color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w800)),
      ),
    ]);
  }

  // ── BOUTONS FONCTIONNALITÉS ──────────────────────────────
  Widget _buildFeatureBtns() {
    const btns = [
      _FeatBtn(emoji: '🎮', label: '4 Jeux',      color: Color(0xFF9C6FE4)),
      _FeatBtn(emoji: '🏝️', label: '5 Îles',       color: Color(0xFF4CAF50)),
      _FeatBtn(emoji: '🎁', label: 'Récompenses',  color: Color(0xFFFF9800)),
      _FeatBtn(emoji: '🧠', label: 'IA Adaptive',  color: Color(0xFF29B6F6)),
    ];
    return Row(
      children: btns.map((b) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _FeatureButton(data: b),
        ),
      )).toList(),
    );
  }

  // ── CHAMP PRÉNOM ─────────────────────────────────────────
  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.10), blurRadius: 14, offset: const Offset(0,5))],
      ),
      child: Row(children: [
        Container(
          margin: const EdgeInsets.all(8),
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _mascottes[_selectedMascot].bg,
            border: Border.all(color: _mascottes[_selectedMascot].color, width: 2.5),
          ),
          child: Center(child: Text(_mascottes[_selectedMascot].emoji,
              style: const TextStyle(fontSize: 26))),
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 2),
            child: Text('Ton prénom',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFF9E9E9E))),
          ),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: Color(0xFF333333)),
            decoration: const InputDecoration(
              hintText: 'Écris ton prénom ici...',
              hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(bottom: 10, left: 2),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _start(),
          ),
        ])),
        Container(
          margin: const EdgeInsets.all(12),
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7C4DFF).withOpacity(0.12)),
          child: const Center(child: Text('✏️', style: TextStyle(fontSize: 18))),
        ),
      ]),
    );
  }

  // ── CHOIX MASCOTTE ──────────────────────────────────────
  Widget _buildMascotPicker() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌿', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text('Choisis ta mascotte',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 4)])),
        const SizedBox(width: 6),
        const Text('🌿', style: TextStyle(fontSize: 16)),
      ]),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_mascottes.length, (i) {
          final m = _mascottes[i];
          final selected = i == _selectedMascot;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedMascot = i);
              TtsService().speak(m.name);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.elasticOut,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width:  selected ? 70 : 60,
              height: selected ? 70 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: selected ? m.color : Colors.white.withOpacity(0.6),
                  width: selected ? 4 : 2),
                boxShadow: [BoxShadow(
                  color: selected
                    ? m.color.withOpacity(0.5) : Colors.black.withOpacity(0.15),
                  blurRadius: selected ? 16 : 6,
                  spreadRadius: selected ? 2 : 0,
                  offset: const Offset(0, 3))],
              ),
              child: Center(child: Text(m.emoji,
                style: TextStyle(fontSize: selected ? 36 : 30))),
            ),
          );
        }),
      ),
    ]);
  }

  // ── BOUTON DÉMARRER ──────────────────────────────────────
  Widget _buildStartBtn() {
    return AnimatedBuilder(
      animation: _btnAnim,
      builder: (_, __) => Transform.scale(
        scale: _btnAnim.value,
        child: GestureDetector(
          onTap: _isLoading ? null : _start,
          child: Container(
            width: double.infinity, height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(31),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF8F00).withOpacity(0.55),
                    blurRadius: 16, offset: const Offset(0, 7)),
                const BoxShadow(color: Color(0xFFE65100),
                    offset: Offset(0, 5), blurRadius: 0, spreadRadius: -2),
              ],
            ),
            child: Center(
              child: _isLoading
                ? const SizedBox(width: 26, height: 26,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('🚀', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Text("C'est parti !",
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black26,
                            blurRadius: 4, offset: Offset(0, 2))])),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FOND TROPICAL
// ════════════════════════════════════════════════════════════
class _TropicalBackground extends StatelessWidget {
  const _TropicalBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox.expand(
      child: CustomPaint(painter: _TropicalPainter(size)),
    );
  }
}

class _TropicalPainter extends CustomPainter {
  final Size screenSize;
  const _TropicalPainter(this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Ciel
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.65),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFF87CEEB), Color(0xFF56CCF2), Color(0xFF29B6F6)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65)),
    );
    // Mer
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height*0.62, size.width, size.height*0.38)),
    );
    _drawSun(canvas, size.width * 0.82, size.height * 0.09);
    _drawCloud(canvas, size.width * 0.08, size.height * 0.08, 1.0);
    _drawCloud(canvas, size.width * 0.55, size.height * 0.06, 0.75);
    _drawCloud(canvas, size.width * 0.72, size.height * 0.13, 0.6);
    _drawDistantIsland(canvas, size.width * 0.10, size.height * 0.62, size.width * 0.28);
    _drawDistantIsland(canvas, size.width * 0.75, size.height * 0.60, size.width * 0.22);
    // Sol
    final groundPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(size.width*0.25, size.height*0.73, size.width*0.5, size.height*0.76)
      ..quadraticBezierTo(size.width*0.75, size.height*0.79, size.width, size.height*0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPath, Paint()..color = const Color(0xFF388E3C));
    final grassPath = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(size.width*0.25, size.height*0.71, size.width*0.5, size.height*0.74)
      ..quadraticBezierTo(size.width*0.75, size.height*0.77, size.width, size.height*0.72)
      ..lineTo(size.width, size.height*0.74)
      ..quadraticBezierTo(size.width*0.75, size.height*0.79, size.width*0.5, size.height*0.76)
      ..quadraticBezierTo(size.width*0.25, size.height*0.73, 0, size.height*0.78)
      ..close();
    canvas.drawPath(grassPath, Paint()..color = const Color(0xFF66BB6A));
    _drawFlower(canvas, size.width*0.08, size.height*0.84, const Color(0xFFFF80AB));
    _drawFlower(canvas, size.width*0.18, size.height*0.87, const Color(0xFFFFD740));
    _drawFlower(canvas, size.width*0.82, size.height*0.85, const Color(0xFFFF80AB));
    _drawFlower(canvas, size.width*0.90, size.height*0.88, const Color(0xFFFFD740));
    _drawPalm(canvas, size.width*0.04, size.height*0.78, size.height*0.30, true);
    _drawPalm(canvas, size.width*0.96, size.height*0.76, size.height*0.26, false);
    _drawWave(canvas, size, size.height*0.67, 1.0);
    _drawWave(canvas, size, size.height*0.70, 0.6);
  }

  void _drawSun(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 36,
        Paint()..color = const Color(0xFFFFE082).withOpacity(0.35));
    canvas.drawCircle(Offset(cx, cy), 26, Paint()..color = const Color(0xFFFFF176));
    final rp = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.6)
      ..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(Offset(cx + 30*math.cos(a), cy + 30*math.sin(a)),
                      Offset(cx + 44*math.cos(a), cy + 44*math.sin(a)), rp);
    }
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double scale) {
    final p = Paint()..color = Colors.white.withOpacity(0.88);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy),
        width: 90*scale, height: 32*scale), p);
    canvas.drawCircle(Offset(cx-20*scale, cy-10*scale), 22*scale, p);
    canvas.drawCircle(Offset(cx+15*scale, cy-14*scale), 18*scale, p);
    canvas.drawCircle(Offset(cx+35*scale, cy-6*scale),  14*scale, p);
  }

  void _drawDistantIsland(Canvas canvas, double cx, double cy, double w) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy+8), width: w, height: w*0.18),
      Paint()..color = const Color(0xFF0288D1).withOpacity(0.4));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w*0.85, height: w*0.22),
      Paint()..color = const Color(0xFF4CAF50));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy-4), width: w*0.72, height: w*0.17),
      Paint()..color = const Color(0xFF66BB6A));
    canvas.drawLine(Offset(cx, cy-2), Offset(cx-4, cy-w*0.16),
      Paint()..color = const Color(0xFF4E342E)..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx-8, cy-w*0.17), width: w*0.12, height: w*0.06),
      Paint()..color = const Color(0xFF2E7D32));
  }

  void _drawPalm(Canvas canvas, double bx, double by, double h, bool left) {
    final tipX = bx + (left ? h*0.18 : -h*0.18);
    final tipY = by - h;
    final trunkPath = Path()
      ..moveTo(bx-8, by)
      ..quadraticBezierTo(bx+(left?10:-10), by-h*0.5, tipX, tipY)
      ..lineTo(tipX+(left?8:-8), tipY)
      ..quadraticBezierTo(bx+(left?18:-18), by-h*0.5, bx+8, by)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF5D4037));
    final leafColors = [const Color(0xFF2E7D32), const Color(0xFF388E3C), const Color(0xFF43A047)];
    for (int i = 0; i < 3; i++) {
      final angle = (left ? -30 : 210) + i * (left ? 35 : -35);
      final rad = angle * math.pi / 180;
      final lx = tipX + 55 * math.cos(rad);
      final ly = tipY + 55 * math.sin(rad);
      final lp = Path()
        ..moveTo(tipX, tipY)
        ..quadraticBezierTo(tipX+30*math.cos(rad-0.3), tipY+30*math.sin(rad-0.3), lx, ly)
        ..quadraticBezierTo(tipX+30*math.cos(rad+0.3), tipY+30*math.sin(rad+0.3), tipX, tipY)
        ..close();
      canvas.drawPath(lp, Paint()..color = leafColors[i % 3]);
    }
    canvas.drawCircle(Offset(tipX, tipY+12), 7, Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(Offset(tipX+(left?10:-10), tipY+8), 6, Paint()..color = const Color(0xFF6D4C41));
  }

  void _drawFlower(Canvas canvas, double cx, double cy, Color color) {
    final p = Paint()..color = color;
    for (int i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      canvas.drawCircle(Offset(cx+7*math.cos(a), cy+7*math.sin(a)), 5, p);
    }
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = const Color(0xFFFFD740));
  }

  void _drawWave(Canvas canvas, Size size, double y, double opacity) {
    final path = Path()
      ..moveTo(0, y)
      ..quadraticBezierTo(size.width*0.15, y-6,  size.width*0.30, y)
      ..quadraticBezierTo(size.width*0.45, y+6,  size.width*0.60, y)
      ..quadraticBezierTo(size.width*0.75, y-6,  size.width*0.90, y)
      ..quadraticBezierTo(size.width*0.95, y+3,  size.width,      y)
      ..lineTo(size.width, y+10)
      ..lineTo(0, y+10)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.18*opacity));
  }

  @override
  bool shouldRepaint(_TropicalPainter old) => false;
}

// ════════════════════════════════════════════════════════════
// DATA CLASSES & SMALL WIDGETS
// ════════════════════════════════════════════════════════════

class _MascotData {
  final String emoji, name;
  final Color  color, bg;
  const _MascotData({required this.emoji, required this.name,
      required this.color, required this.bg});
}

class _StarDeco {
  final double x, y, size, phase;
  const _StarDeco({required this.x, required this.y,
      required this.size, required this.phase});
}

class _SpinStar extends StatefulWidget {
  final Color color; final double size; final int delay;
  const _SpinStar({required this.color, required this.size, required this.delay});
  @override State<_SpinStar> createState() => _SpinStarState();
}
class _SpinStarState extends State<_SpinStar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.rotate(
      angle: _c.value * 2 * math.pi,
      child: Text('✦', style: TextStyle(fontSize: widget.size, color: widget.color)),
    ),
  );
}

class _FeatBtn {
  final String emoji, label; final Color color;
  const _FeatBtn({required this.emoji, required this.label, required this.color});
}

class _FeatureButton extends StatefulWidget {
  final _FeatBtn data;
  const _FeatureButton({required this.data});
  @override State<_FeatureButton> createState() => _FeatureButtonState();
}
class _FeatureButtonState extends State<_FeatureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _scale;
  @override
  void initState() {
    super.initState();
    _c     = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); HapticFeedback.lightImpact(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.data.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: widget.data.color.withOpacity(0.45),
              blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.data.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(widget.data.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                  color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
      ),
    ),
  );
}