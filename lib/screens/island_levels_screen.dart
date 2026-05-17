// lib/screens/island_levels_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../data/cp_levels_data.dart' as cp;
import '../data/ce1_ce2_cm1_cm2_levels_data.dart' as ce;
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'game_selection_screen.dart';

class IslandLevelsScreen extends StatefulWidget {
  final String niveauLabel;
  const IslandLevelsScreen({super.key, required this.niveauLabel});
  @override
  State<IslandLevelsScreen> createState() => _IslandLevelsScreenState();
}

class _IslandLevelsScreenState extends State<IslandLevelsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;
  late final AnimationController _sparkCtrl;

  late List<GameLevelData> _levels;
  late List<Color> _palette;

  // Zigzag : position x (0→1 = gauche→droite)
  static const _zz = [0.55, 0.18, 0.58, 0.15, 0.55, 0.18, 0.58];

  @override
  void initState() {
    super.initState();
    _levels = _getLevels();
    _palette = _getPalette();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _sparkCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _sparkCtrl.dispose();
    super.dispose();
  }

  List<GameLevelData> _getLevels() {
    switch (widget.niveauLabel) {
      case 'CP':
        return cp.CPLevelsProvider.getAllCPLevels();
      case 'CE1':
        return ce.CE1LevelsProvider.getAllCE1Levels();
      case 'CE2':
        return ce.CE2LevelsProvider.getAllCE2Levels();
      case 'CM1':
        return ce.CM1LevelsProvider.getAllCM1Levels();
      case 'CM2':
        return ce.CM2LevelsProvider.getAllCM2Levels();
      default:
        return [];
    }
  }

  List<Color> _getPalette() {
    switch (widget.niveauLabel) {
      case 'CP':
        return [
          const Color(0xFF0D47A1),
          const Color(0xFF1976D2),
          const Color(0xFF42A5F5)
        ];
      case 'CE1':
        return [
          const Color(0xFF1B5E20),
          const Color(0xFF2E7D32),
          const Color(0xFF66BB6A)
        ];
      case 'CE2':
        return [
          const Color(0xFFBF360C),
          const Color(0xFFE64A19),
          const Color(0xFFFF7043)
        ];
      case 'CM1':
        return [
          const Color(0xFF4A148C),
          const Color(0xFF7B1FA2),
          const Color(0xFFCE93D8)
        ];
      case 'CM2':
        return [
          const Color(0xFF7F0000),
          const Color(0xFFD32F2F),
          const Color(0xFFEF9A9A)
        ];
      default:
        return [
          Colors.grey.shade900,
          Colors.grey.shade800,
          Colors.grey.shade700
        ];
    }
  }

  String _getIslandEmoji() {
    switch (widget.niveauLabel) {
      case 'CP':
        return '🌊';
      case 'CE1':
        return '🌿';
      case 'CE2':
        return '🔥';
      case 'CM1':
        return '🌙';
      case 'CM2':
        return '🚀';
      default:
        return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        final earned =
            _levels.fold(0, (s, l) => s + ProgressService().starsFor(l.id));
        final maxStar = _levels.length * 3;
        return Scaffold(
          body: Stack(children: [
            _buildBg(),
            AnimatedBuilder(
                animation: _floatAnim, builder: (_, __) => _buildDecos()),
            SafeArea(
                child: Column(children: [
              _buildHeader(context, earned, maxStar),
              const SizedBox(height: 8),
              Expanded(
                  child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
                child: _buildPath(),
              )),
            ])),
          ]),
        );
      },
    );
  }

  Widget _buildBg() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_palette[0], _palette[1], const Color(0xFF0A1628)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.55, 1],
          ),
        ),
        child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _StarsBg(seed: 42)),
      );

  Widget _buildDecos() => IgnorePointer(
          child: Stack(children: [
        Positioned(
            top: 100 + _floatAnim.value * 0.5,
            right: 28,
            child: const Text('⭐', style: TextStyle(fontSize: 20))),
        Positioned(
            top: 240 - _floatAnim.value * 0.7,
            left: 16,
            child: const Text('💫', style: TextStyle(fontSize: 16))),
        Positioned(
            top: 380 + _floatAnim.value * 0.4,
            right: 44,
            child: const Text('✨', style: TextStyle(fontSize: 18))),
      ]));

  Widget _buildHeader(BuildContext ctx, int earned, int maxStar) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          _glassBtn(
              onTap: () => Navigator.pop(ctx),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(_getIslandEmoji(), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text('Île ${widget.niveauLabel}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 4)
                          ])),
                ]),
                const SizedBox(height: 3),
                ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: maxStar == 0 ? 0 : earned / maxStar,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation(Colors.amber),
                    )),
              ])),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
              borderRadius: BorderRadius.circular(20),
              border: const Border(
                  bottom: BorderSide(color: Color(0xFFE65100), width: 3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('$earned/$maxStar',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ]),
          ),
        ]),
      );

  Widget _glassBtn({required VoidCallback onTap, required Widget child}) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Center(child: child),
          ));

  Widget _buildPath() {
    final screenW = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first)
        .size
        .width;
    return Column(children: [
      for (int i = 0; i < _levels.length; i++) ...[
        if (i > 0) _buildConnector(i, screenW),
        _buildNode(i, screenW),
      ],
      const SizedBox(height: 24),
      if (_levels.every((l) => ProgressService().starsFor(l.id) > 0))
        _buildWin(),
    ]);
  }

  Widget _buildNode(int i, double screenW) {
    final level = _levels[i];
    final stars = ProgressService().starsFor(level.id);
    final unlocked = ProgressService().isUnlocked(level.id);
    final active = unlocked && stars == 0;
    final done = stars > 0;

    final xFrac = i < _zz.length ? _zz[i] : (i % 2 == 0 ? 0.55 : 0.18);
    final lPad = (screenW * xFrac - 70).clamp(12.0, screenW - 152.0);

    return Padding(
      padding: EdgeInsets.only(left: lPad),
      child: GestureDetector(
        onTap: () => _tap(level, unlocked, i),
        child: AnimatedBuilder(
          animation: active ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          builder: (_, child) => Transform.scale(
              scale: active ? _pulseAnim.value : 1.0, child: child),
          child: SizedBox(
              width: 140,
              child: Column(children: [
                // Étoiles au-dessus
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        3,
                        (s) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(s < stars ? '⭐' : '☆',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: s < stars
                                          ? Colors.amber
                                          : Colors.white
                                              .withValues(alpha: 0.25))),
                            ))),
                const SizedBox(height: 5),
                _NodeBody(
                    index: i,
                    level: level,
                    stars: stars,
                    unlocked: unlocked,
                    active: active,
                    done: done,
                    palette: _palette),
              ])),
        ),
      ),
    );
  }

  Widget _buildConnector(int idx, double screenW) {
    final prevX = idx - 1 < _zz.length ? _zz[idx - 1] : 0.4;
    final currX = idx < _zz.length ? _zz[idx] : 0.4;
    return AnimatedBuilder(
      animation: _sparkCtrl,
      builder: (_, __) => SizedBox(
        width: screenW,
        height: 60,
        child: CustomPaint(
            painter: _PathPainter(
                prevXFrac: prevX,
                currXFrac: currX,
                progress: _sparkCtrl.value)),
      ),
    );
  }

  Widget _buildWin() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
          borderRadius: BorderRadius.circular(24),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFE65100), width: 5)),
          boxShadow: [
            BoxShadow(
                color: Colors.amber.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(children: [
          const Text('🏆', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text('Île ${widget.niveauLabel} terminée !',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Retourne à la carte du monde !',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      );

  void _tap(GameLevelData level, bool unlocked, int idx) {
    if (!unlocked) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('🔒 ', style: TextStyle(fontSize: 18)),
          Expanded(
              child: Text(
                  idx > 0
                      ? 'Termine "${_levels[idx - 1].title}" d\'abord !'
                      : 'Niveau verrouillé.',
                  style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: const Color(0xFF212121),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    TtsService().speak(level.title);
    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => GameSelectionScreen(levelData: level),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
                    .animate(
                        CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: a, child: child),
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ));
  }
}

// ─── Corps du nœud ───────────────────────────────────────
class _NodeBody extends StatelessWidget {
  final int index;
  final GameLevelData level;
  final int stars;
  final bool unlocked, active, done;
  final List<Color> palette;
  const _NodeBody(
      {required this.index,
      required this.level,
      required this.stars,
      required this.unlocked,
      required this.active,
      required this.done,
      required this.palette});

  String _emoji() {
    if (!unlocked) return '🔒';
    if (stars == 3) return '🏆';
    final t = (level.theme ?? '').toLowerCase();
    if (t.contains('alpha')) return '🔤';
    if (t.contains('number') || t.contains('chiffre')) return '🔢';
    if (t.contains('color') || t.contains('couleur')) return '🎨';
    if (t.contains('animal')) return '🐾';
    if (t.contains('météo')) return '⛅';
    if (t.contains('famille')) return '👨‍👩‍👧';
    if (t.contains('émotion')) return '😊';
    if (t.contains('métier')) return '👷';
    return '📖';
  }

  @override
  Widget build(BuildContext context) {
    final grad = done
        ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
        : active
            ? [palette[0], palette[2]]
            : [const Color(0xFF263238), const Color(0xFF37474F)];
    final glow = done
        ? Colors.green
        : active
            ? palette[1]
            : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 7)),
          if (unlocked)
            BoxShadow(
                color: glow.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.18),
            width: active ? 2.5 : 1,
          ),
        ),
        child: Stack(children: [
          // Reflet 3D
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.transparent
                    ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                  ))),
          Column(children: [
            // Badge numéro
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: unlocked ? 0.22 : 0.08),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35))),
              child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: unlocked
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                          fontWeight: FontWeight.w900))),
            ),
            const SizedBox(height: 6),
            Text(_emoji(), style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 5),
            Text(unlocked ? level.title : '???',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: unlocked
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 7),
            if (active) _PlayBtn() else if (done) _DoneChip() else _LockChip(),
          ]),
        ]),
      ),
    );
  }
}

class _PlayBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)]),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFE65100), width: 3)),
          boxShadow: [
            BoxShadow(
                color: Colors.amber.withValues(alpha: 0.55),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: const Text('▶  JOUER',
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4)),
      );
}

class _DoneChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10)),
        child: const Text('✓ Rejouer',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
}

class _LockChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Text('🔒', style: TextStyle(fontSize: 22));
}

// ─── Connecteur chemin ────────────────────────────────────
class _PathPainter extends CustomPainter {
  final double prevXFrac, currXFrac, progress;
  const _PathPainter(
      {required this.prevXFrac,
      required this.currXFrac,
      required this.progress});
  @override
  void paint(Canvas canvas, Size s) {
    final sX = s.width * prevXFrac + 70;
    final eX = s.width * currXFrac + 70;
    final base = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = Colors.amber.withValues(alpha: 0.65)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(sX, 0)
      ..cubicTo(sX, s.height * 0.5, eX, s.height * 0.5, eX, s.height);
    canvas.drawPath(path, base);
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final l = draw ? 10.0 : 7.0;
        if (draw)
          canvas.drawPath(m.extractPath(d, (d + l).clamp(0, m.length)), dot);
        d += l;
        draw = !draw;
      }
      final pos = m.getTangentForOffset(m.length * progress);
      if (pos != null) {
        canvas.drawCircle(pos.position, 5,
            Paint()..color = Colors.white.withValues(alpha: 0.9));
        canvas.drawCircle(
            pos.position,
            3,
            Paint()
              ..color = Colors.amber
              ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter o) => o.progress != progress;
}

class _StarsBg extends CustomPainter {
  final int seed;
  const _StarsBg({required this.seed});
  @override
  void paint(Canvas canvas, Size s) {
    final rng = math.Random(seed);
    for (int i = 0; i < 70; i++) {
      canvas.drawCircle(
          Offset(
              rng.nextDouble() * s.width, rng.nextDouble() * s.height * 0.55),
          rng.nextDouble() * 1.5 + 0.4,
          Paint()
            ..color =
                Colors.white.withValues(alpha: 0.18 + rng.nextDouble() * 0.45));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
