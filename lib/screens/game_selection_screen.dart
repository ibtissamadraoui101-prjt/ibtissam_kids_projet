// lib/screens/game_selection_screen.dart
// 🎮 SÉLECTION DE JEU — Style Candy Crush
// 4 jeux en chemin sinueux · nœuds 3D brillants · déblocage progressif
// Memory → Quiz → Bingo → Parcours

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/game_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'memory_game_screen.dart';
import 'quiz_game_screen.dart';
import 'bingo_game_screen.dart';
import 'parcours_game_screen.dart';

// ─── Config d'un jeu ─────────────────────────────────────
class _GameCfg {
  final String type, title, emoji, desc, locked;
  final Color c1, c2;
  const _GameCfg(this.type, this.title, this.emoji,
      this.desc, this.locked, this.c1, this.c2);
}

class GameSelectionScreen extends StatefulWidget {
  final GameLevelData levelData;
  const GameSelectionScreen({super.key, required this.levelData});
  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with TickerProviderStateMixin {

  // Animations
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryAnim;
  late final AnimationController _sparkCtrl;
  late final AnimationController _confCtrl;
  late final Animation<double>   _confAnim;
  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatAnim;

  // Pour la carte active qui pulse
  int _activeIdx = 0;

  static const _games = [
    _GameCfg('memory',  'Memory',  '🃏', 'Retourne les cartes\net trouve les paires !',
        'Commence par ici !',       Color(0xFF0D47A1), Color(0xFF1976D2)),
    _GameCfg('quiz',    'Quiz',    '❓', 'Réponds aux\nquestions !',
        'Finis Memory d\'abord !',  Color(0xFF1B5E20), Color(0xFF388E3C)),
    _GameCfg('bingo',   'Bingo',   '🎯', 'Écoute et clique\nla bonne image !',
        'Finis Quiz d\'abord !',    Color(0xFF4A148C), Color(0xFF7B1FA2)),
    _GameCfg('parcours','Parcours','🏆', 'Avance case\npar case !',
        'Finis Bingo d\'abord !',   Color(0xFFBF360C), Color(0xFFE64A19)),
  ];

  // Zigzag horizontal (fraction 0→1 de la largeur)
  static const _xPos = [0.62, 0.12, 0.62, 0.12];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    _entryCtrl.forward();

    _sparkCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _confCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _confAnim = CurvedAnimation(parent: _confCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Trouver le premier jeu non complété
    _activeIdx = _findActiveIndex();

    // Si tout complété → confettis
    final all = _games.every(
      (g) => ProgressService().hasCompletedGame(widget.levelData.id, g.type));
    if (all) Future.delayed(const Duration(milliseconds: 600), () => _confCtrl.forward());

    TtsService().speak(widget.levelData.title);
  }

  int _findActiveIndex() {
    for (int i = 0; i < _games.length; i++) {
      if (!ProgressService().hasCompletedGame(widget.levelData.id, _games[i].type)) return i;
    }
    return _games.length - 1;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _entryCtrl.dispose();
    _sparkCtrl.dispose(); _confCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final allDone = _games.every(
      (g) => ProgressService().hasCompletedGame(widget.levelData.id, g.type));
    final stars = ProgressService().starsFor(widget.levelData.id);

    return Scaffold(
      body: Stack(children: [
        // ── Fond ───────────────────────────────────────
        _buildBg(),

        // ── Particules flottantes ───────────────────────
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, __) => _buildParticles(size),
        ),

        SafeArea(
          child: Column(children: [
            _buildHeader(stars),
            Expanded(
              child: ListenableBuilder(
                listenable: ProgressService(),
                builder: (_, __) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
                  child: Column(children: [
                    // ── Info du niveau ──────────────────
                    _buildLevelInfo(),
                    const SizedBox(height: 20),
                    // ── Chemin des 4 jeux ───────────────
                    for (int i = 0; i < _games.length; i++) ...[
                      if (i > 0) _buildConnector(i, size.width),
                      _buildGameNode(i, size.width),
                    ],
                    const SizedBox(height: 20),
                    if (allDone) _buildVictoryPanel(stars),
                  ]),
                ),
              ),
            ),
          ]),
        ),

        // ── Confettis ──────────────────────────────────
        AnimatedBuilder(
          animation: _confAnim,
          builder: (_, __) => _ConfettiOverlay(progress: _confAnim.value),
        ),
      ]),
    );
  }

  // ─── Fond ─────────────────────────────────────────────
  Widget _buildBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0A0E27), Color(0xFF0D2137), Color(0xFF1A3A5C)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
    ),
    child: CustomPaint(size: const Size(double.infinity, double.infinity),
        painter: _BgStarsPainter()),
  );

  // ─── Particules déco ──────────────────────────────────
  Widget _buildParticles(Size sz) => IgnorePointer(
    child: Stack(children: [
      Positioned(top: 80  + _floatAnim.value * 0.5, right: 24,
          child: const Text('✨', style: TextStyle(fontSize: 18))),
      Positioned(top: 220 - _floatAnim.value * 0.7, left: 16,
          child: const Text('💫', style: TextStyle(fontSize: 14))),
      Positioned(top: 380 + _floatAnim.value * 0.4, right: 40,
          child: const Text('⭐', style: TextStyle(fontSize: 16))),
    ]),
  );

  // ─── Header ───────────────────────────────────────────
  Widget _buildHeader(int stars) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Row(children: [
      _glassBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.levelData.title,
            style: const TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)])),
          Text(widget.levelData.getProgression(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
        ]),
      ),
      // Étoiles
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('⭐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$stars/3',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
      ),
    ]),
  );

  Widget _glassBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  // ─── Info niveau ──────────────────────────────────────
  Widget _buildLevelInfo() {
    final done  = ProgressService().completedGameCount(widget.levelData.id);
    final total = _games.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        // Icône niveau
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: Center(child: Text(_getLevelEmoji(),
              style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.levelData.description,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.book_outlined, color: Colors.cyan, size: 13),
            const SizedBox(width: 4),
            Text('${widget.levelData.vocabulary.length} mots',
              style: const TextStyle(color: Colors.cyan, fontSize: 11,
                  fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            const Icon(Icons.timer_outlined, color: Colors.lime, size: 13),
            const SizedBox(width: 4),
            Text('${widget.levelData.estimatedDuration} min',
              style: const TextStyle(color: Colors.lime, fontSize: 11,
                  fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          // Barre progression jeux
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            ),
          ),
          const SizedBox(height: 3),
          Text('$done / $total jeux complétés',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10)),
        ])),
      ]),
    );
  }

  // ─── Nœud de jeu ──────────────────────────────────────
  Widget _buildGameNode(int i, double screenW) {
    final g          = _games[i];
    final isUnlocked = ProgressService().isGameUnlocked(widget.levelData.id, g.type);
    final isDone     = ProgressService().hasCompletedGame(widget.levelData.id, g.type);
    final isActive   = isUnlocked && !isDone;

    final xFrac = _xPos[i];
    final lPad  = (screenW * xFrac - 75).clamp(12.0, screenW - 162.0);

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Transform.scale(
        scale: _entryAnim.value,
        child: child,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: lPad),
        child: GestureDetector(
          onTap: () => _onGameTap(g, isUnlocked),
          child: AnimatedBuilder(
            animation: isActive ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
            builder: (_, child) => Transform.scale(
              scale: isActive ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: SizedBox(
              width: 150,
              child: _NodeBody(
                game: g, isUnlocked: isUnlocked,
                isDone: isDone, isActive: isActive,
                index: i,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Connecteur animé ─────────────────────────────────
  Widget _buildConnector(int idx, double screenW) {
    final prevX = _xPos[idx - 1];
    final currX = _xPos[idx];
    return AnimatedBuilder(
      animation: _sparkCtrl,
      builder: (_, __) => SizedBox(
        width: screenW, height: 56,
        child: CustomPaint(
          painter: _ConnectorPainter(
            prevXFrac: prevX, currXFrac: currX,
            progress: _sparkCtrl.value,
          ),
        ),
      ),
    );
  }

  // ─── Panel victoire ───────────────────────────────────
  Widget _buildVictoryPanel(int stars) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5),
          blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      const Text('🏆', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 6),
      const Text('Niveau terminé !',
          style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(i < stars ? '⭐' : '☆',
            style: TextStyle(fontSize: 32,
              color: i < stars ? Colors.white : Colors.white.withValues(alpha: 0.3))),
        ),
      )),
      const SizedBox(height: 10),
      Text('Tu as maîtrisé : ${widget.levelData.title} 🎉',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
    ]),
  );

  // ─── Tap sur un jeu ───────────────────────────────────
  void _onGameTap(_GameCfg g, bool unlocked) {
    if (!unlocked) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('🔒 ', style: TextStyle(fontSize: 18)),
          Text(g.locked, style: const TextStyle(fontSize: 13)),
        ]),
        backgroundColor: const Color(0xFF1A237E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    HapticFeedback.mediumImpact();
    TtsService().speak(g.title);

    Widget screen;
    switch (g.type) {
      case 'memory':   screen = MemoryGameScreen(levelData: widget.levelData);   break;
      case 'quiz':     screen = QuizGameScreen(levelData: widget.levelData);     break;
      case 'bingo':    screen = BingoGameScreen(levelData: widget.levelData);    break;
      case 'parcours': screen = ParcourGameScreen(levelData: widget.levelData);  break;
      default: return;
    }

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => screen,
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 320),
    )).then((_) {
      setState(() => _activeIdx = _findActiveIndex());
    });
  }

  String _getLevelEmoji() {
    final t = (widget.levelData.theme ?? '').toLowerCase();
    if (t.contains('alpha'))  return '🔤';
    if (t.contains('number') || t.contains('chiffre')) return '🔢';
    if (t.contains('color')  || t.contains('couleur')) return '🎨';
    if (t.contains('greet')  || t.contains('salut'))   return '👋';
    if (t.contains('animal')) return '🐾';
    if (t.contains('food')   || t.contains('nourrit')) return '🍎';
    if (t.contains('météo'))  return '⛅';
    if (t.contains('famille'))return '👨‍👩‍👧';
    return '📖';
  }
}

// ─── Corps d'un nœud ──────────────────────────────────────
class _NodeBody extends StatelessWidget {
  final _GameCfg game;
  final bool isUnlocked, isDone, isActive;
  final int index;
  const _NodeBody({required this.game, required this.isUnlocked,
      required this.isDone, required this.isActive, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = isDone
        ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
        : isActive
            ? [game.c1, game.c2]
            : [const Color(0xFF1C2633), const Color(0xFF2D3A4A)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8, offset: const Offset(0, 7)),
          if (isUnlocked)
            BoxShadow(color: (isDone ? Colors.green : game.c1).withValues(alpha: 0.4),
                blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.18),
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Stack(children: [
          // Reflet 3D
          Positioned(top: 0, left: 0, right: 0,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.28), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          // Contenu
          Column(children: [
            // Numéro
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isUnlocked ? 0.22 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text('${index + 1}',
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.35),
                    fontSize: 13, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 7),
            // Emoji
            Text(isUnlocked ? game.emoji : '🔒',
                style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            // Titre
            Text(game.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.35),
                fontSize: 13, fontWeight: FontWeight.w900,
              )),
            const SizedBox(height: 4),
            // Description
            Text(game.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.25),
                fontSize: 9.5,
              ),
              maxLines: 2),
            const SizedBox(height: 8),
            // CTA bouton
            if (isDone)
              _chip('✓ Refaire', Colors.white.withValues(alpha: 0.2))
            else if (isActive)
              _ctaBtn()
            else
              _chip('🔒', Colors.white.withValues(alpha: 0.08)),
          ]),
        ]),
      ),
    );
  }

  Widget _ctaBtn() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)]),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.55),
          blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: const Text('▶ JOUER',
      style: TextStyle(color: Colors.white, fontSize: 10,
          fontWeight: FontWeight.w900, letterSpacing: 1.4)),
  );

  Widget _chip(String t, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg,
        borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: const TextStyle(color: Colors.white,
        fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

// ─── Connecteur chemin animé ──────────────────────────────
class _ConnectorPainter extends CustomPainter {
  final double prevXFrac, currXFrac, progress;
  const _ConnectorPainter(
      {required this.prevXFrac, required this.currXFrac, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final startX = size.width * prevXFrac + 75;
    final endX   = size.width * currXFrac + 75;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 5 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.6)
      ..strokeWidth = 3 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(startX, size.height * 0.5,
                endX,   size.height * 0.5, endX, size.height);

    canvas.drawPath(path, basePaint);

    // Tirets dorés
    for (final m in path.computeMetrics()) {
      double d = 0; bool draw = true;
      while (d < m.length) {
        final l = draw ? 10.0 : 7.0;
        if (draw) canvas.drawPath(m.extractPath(d, (d + l).clamp(0, m.length)), dotPaint);
        d += l; draw = !draw;
      }
      // Point lumineux animé
      final pos = m.getTangentForOffset(m.length * progress);
      if (pos != null) {
        canvas.drawCircle(pos.position, 5,
            Paint()..color = Colors.white.withValues(alpha: 0.9));
        canvas.drawCircle(pos.position, 3,
            Paint()..color = Colors.amber..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter o) => o.progress != progress;
}

// ─── Fond étoilé ─────────────────────────────────────────
class _BgStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);
    for (int i = 0; i < 70; i++) {
      final r = rng.nextDouble() * 1.4 + 0.3;
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        r, Paint()..color = Colors.white.withValues(alpha: 0.2 + rng.nextDouble() * 0.4));
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Confettis ───────────────────────────────────────────
class _ConfettiOverlay extends StatelessWidget {
  final double progress;
  const _ConfettiOverlay({required this.progress});
  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height),
        painter: _ConfPainter(progress: progress),
      ),
    );
  }
}

class _ConfPainter extends CustomPainter {
  final double progress;
  static const _cols = [Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
  const _ConfPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(13);
    for (int i = 0; i < 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -20.0 + (size.height + 40) * progress
          + math.sin(progress * 8 + i) * 38;
      final p = Paint()..color = _cols[i % _cols.length]
          .withValues(alpha: (1 - progress).clamp(0, 1));
      final r = Rect.fromCenter(
          center: Offset(x + math.sin(progress * 5 + i) * 22, y),
          width: 9, height: 14);
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(progress * 9 + i.toDouble());
      canvas.translate(-r.center.dx, -r.center.dy);
      canvas.drawRect(r, p);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfPainter o) => o.progress != progress;
}