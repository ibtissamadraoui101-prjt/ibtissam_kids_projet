// lib/screens/game_selection_screen.dart
// ✅ v3 — 6 jeux au lieu de 4 :
//   Memory → Quiz → Bingo → Parcours → 🎤 Vocal → 🔀 Phrases
//   Les 2 nouveaux jeux ciblent la COMMUNICATION ORALE et ÉCRITE
//   Le jeu Vocal est débloqué après Parcours
//   Le jeu Phrases est débloqué après Vocal

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/adaptive_engine.dart';
import 'memory_game_screen.dart';
import 'quiz_game_screen.dart';
import 'bingo_game_screen.dart';
import 'parcours_game_screen.dart';
import 'vocal_game_screen.dart';           // ✅ NOUVEAU
import 'phrase_order_game_screen.dart';    // ✅ NOUVEAU

class _GCfg {
  final String type, title, emoji, desc, lockMsg;
  final Color c1, c2, slab;
  const _GCfg(this.type, this.title, this.emoji,
      this.desc, this.lockMsg, this.c1, this.c2, this.slab);
}

class GameSelectionScreen extends StatefulWidget {
  final GameLevelData levelData;
  const GameSelectionScreen({super.key, required this.levelData});
  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with TickerProviderStateMixin {

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;
  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryAnim;
  late final AnimationController _sparkCtrl;
  late final AnimationController _confCtrl;
  late final Animation<double>   _confAnim;
  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatAnim;

  // ✅ 6 jeux : les 4 originaux + Vocal + Phrases
  static const _games = [
    _GCfg('memory',  'Memory',   '🃏', 'Retourne les cartes\net trouve les paires !',
        'Commence par ici !',
        Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF0A2F6B)),
    _GCfg('quiz',    'Quiz',     '❓', 'Réponds aux\nquestions !',
        'Finis Memory d\'abord !',
        Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF103A0F)),
    _GCfg('bingo',   'Bingo',    '🎯', 'Écoute et clique\nla bonne image !',
        'Finis Quiz d\'abord !',
        Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFF2D0058)),
    _GCfg('parcours','Parcours', '🏆', 'Avance case\npar case !',
        'Finis Bingo d\'abord !',
        Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFF7F2006)),
    // ✅ NOUVEAU : Jeu vocal
    _GCfg('vocal',   'Dis le mot !', '🎤', 'Parle et\nle micro valide !',
        'Finis Parcours d\'abord !',
        Color(0xFF006064), Color(0xFF00838F), Color(0xFF004D40)),
    // ✅ NOUVEAU : Jeu de phrases
    _GCfg('phrases', 'Phrases',  '🔀', 'Remets les mots\ndans le bon ordre !',
        'Finis le jeu Vocal d\'abord !',
        Color(0xFF4A148C), Color(0xFF880E4F), Color(0xFF311B92)),
  ];

  static const _xPos = [0.60, 0.10, 0.60, 0.10, 0.60, 0.10];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 850))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    _entryCtrl.forward();

    _sparkCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat();

    _confCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _confAnim = CurvedAnimation(parent: _confCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    final allDone = _games.every(
        (g) => ProgressService().hasCompletedGame(widget.levelData.id, g.type));
    if (allDone) {
      Future.delayed(const Duration(milliseconds: 600),
          () { if (mounted) _confCtrl.forward(); });
    }

    TtsService().speak(widget.levelData.title);
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
    return Scaffold(
      body: Stack(children: [
        _buildBg(),
        AnimatedBuilder(animation: _floatAnim,
            builder: (_, __) => _buildParticles()),
        SafeArea(child: Column(children: [
          _buildHeader(),
          Expanded(
            child: ListenableBuilder(
              listenable: ProgressService(),
              builder: (_, __) {
                final allDone = _games.every(
                    (g) => ProgressService().hasCompletedGame(
                        widget.levelData.id, g.type));
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
                  child: Column(children: [
                    _buildLevelInfo(),
                    const SizedBox(height: 16),

                    // ✅ NOUVEAU : bandeau "Nouveaux jeux de communication"
                    _buildCommunicationBanner(),
                    const SizedBox(height: 16),

                    for (int i = 0; i < _games.length; i++) ...[
                      if (i > 0) _buildConnector(i, size.width),
                      // ✅ Séparateur avant les nouveaux jeux
                      if (i == 4) _buildNewGamesLabel(),
                      _buildNode(i, size.width),
                    ],
                    const SizedBox(height: 20),
                    if (allDone) _buildWin(),
                  ]),
                );
              },
            ),
          ),
        ])),
        AnimatedBuilder(animation: _confAnim,
            builder: (_, __) => _ConfettiWidget(progress: _confAnim.value)),
      ]),
    );
  }

  // ✅ NOUVEAU : bandeau communication
  Widget _buildCommunicationBanner() {
    final vocalDone = ProgressService().hasCompletedGame(widget.levelData.id, 'vocal');
    final phrasesDone = ProgressService().hasCompletedGame(widget.levelData.id, 'phrases');
    if (vocalDone && phrasesDone) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006064), Color(0xFF004D40)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Text('🎤', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nouveaux jeux de communication !',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('Parler et écrire en français avec 2 jeux spéciaux.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
      ]),
    );
  }

  // Label séparateur avant les nouveaux jeux
  Widget _buildNewGamesLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const SizedBox(width: 20),
        Expanded(child: Divider(color: Colors.tealAccent.withOpacity(0.3))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🆕 ', style: TextStyle(fontSize: 12)),
            Text('Communication',
                style: TextStyle(color: Colors.tealAccent, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
        Expanded(child: Divider(color: Colors.tealAccent.withOpacity(0.3))),
        const SizedBox(width: 20),
      ]),
    );
  }

  Widget _buildBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0A0E27), Color(0xFF0D2137), Color(0xFF1A3A5C)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
    ),
    child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: _StarsBg(seed: 77)),
  );

  Widget _buildParticles() => IgnorePointer(child: Stack(children: [
    Positioned(top: 80  + _floatAnim.value * 0.5, right: 24,
        child: const Text('✨', style: TextStyle(fontSize: 16))),
    Positioned(top: 220 - _floatAnim.value * 0.7, left: 16,
        child: const Text('💫', style: TextStyle(fontSize: 13))),
    Positioned(top: 380 + _floatAnim.value * 0.4, right: 40,
        child: const Text('⭐', style: TextStyle(fontSize: 15))),
  ]));

  Widget _buildHeader() {
    final stars = ProgressService().starsFor(widget.levelData.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.levelData.title,
            style: const TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.w900)),
          Text(widget.levelData.getProgression(),
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
            borderRadius: BorderRadius.circular(18),
            border: const Border(bottom: BorderSide(color: Color(0xFFE65100), width: 3)),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.45),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('$stars/3', style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLevelInfo() {
    final done = ProgressService().completedGameCount(widget.levelData.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Center(child: Text('📖', style: const TextStyle(fontSize: 26)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.levelData.description,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.book_outlined, color: Colors.cyan, size: 13),
            const SizedBox(width: 4),
            Text('${widget.levelData.vocabulary.length} mots',
              style: const TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            const Icon(Icons.games_outlined, color: Colors.lime, size: 13),
            const SizedBox(width: 4),
            Text('${_games.length} jeux',
              style: const TextStyle(color: Colors.lime, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / _games.length,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.amber),
            )),
          const SizedBox(height: 3),
          Text('$done / ${_games.length} jeux complétés',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
        ])),
      ]),
    );
  }

  Widget _buildNode(int i, double screenW) {
    final g          = _games[i];
    final isUnlocked = ProgressService().isGameUnlocked(widget.levelData.id, g.type);
    final isDone     = ProgressService().hasCompletedGame(widget.levelData.id, g.type);
    final isActive   = isUnlocked && !isDone;
    final isNew      = g.type == 'vocal' || g.type == 'phrases'; // ✅ badge NEW

    final xFrac = _xPos[i];
    final lPad  = (screenW * xFrac - 70).clamp(12.0, screenW - 165.0);

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Transform.scale(scale: _entryAnim.value, child: child),
      child: Padding(
        padding: EdgeInsets.only(left: lPad),
        child: GestureDetector(
          onTap: () => _onTap(g, isUnlocked),
          child: AnimatedBuilder(
            animation: isActive ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
            builder: (_, child) => Transform.scale(
                scale: isActive ? _pulseAnim.value : 1.0, child: child),
            child: Stack(children: [
              SizedBox(width: 155, child: _GameNodeBody(
                game: g, isUnlocked: isUnlocked,
                isDone: isDone, isActive: isActive, index: i,
              )),
              // ✅ Badge NEW sur les nouveaux jeux
              if (isNew && !isDone)
                Positioned(top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('NOUVEAU',
                        style: TextStyle(color: Colors.black, fontSize: 8,
                            fontWeight: FontWeight.w900)),
                  )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(int idx, double screenW) {
    final prevX = _xPos[idx - 1];
    final currX = _xPos[idx];
    return AnimatedBuilder(
      animation: _sparkCtrl,
      builder: (_, __) => SizedBox(
        width: screenW, height: 56,
        child: CustomPaint(painter: _ConnPainter(
            prevXFrac: prevX, currXFrac: currX,
            progress: _sparkCtrl.value)),
      ),
    );
  }

  Widget _buildWin() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
      borderRadius: BorderRadius.circular(24),
      border: const Border(bottom: BorderSide(color: Color(0xFFE65100), width: 5)),
      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5),
          blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      const Text('🏆', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 6),
      const Text('Niveau terminé !',
          style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text('Tu parles et écris le français ! 🎤✍️',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
    ]),
  );

  void _onTap(_GCfg g, bool unlocked) {
    if (!unlocked) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('🔒 ', style: TextStyle(fontSize: 18)),
          Text(g.lockMsg, style: const TextStyle(fontSize: 13)),
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
      case 'memory':   screen = MemoryGameScreen(levelData: widget.levelData);      break;
      case 'quiz':     screen = QuizGameScreen(levelData: widget.levelData);        break;
      case 'bingo':    screen = BingoGameScreen(levelData: widget.levelData);       break;
      case 'parcours': screen = ParcourGameScreen(levelData: widget.levelData);     break;
      case 'vocal':    screen = VocalGameScreen(levelData: widget.levelData);       break; // ✅
      case 'phrases':  screen = PhraseOrderGameScreen(levelData: widget.levelData); break; // ✅
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
    )).then((_) => setState(() {}));
  }
}

// ─── Corps nœud ─────────────────────────────────────────
class _GameNodeBody extends StatelessWidget {
  final _GCfg game;
  final bool isUnlocked, isDone, isActive;
  final int index;
  const _GameNodeBody({required this.game, required this.isUnlocked,
      required this.isDone, required this.isActive, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = isDone
        ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
        : isActive ? [game.c1, game.c2]
        : [const Color(0xFF1C2633), const Color(0xFF2D3A4A)];
    final slabC = isDone ? const Color(0xFF103A0F)
        : isActive ? game.slab : const Color(0xFF121820);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5),
              blurRadius: 8, offset: const Offset(0, 7)),
          if (isUnlocked)
            BoxShadow(
              color: (isDone ? Colors.green : game.c1).withOpacity(0.4),
              blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors,
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: isActive
                  ? Colors.white.withOpacity(0.88)
                  : Colors.white.withOpacity(0.18),
              width: isActive ? 2.0 : 1.0,
            ),
          ),
          child: Stack(children: [
            Positioned(top: 0, left: 0, right: 0,
              child: Container(height: 20, decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.25), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ))),
            Column(children: [
              Container(width: 28, height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isUnlocked ? 0.22 : 0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.35))),
                child: Center(child: Text('${index + 1}',
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.35),
                    fontSize: 12, fontWeight: FontWeight.w900)))),
              const SizedBox(height: 6),
              Text(isUnlocked ? game.emoji : '🔒',
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 5),
              Text(game.title, textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.35),
                  fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(game.desc, textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUnlocked
                      ? Colors.white.withOpacity(0.72)
                      : Colors.white.withOpacity(0.22),
                  fontSize: 9.5), maxLines: 2),
              const SizedBox(height: 8),
              if (isDone) _chip('✓ Refaire')
              else if (isActive) _playBtn()
              else _chip('🔒'),
            ]),
          ]),
        ),
        Container(height: 5, decoration: BoxDecoration(
          color: slabC,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        )),
      ]),
    );
  }

  Widget _playBtn() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)]),
      borderRadius: BorderRadius.circular(10),
      border: const Border(bottom: BorderSide(color: Color(0xFFE65100), width: 3)),
      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.55),
          blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: const Text('▶ JOUER', style: TextStyle(color: Colors.white,
        fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
  );

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: const TextStyle(color: Colors.white,
        fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

// ─── Connecteur ──────────────────────────────────────────
class _ConnPainter extends CustomPainter {
  final double prevXFrac, currXFrac, progress;
  const _ConnPainter({required this.prevXFrac,
      required this.currXFrac, required this.progress});
  @override
  void paint(Canvas canvas, Size s) {
    final sX = s.width * prevXFrac + 77;
    final eX = s.width * currXFrac + 77;
    final base = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 5 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..strokeWidth = 3 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(sX, 0)
      ..cubicTo(sX, s.height * 0.5, eX, s.height * 0.5, eX, s.height);
    canvas.drawPath(path, base);
    for (final m in path.computeMetrics()) {
      double d = 0; bool draw = true;
      while (d < m.length) {
        final l = draw ? 10.0 : 7.0;
        if (draw) canvas.drawPath(m.extractPath(d, (d + l).clamp(0, m.length)), dot);
        d += l; draw = !draw;
      }
      final pos = m.getTangentForOffset(m.length * progress);
      if (pos != null) {
        canvas.drawCircle(pos.position, 5,
            Paint()..color = Colors.white.withOpacity(0.9));
        canvas.drawCircle(pos.position, 3,
            Paint()..color = Colors.amber..style = PaintingStyle.fill);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _ConnPainter o) => o.progress != progress;
}

class _StarsBg extends CustomPainter {
  final int seed;
  const _StarsBg({required this.seed});
  @override
  void paint(Canvas canvas, Size s) {
    final rng = math.Random(seed);
    for (int i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height),
        rng.nextDouble() * 1.4 + 0.3,
        Paint()..color = Colors.white.withOpacity(0.18 + rng.nextDouble() * 0.4));
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _ConfettiWidget extends StatelessWidget {
  final double progress;
  const _ConfettiWidget({required this.progress});
  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return IgnorePointer(child: CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ConfP(progress: progress),
    ));
  }
}

class _ConfP extends CustomPainter {
  final double progress;
  static const _c = [Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
  const _ConfP({required this.progress});
  @override
  void paint(Canvas canvas, Size s) {
    final rng = math.Random(13);
    for (int i = 0; i < 90; i++) {
      final x = rng.nextDouble() * s.width;
      final y = -20.0 + (s.height + 40) * progress + math.sin(progress * 8 + i) * 38;
      final p = Paint()..color = _c[i % _c.length]
          .withOpacity((1 - progress).clamp(0.0, 1.0));
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
  @override bool shouldRepaint(covariant _ConfP o) => o.progress != progress;
}