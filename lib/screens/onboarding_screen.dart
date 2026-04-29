// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'world_map_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final _nameCtrl = TextEditingController();
  String _avatar  = '🦁';
  bool   _loading = false;
  bool   _nameError = false;

  late final AnimationController _mascotCtrl;
  late final Animation<double>   _mascotAnim;
  late final AnimationController _bgCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnAnim;
  late final AnimationController _starCtrl;
  late final Animation<double>   _shootAnim;

  static const _avatars = [
    '🦁','🐸','🦊','🐧','🦋',
    '🐬','🦄','🦅','🐼','🐯',
    '🐙','🦓','🦒','🐺','🦜',
  ];

  @override
  void initState() {
    super.initState();

    _mascotCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _mascotAnim = Tween<double>(begin: -10, end: 10)
        .animate(CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeInOut));

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 12))..repeat(reverse: true);

    _btnCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _btnAnim = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _starCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
    _shootAnim = CurvedAnimation(parent: _starCtrl,
        curve: const Interval(0, 0.12));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) TtsService().speak('Bienvenue ! Écris ton prénom !');
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mascotCtrl.dispose();
    _bgCtrl.dispose();
    _btnCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      HapticFeedback.vibrate();
      TtsService().speak('Écris ton prénom d\'abord !');
      return;
    }
    setState(() { _loading = true; _nameError = false; });
    HapticFeedback.mediumImpact();
    TtsService().speak('Bravo $name ! L\'aventure commence !');
    await ProgressService().createStudent(name, emoji: _avatar);
    if (mounted) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, a, __) => const WorldMapScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        AnimatedBuilder(animation: _bgCtrl, builder: (_, __) =>
            CustomPaint(size: size, painter: _OnboardingBg(t: _bgCtrl.value))),
        AnimatedBuilder(animation: _shootAnim, builder: (_, __) =>
            _ShootingStar(size: size, t: _shootAnim.value)),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 16, 24,
                MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(children: [
              _buildMascot(),
              const SizedBox(height: 18),
              _buildTitle(),
              const SizedBox(height: 26),
              _buildNameField(),
              const SizedBox(height: 22),
              _buildAvatarSection(),
              const SizedBox(height: 30),
              _buildStartButton(),
              const SizedBox(height: 14),
              Text('Gratuit · Sans pub · 100% éducatif 🎓',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMascot() => AnimatedBuilder(
    animation: _mascotAnim,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _mascotAnim.value),
      child: Center(child: Stack(alignment: Alignment.center, children: [
        Container(width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Colors.blue.withValues(alpha: 0.35), Colors.transparent])),
        ),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
            boxShadow: [
              BoxShadow(color: Colors.blue.withValues(alpha: 0.5),
                  blurRadius: 20, spreadRadius: 2),
              BoxShadow(color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 6)),
            ],
          ),
          child: Center(child: Text(_avatar,
              style: const TextStyle(fontSize: 48))),
        ),
        Positioned(top: 10, left: 30, right: 30,
          child: Container(height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withValues(alpha: 0.35), Colors.transparent],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(20),
            )),
        ),
      ])),
    ),
  );

  Widget _buildTitle() => Column(children: [
    ShaderMask(
      shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFFFFD600), Color(0xFFFF6D00), Color(0xFFFF4081)])
          .createShader(r),
      child: const Text('🌟 LinguaKids',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 34,
            fontWeight: FontWeight.w900, letterSpacing: 1)),
    ),
    const SizedBox(height: 6),
    Text('Apprends le français en jouant !',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
      _badge('🎮 4 Jeux'),
      _badge('🏝️ 5 Îles'),
      _badge('⭐ Récompenses'),
      _badge('🤖 IA Adaptative'),
    ]),
  ]);

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Text(t, style: const TextStyle(color: Colors.white,
        fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _buildNameField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(children: [
          const Text('✏️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          const Text('Ton prénom', style: TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
      ),
      TextField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Colors.white,
            fontSize: 18, fontWeight: FontWeight.bold),
        onChanged: (_) { if (_nameError) setState(() => _nameError = false); },
        decoration: InputDecoration(
          hintText: 'Ex : Amira, Youssef, Fatima…',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35),
              fontSize: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Text('😊', style: TextStyle(fontSize: 22)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: _nameError
              ? Colors.red.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: _nameError
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
                color: _nameError ? Colors.red : Colors.blue.shade300, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          errorText: _nameError ? 'Écris ton prénom pour commencer !' : null,
          errorStyle: const TextStyle(color: Colors.orangeAccent),
        ),
      ),
    ],
  );

  Widget _buildAvatarSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Row(children: [
          const Text('🎭', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          const Text('Choisis ta mascotte', style: TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _avatars.length,
          itemBuilder: (_, i) {
            final em = _avatars[i];
            final sel = em == _avatar;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _avatar = em);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: sel ? const LinearGradient(
                      colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]) : null,
                  color: sel ? null : Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: sel ? Colors.amber : Colors.white.withValues(alpha: 0.2),
                    width: sel ? 2.5 : 1,
                  ),
                  boxShadow: sel ? [BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 10, spreadRadius: 1)] : [],
                ),
                child: Center(child: AnimatedScale(
                  scale: sel ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Text(em, style: const TextStyle(fontSize: 24)),
                )),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildStartButton() => AnimatedBuilder(
    animation: _btnAnim,
    builder: (_, child) => Transform.scale(
        scale: _loading ? 1.0 : _btnAnim.value, child: child),
    child: GestureDetector(
      onTap: _loading ? null : _start,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: _loading
                ? [Colors.grey.shade700, Colors.grey.shade600]
                : const [Color(0xFFFF8F00), Color(0xFFFFCA28), Color(0xFFFF8F00)],
          ),
          boxShadow: [
            BoxShadow(
              color: (_loading ? Colors.grey : Colors.amber)
                  .withValues(alpha: 0.55),
              blurRadius: 18, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4, offset: const Offset(0, 3)),
          ],
          border: _loading ? null : const Border(
            bottom: BorderSide(color: Color(0xFFE65100), width: 5)),
        ),
        child: Stack(children: [
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.35), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22)),
              ))),
          Center(child: _loading
              ? const SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🚀', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text('COMMENCER L\'AVENTURE',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w900, letterSpacing: 1.5,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 3)])),
                ])),
        ]),
      ),
    ),
  );
}

// ─── Fond étoilé ────────────────────────────────────────
class _OnboardingBg extends CustomPainter {
  final double t;
  const _OnboardingBg({required this.t});
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
      Paint()..shader = LinearGradient(
        colors: const [Color(0xFF080B1A), Color(0xFF0D1F35),
            Color(0xFF0A2744), Color(0xFF0D3B6E)],
        begin: Alignment(math.sin(t * math.pi) * 0.3, -1),
        end: Alignment(math.sin(t * math.pi) * -0.3, 1),
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
    final rng = math.Random(55);
    for (int i = 0; i < 100; i++) {
      final r = rng.nextDouble() * 1.5 + 0.3;
      final a = 0.15 + rng.nextDouble() * 0.55;
      canvas.drawCircle(
        Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height),
        r, Paint()..color = Colors.white.withValues(alpha: a));
    }
  }
  @override
  bool shouldRepaint(covariant _OnboardingBg o) => o.t != t;
}

class _ShootingStar extends StatelessWidget {
  final Size size;
  final double t;
  const _ShootingStar({required this.size, required this.t});
  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    return Positioned(
      left: size.width * 0.75 - t * size.width * 0.65,
      top: size.height * 0.05 + t * size.height * 0.12,
      child: Opacity(
        opacity: (1 - t * 2.5).clamp(0.0, 1.0),
        child: Container(width: 55 + t * 35, height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, Colors.transparent]))),
      ),
    );
  }
}