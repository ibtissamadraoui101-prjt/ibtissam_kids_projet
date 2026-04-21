// lib/screens/island_levels_screen.dart
import 'package:flutter/material.dart';
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
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late List<GameLevelData> _levels;
  late Color _islandColor;

  @override
  void initState() {
    super.initState();
    _levels = _getLevels();
    _islandColor = _getColor();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
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

  Color _getColor() {
    switch (widget.niveauLabel) {
      case 'CP':  return const Color(0xFF1565C0);
      case 'CE1': return const Color(0xFF2E7D32);
      case 'CE2': return const Color(0xFFE65100);
      case 'CM1': return const Color(0xFF6A1B9A);
      case 'CM2': return const Color(0xFFC62828);
      default:    return Colors.grey;
    }
  }

  String _getEmoji() {
    switch (widget.niveauLabel) {
      case 'CP':  return '🌱';
      case 'CE1': return '🌿';
      case 'CE2': return '🌳';
      case 'CM1': return '🦋';
      case 'CM2': return '🚀';
      default:    return '🏝️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _islandColor.withOpacity(0.9),
                  const Color(0xFF0D47A1),
                  const Color(0xFF1565C0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Étoiles décoratives (déclarées dans ce fichier)
                const _IslandStarField(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(child: _buildMap()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final earnedHere = _levels.fold(
      0,
      (sum, l) => sum + ProgressService().starsFor(l.id),
    );
    final maxHere = _levels.length * 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_getEmoji()} Île ${widget.niveauLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 15),
                const SizedBox(width: 4),
                Text(
                  '$earnedHere / $maxHere',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          // Bandeau d'instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Complète les niveaux dans l\'ordre pour avancer !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Îles en zigzag
          ..._buildZigzagPath(),
          const SizedBox(height: 24),
          // Bannière de fin si tout est terminé
          if (_levels.every((l) => ProgressService().starsFor(l.id) > 0))
            _buildCompletionBanner(),
        ],
      ),
    );
  }

  List<Widget> _buildZigzagPath() {
    final widgets = <Widget>[];

    for (int i = 0; i < _levels.length; i++) {
      final level = _levels[i];
      final stars = ProgressService().starsFor(level.id);
      final isUnlocked = ProgressService().isUnlocked(level.id);
      final isActive = isUnlocked && stars == 0;
      // Alterner gauche/droite pour le zigzag
      final isLeft = i % 2 == 0;

      // Connecteur entre 2 îles (sauf pour la première)
      if (i > 0) {
        widgets.add(_buildConnector(goRight: isLeft));
      }

      // Île du niveau — alignée à gauche ou à droite
      widgets.add(
        Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, isActive ? _bounceAnim.value : 0),
              child: _LevelIsland(
                level: level,
                stars: stars,
                isUnlocked: isUnlocked,
                isActive: isActive,
                islandColor: _islandColor,
                index: i,
                onTap: () => _onLevelTap(level, isUnlocked, i),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  // ── CORRECTION : MainAxisAlignment.start / .end (pas centerLeft) ──
  Widget _buildConnector({required bool goRight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            goRight ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 160,
            height: 54,
            child: CustomPaint(
              painter: _ConnectorPainter(goRight: goRight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            'Île ${widget.niveauLabel} complétée !',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Retourne à la carte pour continuer !',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _onLevelTap(GameLevelData level, bool isUnlocked, int levelIndex) {
    if (!isUnlocked) {
      final prevLevel = levelIndex > 0 ? _levels[levelIndex - 1] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🔒 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  prevLevel != null
                      ? 'Termine "${prevLevel.title}" d\'abord !'
                      : 'Ce niveau est verrouillé.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey[850],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    TtsService().speak(level.title);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => GameSelectionScreen(levelData: level),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widget île d'un niveau
// ─────────────────────────────────────────────────────────────
class _LevelIsland extends StatelessWidget {
  final GameLevelData level;
  final int stars;
  final bool isUnlocked;
  final bool isActive;
  final Color islandColor;
  final int index;
  final VoidCallback onTap;

  const _LevelIsland({
    required this.level,
    required this.stars,
    required this.isUnlocked,
    required this.isActive,
    required this.islandColor,
    required this.index,
    required this.onTap,
  });

  String get _emoji {
    if (!isUnlocked) return '🔒';
    if (stars == 3) return '🏆';
    if (stars == 2) return '😊';
    if (stars == 1) return '👍';
    return _themeEmoji();
  }

  String _themeEmoji() {
    final t = (level.theme ?? '').toLowerCase();
    if (t.contains('alpha'))   return '🔤';
    if (t.contains('chiffre')) return '🔢';
    if (t.contains('couleur')) return '🎨';
    if (t.contains('salut'))   return '👋';
    if (t.contains('animal'))  return '🐾';
    if (t.contains('nourrit') || t.contains('food')) return '🍎';
    if (t.contains('famille')) return '👨‍👩‍👧';
    if (t.contains('météo'))   return '⛅';
    if (t.contains('école'))   return '🎒';
    if (t.contains('maison'))  return '🏠';
    if (t.contains('verbe'))   return '✍️';
    if (t.contains('descri'))  return '🪞';
    if (t.contains('émotion')) return '😊';
    if (t.contains('métier'))  return '👷';
    if (t.contains('passé'))   return '⏮️';
    if (t.contains('futur'))   return '⏭️';
    if (t.contains('express')) return '💬';
    return '📖';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 155,
        child: Column(
          children: [
            // Étoiles au-dessus de l'île
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars
                        ? Colors.amber
                        : Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Corps de l'île
            Container(
              width: 145,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: !isUnlocked
                      ? [const Color(0xFF1C2833), const Color(0xFF2C3E50)]
                      : stars > 0
                          ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
                          : [islandColor, islandColor.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.2),
                  width: isActive ? 2.5 : 1,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: (isActive ? Colors.white : islandColor)
                              .withOpacity(0.4),
                          blurRadius: isActive ? 20 : 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(
                    level.getProgression(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '▶  JOUER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else if (isUnlocked && stars > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔄 Rejouer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Connecteur chemin entre 2 îles
// ─────────────────────────────────────────────────────────────
class _ConnectorPainter extends CustomPainter {
  final bool goRight;
  const _ConnectorPainter({required this.goRight});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (goRight) {
      path.moveTo(30, 0);
      path.cubicTo(30, size.height * 0.5,
          size.width - 30, size.height * 0.5,
          size.width - 30, size.height);
    } else {
      path.moveTo(size.width - 30, 0);
      path.cubicTo(size.width - 30, size.height * 0.5,
          30, size.height * 0.5,
          30, size.height);
    }

    canvas.drawPath(path, basePaint);
    _drawDashes(canvas, path, dotPaint);
  }

  void _drawDashes(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? 9.0 : 6.0;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(dist, (dist + len).clamp(0, metric.length)),
            paint,
          );
        }
        dist += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
// Étoiles décoratives — version locale (pas privée à world_map)
// CORRECTION : renommée _IslandStarField pour éviter le conflit
// ─────────────────────────────────────────────────────────────
class _IslandStarField extends StatelessWidget {
  const _IslandStarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _IslandStarPainter(),
    );
  }
}

class _IslandStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    // 30 étoiles réparties sur tout l'écran
    final positions = [
      [0.04, 0.05], [0.14, 0.02], [0.25, 0.08], [0.38, 0.03],
      [0.50, 0.06], [0.63, 0.01], [0.75, 0.07], [0.87, 0.04],
      [0.94, 0.09], [0.07, 0.15], [0.19, 0.19], [0.31, 0.13],
      [0.44, 0.18], [0.56, 0.12], [0.68, 0.17], [0.80, 0.11],
      [0.92, 0.16], [0.02, 0.25], [0.13, 0.29], [0.24, 0.23],
      [0.36, 0.28], [0.48, 0.22], [0.60, 0.27], [0.72, 0.21],
      [0.84, 0.26], [0.96, 0.24], [0.09, 0.35], [0.21, 0.38],
      [0.33, 0.33], [0.45, 0.37],
    ];
    for (final p in positions) {
      canvas.drawCircle(
        Offset(size.width * p[0], size.height * p[1]),
        1.4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}