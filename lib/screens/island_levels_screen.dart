// lib/screens/island_levels_screen.dart
// 🎮 CANDY CRUSH STYLE — nœuds circulaires, chemin zigzag, boutons 3D brillants

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../data/cp_levels_data.dart';
import '../data/ce1_ce2_cm1_cm2_levels_data.dart';
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
  late final Animation<double>   _pulseAnim;
  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatAnim;
  late final AnimationController _sparkCtrl;

  late List<GameLevelData> _levels;
  late List<Color> _palette;

  // Positions zigzag des nœuds (x normalisé 0→1)
  static const _zigzag = [0.55, 0.25, 0.60, 0.20, 0.55, 0.25, 0.60];

  @override
  void initState() {
    super.initState();
    _levels  = _getLevels();
    _palette = _getPalette();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _sparkCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
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
      case 'CP':  return CPLevelsProvider.getAllCPLevels();
      case 'CE1': return CE1LevelsProvider.getAllCE1Levels();
      case 'CE2': return CE2LevelsProvider.getAllCE2Levels();
      case 'CM1': return CM1LevelsProvider.getAllCM1Levels();
      case 'CM2': return CM2LevelsProvider.getAllCM2Levels();
      default:    return [];
    }
  }

  List<Color> _getPalette() {
    switch (widget.niveauLabel) {
      case 'CP':  return [const Color(0xFF0D47A1), const Color(0xFF1565C0), const Color(0xFF1976D2)];
      case 'CE1': return [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF388E3C)];
      case 'CE2': return [const Color(0xFFBF360C), const Color(0xFFD84315), const Color(0xFFE64A19)];
      case 'CM1': return [const Color(0xFF4A148C), const Color(0xFF6A1B9A), const Color(0xFF7B1FA2)];
      case 'CM2': return [const Color(0xFF7F0000), const Color(0xFFC62828), const Color(0xFFD32F2F)];
      default:    return [Colors.grey.shade900, Colors.grey.shade800, Colors.grey.shade700];
    }
  }

  String _getEmoji() {
    switch (widget.niveauLabel) {
      case 'CP':  return '🌊';
      case 'CE1': return '🌿';
      case 'CE2': return '🔥';
      case 'CM1': return '🌙';
      case 'CM2': return '🚀';
      default:    return '⭐';
    }
  }

  Color get _mainColor => _palette[1];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (_, __) {
        final earned = _levels.fold(0, (s, l) => s + ProgressService().starsFor(l.id));
        final maxStars = _levels.length * 3;

        return Scaffold(
          body: Stack(children: [
            // ── Fond en couches ──────────────────────────────
            _buildBackground(),

            // ── Décorations flottantes ───────────────────────
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => _buildFloatingDecos(),
            ),

            SafeArea(
              child: Column(children: [
                // ── Header ───────────────────────────────────
                _buildHeader(context, earned, maxStars),
                const SizedBox(height: 8),

                // ── Carte des niveaux ─────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
                    child: _buildLevelPath(),
                  ),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  // ─── Fond ────────────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_palette[0], _palette[1], const Color(0xFF0A1628)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(children: [
        // Nuages décoratifs
        Positioned(top: 60,  left: -20, child: _cloud(140, 0.12)),
        Positioned(top: 160, right: -10, child: _cloud(100, 0.08)),
        Positioned(top: 300, left: 20,  child: _cloud(120, 0.10)),
        // Points lumineux de fond
        CustomPaint(size: Size.infinite, painter: _StarfieldPainter()),
      ]),
    );
  }

  Widget _cloud(double w, double opacity) => Container(
    width: w, height: w * 0.45,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(w),
    ),
  );

  // ─── Décorations flottantes ──────────────────────────────
  Widget _buildFloatingDecos() {
    final floatOffset = _floatAnim.value;
    return IgnorePointer(
      child: Stack(children: [
        Positioned(top: 100 + floatOffset * 0.5, right: 30,
            child: const Text('⭐', style: TextStyle(fontSize: 22))),
        Positioned(top: 240 - floatOffset * 0.7, left: 18,
            child: const Text('💫', style: TextStyle(fontSize: 18))),
        Positioned(top: 380 + floatOffset * 0.4, right: 45,
            child: const Text('✨', style: TextStyle(fontSize: 20))),
        Positioned(top: 500 - floatOffset * 0.6, left: 30,
            child: const Text('🌟', style: TextStyle(fontSize: 16))),
      ]),
    );
  }

  // ─── Header ──────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx, int earned, int maxStars) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        // Bouton retour
        _glassBtn(
          onTap: () => Navigator.pop(ctx),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        // Titre île
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_getEmoji(), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text('Île ${widget.niveauLabel}',
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)])),
            ]),
            const SizedBox(height: 2),
            // Barre progression
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maxStars == 0 ? 0 : earned / maxStars,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        // Étoiles total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text('$earned/$maxStars',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  Widget _glassBtn({required VoidCallback onTap, required Widget child}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Center(child: child),
        ),
      );

  // ─── Chemin de niveaux ────────────────────────────────────
  Widget _buildLevelPath() {
    // Calcul de la largeur disponible
    final screenW = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first).size.width;

    return Column(children: [
      for (int i = 0; i < _levels.length; i++) ...[
        // ── Connecteur entre nœuds ──
        if (i > 0) _buildConnector(i, screenW),
        // ── Nœud du niveau ──
        _buildLevelNode(i, screenW),
      ],
      const SizedBox(height: 20),
      // Bannière fin si tout complété
      if (_levels.every((l) => ProgressService().starsFor(l.id) > 0))
        _buildVictoryBanner(),
    ]);
  }

  // ─── Nœud circulaire Candy Crush ─────────────────────────
  Widget _buildLevelNode(int i, double screenW) {
    final level     = _levels[i];
    final stars     = ProgressService().starsFor(level.id);
    final unlocked  = ProgressService().isUnlocked(level.id);
    final isActive  = unlocked && stars == 0;
    final isComplete = stars > 0;

    // Position horizontale zigzag
    final xFrac = i < _zigzag.length ? _zigzag[i] : (i % 2 == 0 ? 0.55 : 0.25);
    final leftPad = screenW * xFrac - 70;

    return Padding(
      padding: EdgeInsets.only(left: leftPad.clamp(12.0, screenW - 152.0)),
      child: GestureDetector(
        onTap: () => _onNodeTap(level, unlocked, i),
        child: AnimatedBuilder(
          animation: isActive ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          builder: (_, child) => Transform.scale(
            scale: isActive ? _pulseAnim.value : 1.0,
            child: child,
          ),
          child: SizedBox(
            width: 140,
            child: Column(children: [
              // ── Étoiles au-dessus ──
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (int s = 0; s < 3; s++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      s < stars ? '⭐' : '☆',
                      style: TextStyle(fontSize: 16,
                          color: s < stars ? Colors.amber : Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
              ]),
              const SizedBox(height: 5),

              // ── Corps du nœud 3D ──
              _buildNodeBody(i, level, stars, unlocked, isActive, isComplete),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeBody(int i, GameLevelData level, int stars,
      bool unlocked, bool isActive, bool isComplete) {

    // Couleurs selon état
    final List<Color> gradient;
    final Color glow;
    if (!unlocked) {
      gradient = [const Color(0xFF263238), const Color(0xFF37474F)];
      glow     = Colors.transparent;
    } else if (isComplete) {
      gradient = [const Color(0xFF1B5E20), const Color(0xFF43A047)];
      glow     = Colors.green;
    } else if (isActive) {
      gradient = [_palette[1], _palette[2]];
      glow     = _mainColor;
    } else {
      gradient = [_palette[0], _palette[1]];
      glow     = _mainColor.withValues(alpha: 0.3);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Ombre profonde (effet 3D)
          BoxShadow(color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8, offset: const Offset(0, 6)),
          // Halo couleur
          if (unlocked)
            BoxShadow(color: glow.withValues(alpha: 0.45),
                blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.2),
            width: isActive ? 2.5 : 1,
          ),
        ),
        child: Stack(children: [
          // ── Reflet blanc en haut (effet 3D brillant) ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          // ── Contenu ──
          Column(children: [
            // Numéro du niveau
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: unlocked ? 0.25 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text('${i + 1}',
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.4),
                    fontSize: 15, fontWeight: FontWeight.w900,
                  )),
              ),
            ),
            const SizedBox(height: 6),
            // Emoji thème
            Text(_getLevelEmoji(level, stars, unlocked),
                style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 5),
            // Titre
            Text(
              unlocked ? level.title : '???',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.35),
                fontSize: 11, fontWeight: FontWeight.bold,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Bouton JOUER ou état
            if (isActive)
              _playButton()
            else if (isComplete)
              _doneChip()
            else if (!unlocked)
              _lockChip(),
          ]),
        ]),
      ),
    );
  }

  Widget _playButton() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)]),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.6),
          blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: const Text('▶  JOUER',
      style: TextStyle(color: Colors.white, fontSize: 11,
          fontWeight: FontWeight.w900, letterSpacing: 1.5)),
  );

  Widget _doneChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text('✓ Rejouer',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _lockChip() => const Text('🔒',
      style: TextStyle(fontSize: 22));

  // ─── Connecteur entre nœuds ──────────────────────────────
  Widget _buildConnector(int nodeIndex, double screenW) {
    final prevX = nodeIndex - 1 < _zigzag.length ? _zigzag[nodeIndex - 1] : 0.4;
    final currX = nodeIndex     < _zigzag.length ? _zigzag[nodeIndex]     : 0.4;
    final goRight = currX > prevX;

    return AnimatedBuilder(
      animation: _sparkCtrl,
      builder: (_, __) => SizedBox(
        width: screenW,
        height: 60,
        child: CustomPaint(
          painter: _PathConnectorPainter(
            goRight: goRight,
            prevXFrac: prevX,
            currXFrac: currX,
            progress: _sparkCtrl.value,
          ),
        ),
      ),
    );
  }

  // ─── Bannière victoire ────────────────────────────────────
  Widget _buildVictoryBanner() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)]),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5),
          blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      const Text('🏆', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 8),
      Text('Île ${widget.niveauLabel} terminée !',
        style: const TextStyle(color: Colors.white, fontSize: 20,
            fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('Retourne à la carte du monde !',
          style: TextStyle(color: Colors.white70, fontSize: 13)),
    ]),
  );

  // ─── Tap sur un nœud ─────────────────────────────────────
  void _onNodeTap(GameLevelData level, bool unlocked, int idx) {
    if (!unlocked) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('🔒 ', style: TextStyle(fontSize: 18)),
          Expanded(child: Text(
            idx > 0 ? 'Termine "${_levels[idx - 1].title}" d\'abord !' : 'Niveau verrouillé.',
            style: const TextStyle(fontSize: 13),
          )),
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
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => GameSelectionScreen(levelData: level),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: a, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  String _getLevelEmoji(GameLevelData l, int stars, bool unlocked) {
    if (!unlocked) return '🔒';
    if (stars == 3) return '🏆';
    final t = (l.theme ?? '').toLowerCase();
    if (t.contains('alpha'))  return '🔤';
    if (t.contains('chiffre') || t.contains('number')) return '🔢';
    if (t.contains('couleur') || t.contains('color'))  return '🎨';
    if (t.contains('salut') || t.contains('greet'))    return '👋';
    if (t.contains('animal'))  return '🐾';
    if (t.contains('nourrit') || t.contains('food'))   return '🍎';
    if (t.contains('famille')) return '👨‍👩‍👧';
    if (t.contains('météo'))   return '⛅';
    if (t.contains('école'))   return '🎒';
    if (t.contains('maison'))  return '🏠';
    if (t.contains('verbe'))   return '✍️';
    if (t.contains('émotion')) return '😊';
    if (t.contains('métier'))  return '👷';
    if (t.contains('passé'))   return '⏮️';
    if (t.contains('futur'))   return '⏭️';
    return '📖';
  }
}

// ─── Peintre du chemin animé ─────────────────────────────
class _PathConnectorPainter extends CustomPainter {
  final bool goRight;
  final double prevXFrac, currXFrac, progress;
  const _PathConnectorPainter({
    required this.goRight, required this.prevXFrac,
    required this.currXFrac, required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startX = size.width * prevXFrac + 0;
    final endX   = size.width * currXFrac + 0;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sparkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Chemin courbe
    final path = Path()
      ..moveTo(startX + 70, 0)
      ..cubicTo(startX + 70, size.height * 0.5,
                endX + 70,   size.height * 0.5,
                endX + 70,   size.height);

    canvas.drawPath(path, basePaint);
    _drawDots(canvas, path, dotPaint);

    // Point lumineux animé qui se déplace sur le chemin
    for (final metric in path.computeMetrics()) {
      final pos = metric.getTangentForOffset(metric.length * progress);
      if (pos != null) {
        canvas.drawCircle(pos.position, 5, sparkPaint);
        canvas.drawCircle(pos.position, 3,
            Paint()..color = Colors.amber..style = PaintingStyle.fill);
      }
    }
  }

  void _drawDots(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final len = draw ? 10.0 : 7.0;
        if (draw) {
          canvas.drawPath(
            m.extractPath(d, (d + len).clamp(0, m.length)), paint);
        }
        d += len; draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathConnectorPainter o) => o.progress != progress;
}

// ─── Fond étoilé ─────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.5),
        rng.nextDouble() * 1.5 + 0.5, p,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}