// lib/screens/games/letter_discovery_screen.dart
// ═══════════════════════════════════════════════════════════
// LinguaKids — Jeu 1 : Découverte de la Lettre
// Lettre animée + image + son → enfant tape pour répéter
// Aucun texte de lecture requis
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../widgets/lumi_mascot.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/lk_widgets.dart';
import 'letter_recognition_game.dart';

// Données pédagogiques CP Maroc
class LetterData {
  final String letter;
  final String lowerCase;
  final String exampleWord;
  final String exampleEmoji;
  final String arabicWord;
  final Color  color;
  final Color  dark;

  const LetterData({
    required this.letter,
    required this.lowerCase,
    required this.exampleWord,
    required this.exampleEmoji,
    required this.arabicWord,
    required this.color,
    required this.dark,
  });
}

const kLetterDatabase = {
  'A': LetterData(letter:'A', lowerCase:'a', exampleWord:'Avion',    exampleEmoji:'✈️', arabicWord:'طيارة', color:Color(0xFFFFD93D), dark:Color(0xFFFFA000)),
  'B': LetterData(letter:'B', lowerCase:'b', exampleWord:'Ballon',   exampleEmoji:'🎈', arabicWord:'بالون', color:Color(0xFFFF8C9E), dark:Color(0xFFD4537E)),
  'C': LetterData(letter:'C', lowerCase:'c', exampleWord:'Chat',     exampleEmoji:'🐱', arabicWord:'قطة',   color:Color(0xFF85DAFF), dark:Color(0xFF378ADD)),
  'D': LetterData(letter:'D', lowerCase:'d', exampleWord:'Dindon',   exampleEmoji:'🦃', arabicWord:'ديك',   color:Color(0xFFA8E6CF), dark:Color(0xFF3DAD8A)),
  'E': LetterData(letter:'E', lowerCase:'e', exampleWord:'Éléphant', exampleEmoji:'🐘', arabicWord:'فيل',   color:Color(0xFFCECBF6), dark:Color(0xFF8B7FD4)),
  'F': LetterData(letter:'F', lowerCase:'f', exampleWord:'Fleur',    exampleEmoji:'🌸', arabicWord:'وردة',  color:Color(0xFFFF9B7A), dark:Color(0xFFE07050)),
  'G': LetterData(letter:'G', lowerCase:'g', exampleWord:'Grenouille',exampleEmoji:'🐸', arabicWord:'ضفدع', color:Color(0xFF5DCAA5), dark:Color(0xFF3DAD8A)),
  'H': LetterData(letter:'H', lowerCase:'h', exampleWord:'Hibou',    exampleEmoji:'🦉', arabicWord:'بومة',  color:Color(0xFFFFD93D), dark:Color(0xFFFFA000)),
  'I': LetterData(letter:'I', lowerCase:'i', exampleWord:'Igloo',    exampleEmoji:'🏠', arabicWord:'جليد',  color:Color(0xFF85DAFF), dark:Color(0xFF378ADD)),
  'J': LetterData(letter:'J', lowerCase:'j', exampleWord:'Jaguar',   exampleEmoji:'🐆', arabicWord:'جاغوار',color:Color(0xFFFF8C9E), dark:Color(0xFFD4537E)),
};

class LetterDiscoveryScreen extends StatefulWidget {
  final String       islandId;
  final List<String> letters;
  final int          dayNumber;

  const LetterDiscoveryScreen({
    super.key,
    required this.islandId,
    required this.letters,
    required this.dayNumber,
  });

  @override
  State<LetterDiscoveryScreen> createState() => _LetterDiscoveryScreenState();
}

class _LetterDiscoveryScreenState extends State<LetterDiscoveryScreen>
    with TickerProviderStateMixin {

  int _currentLetterIdx = 0;

  // Animations
  late AnimationController _letterBounceCtrl;
  late AnimationController _letterSpinCtrl;
  late AnimationController _imagePopCtrl;
  late AnimationController _tapRippleCtrl;
  late AnimationController _lumiCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _letterBounce;
  late Animation<double> _letterSpin;
  late Animation<double> _imagePop;
  late Animation<double> _tapRipple;
  late Animation<double> _lumiFloat;
  late Animation<double> _particleAnim;

  bool _showImage     = false;
  bool _tapped        = false;
  bool _showUppercase = true;
  int  _tapCount      = 0; // enfant doit taper 3 fois
  LumiMood _lumiMood  = LumiMood.guide;

  LetterData get _currentData =>
    kLetterDatabase[widget.letters[_currentLetterIdx]] ??
    const LetterData(letter:'A', lowerCase:'a', exampleWord:'Avion',
      exampleEmoji:'✈️', arabicWord:'طيارة', color:Color(0xFFFFD93D), dark:Color(0xFFFFA000));

  @override
  void initState() {
    super.initState();

    _letterBounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _letterSpinCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _imagePopCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _tapRippleCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _lumiCtrl         = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _particleCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _letterBounce = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _letterBounceCtrl, curve: Curves.elasticOut));
    _letterSpin   = CurvedAnimation(parent: _letterSpinCtrl, curve: Curves.linear);
    _imagePop     = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _imagePopCtrl, curve: Curves.elasticOut));
    _tapRipple    = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _tapRippleCtrl, curve: Curves.easeOut));
    _lumiFloat    = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _lumiCtrl, curve: Curves.easeInOut));
    _particleAnim = CurvedAnimation(parent: _particleCtrl, curve: Curves.easeOut);

    // Jouer la lettre au démarrage
    Future.delayed(const Duration(milliseconds: 600), _playCurrentLetter);
  }

  @override
  void dispose() {
    _letterBounceCtrl.dispose();
    _letterSpinCtrl.dispose();
    _imagePopCtrl.dispose();
    _tapRippleCtrl.dispose();
    _lumiCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _playCurrentLetter() async {
    final data = _currentData;
    // Bounce de la lettre
    _letterBounceCtrl.forward(from: 0);
    // TTS
    await TtsService().speak(data.letter);
    await Future.delayed(const Duration(milliseconds: 400));
    await TtsService().speak(data.exampleWord);
    // Apparition de l'image
    setState(() => _showImage = true);
    _imagePopCtrl.forward(from: 0);
  }

  Future<void> _onLetterTap() async {
    if (_tapped && _tapCount >= 3) return;
    HapticFeedback.lightImpact();

    setState(() {
      _tapCount++;
      _tapped = true;
      _showUppercase = !_showUppercase;
      _lumiMood = LumiMood.celebrate;
    });

    _letterBounceCtrl.forward(from: 0);
    _tapRippleCtrl.forward(from: 0);
    SoundService().play(SoundEffect.correct);
    await TtsService().speak(_currentData.letter);

    if (_tapCount >= 3) {
      _particleCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 800));

      if (_currentLetterIdx + 1 < widget.letters.length) {
        // Lettre suivante
        setState(() {
          _currentLetterIdx++;
          _tapCount   = 0;
          _tapped     = false;
          _showImage  = false;
          _showUppercase = true;
          _lumiMood   = LumiMood.guide;
        });
        _imagePopCtrl.reset();
        _letterBounceCtrl.reset();
        await Future.delayed(const Duration(milliseconds: 300));
        _playCurrentLetter();
      } else {
        // Toutes les lettres découvertes → passer au jeu suivant
        await _recordAndNext();
      }
    } else {
      setState(() => _lumiMood = LumiMood.happy);
    }
  }

  Future<void> _recordAndNext() async {
    await ProgressService().recordScore(
      levelId: widget.islandId,
      gameType: 'discovery_${widget.dayNumber}',
      score: widget.letters.length,
      maxScore: widget.letters.length,
    );
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => LetterRecognitionGame(
        islandId:  widget.islandId,
        letters:   widget.letters,
        dayNumber: widget.dayNumber,
      ),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentData;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [data.color.withOpacity(0.9), data.dark.withOpacity(0.7),
                     Colors.white, const Color(0xFFF0FFF8)],
            stops: const [0.0, 0.25, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildTopBar(data),
            Expanded(
              child: Stack(alignment: Alignment.center, children: [
                // Fond décoratif
                _buildBackgroundCircles(data),
                // Contenu central
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLetterDisplay(data),
                    const SizedBox(height: 24),
                    if (_showImage) _buildExampleImage(data),
                    const SizedBox(height: 24),
                    _buildTapInstruction(data),
                    const SizedBox(height: 16),
                    _buildTapDots(),
                  ],
                ),
                // Particules de succès
                if (_tapCount >= 3)
                  AnimatedBuilder(
                    animation: _particleAnim,
                    builder: (_, __) =>
                        _ParticlesBurst(progress: _particleAnim.value, color: data.color),
                  ),
              ]),
            ),
            _buildLumiBar(data),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar(LetterData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 2)),
            child: Icon(Icons.close_rounded, color: data.dark, size: 20),
          ),
        ),
        const Spacer(),
        // Indicateur lettres
        Row(children: List.generate(widget.letters.length, (i) {
          final done = i < _currentLetterIdx;
          final cur  = i == _currentLetterIdx;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: cur ? 36 : 28, height: cur ? 36 : 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF5DCAA5)
                   : cur  ? data.color
                   : Colors.white.withOpacity(0.35),
              border: Border.all(
                color: done ? const Color(0xFF3DAD8A)
                     : cur  ? data.dark
                     : Colors.white.withOpacity(0.5),
                width: cur ? 2.5 : 2),
              boxShadow: cur ? [BoxShadow(color: data.color.withOpacity(0.5), blurRadius: 10)] : [],
            ),
            child: Center(child: Text(
              done ? '⭐' : widget.letters[i],
              style: TextStyle(
                fontSize: cur ? 18 : 14, fontWeight: FontWeight.w900,
                color: cur ? data.dark : Colors.white),
            )),
          );
        })),
        const Spacer(),
        // Label jeu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.dark, width: 2)),
          child: Text('👂 Écoute',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: data.dark)),
        ),
      ]),
    );
  }

  Widget _buildBackgroundCircles(LetterData data) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BgCirclesPainter(color: data.color),
      ),
    );
  }

  Widget _buildLetterDisplay(LetterData data) {
    return AnimatedBuilder(
      animation: Listenable.merge([_letterBounce, _tapRipple]),
      builder: (_, __) {
        return Stack(alignment: Alignment.center, children: [
          // Ripple tap
          if (_tapped)
            Transform.scale(
              scale: 1 + _tapRipple.value * 0.8,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.color.withOpacity(0.25 * (1 - _tapRipple.value)),
                ),
              ),
            ),
          // Cercle fond lettre
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white, data.color.withOpacity(0.3)]),
              border: Border.all(color: data.dark, width: 3.5),
              boxShadow: [
                BoxShadow(color: data.color.withOpacity(0.5), blurRadius: 24, spreadRadius: 4),
                BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 8, spreadRadius: -2),
              ],
            ),
          ),
          // Lettre principale
          GestureDetector(
            onTap: _onLetterTap,
            child: Transform.scale(
              scale: _letterBounce.value,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_showUppercase ? data.letter : data.lowerCase,
                  style: TextStyle(
                    fontSize: 80, fontWeight: FontWeight.w900,
                    color: data.dark,
                    shadows: [
                      Shadow(color: data.dark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,4)),
                    ],
                  ),
                ),
                // Minuscule / majuscule label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: data.dark, width: 1.5)),
                  child: Text(
                    _showUppercase ? 'Majuscule' : 'Minuscule',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ]),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildExampleImage(LetterData data) {
    return ScaleTransition(
      scale: _imagePop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: data.color, width: 2.5),
          boxShadow: [BoxShadow(
            color: data.color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0,5))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(data.exampleEmoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.exampleWord,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: data.dark)),
            const SizedBox(height: 2),
            Text(data.arabicWord,
              style: const TextStyle(fontSize: 14, color: LKColors.textMedium,
                  fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTapInstruction(LetterData data) {
    return GestureDetector(
      onTap: _onLetterTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [data.color, data.dark]),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: data.dark.withOpacity(0.4), blurRadius: 14, offset: const Offset(0,5)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('👆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tape et répète !',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('${3 - _tapCount.clamp(0, 3)} fois encore',
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(width: 8),
          const Text('🔊', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Widget _buildTapDots() {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
      final done = i < _tapCount;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: done ? 18 : 12,
        height: done ? 18 : 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? const Color(0xFF5DCAA5) : Colors.white.withOpacity(0.4),
          border: Border.all(
            color: done ? const Color(0xFF3DAD8A) : Colors.white.withOpacity(0.6), width: 2),
          boxShadow: done ? [BoxShadow(
            color: const Color(0xFF5DCAA5).withOpacity(0.5), blurRadius: 8)] : [],
        ),
        child: done ? const Center(child: Text('✓',
          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900))) : null,
      );
    }));
  }

  Widget _buildLumiBar(LetterData data) {
    return AnimatedBuilder(
      animation: _lumiFloat,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _lumiFloat.value),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: data.color, width: 2.5),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0,3))],
          ),
          child: Row(children: [
            LumiMascot(mood: _lumiMood, size: 38),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _tapCount == 0
                ? '👂 Écoute bien ! Tape la lettre pour répéter !'
                : _tapCount == 1
                ? '👏 Super ! Encore 2 fois !'
                : _tapCount == 2
                ? '🔥 Presque ! Encore une fois !'
                : '🎉 Parfait ! Tu connais la lettre ${data.letter} !',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: data.dark),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── Background circles ────────────────────────────────────────
class _BgCirclesPainter extends CustomPainter {
  final Color color;
  const _BgCirclesPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width*0.85, size.height*0.12), 80, p);
    canvas.drawCircle(Offset(size.width*0.10, size.height*0.80), 60, p);
    canvas.drawCircle(Offset(size.width*0.92, size.height*0.85), 45, p);
    canvas.drawCircle(Offset(size.width*0.05, size.height*0.20), 35, p);
  }
  @override bool shouldRepaint(_) => false;
}

// ── Particles burst ──────────────────────────────────────────
class _ParticlesBurst extends StatelessWidget {
  final double progress;
  final Color  color;
  const _ParticlesBurst({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlesPainter(progress: progress, color: color),
      size: const Size(300, 300),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _ParticlesPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rng = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist  = progress * 120;
      final x     = cx + dist * math.cos(angle);
      final y     = cy + dist * math.sin(angle);
      final r     = (3 + rng.nextDouble() * 5) * (1 - progress * 0.5);
      canvas.drawCircle(Offset(x, y),
        r,
        Paint()..color = color.withOpacity((1 - progress) * 0.85));
    }
    // Étoiles
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final stars = ['⭐', '✨', '🌟'];
    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist  = progress * 90;
      textPainter.text = TextSpan(
        text: stars[i % stars.length],
        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity((1-progress)*0.9)));
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        cx + dist * math.cos(angle) - 8,
        cy + dist * math.sin(angle) - 8,
      ));
    }
  }
  @override bool shouldRepaint(_ParticlesPainter o) => o.progress != progress;
}