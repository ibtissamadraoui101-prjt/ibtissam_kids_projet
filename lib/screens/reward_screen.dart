// lib/screens/reward_screen.dart
// ═══════════════════════════════════════════════════════════
// LinguaKids — Écran Récompense
// Célébration après chaque mini-jeu réussi
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../services/progress_service.dart';
import '../widgets/lumi_mascot.dart';
import '../widgets/lk_widgets.dart';
import 'island_screen.dart';
import 'world_map_screen.dart';

class RewardScreen extends StatefulWidget {
  final int score;
  final int maxScore;
  final String gameTitle;
  final String islandId;
  final IslandTheme theme;
  final String? nextGameKey;

  const RewardScreen({
    super.key,
    required this.score,
    required this.maxScore,
    required this.gameTitle,
    required this.islandId,
    required this.theme,
    this.nextGameKey,
  });

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _confettiCtrl;

  late Animation<double> _entranceAnim;
  late Animation<double> _starsAnim;

  int _starsShown = 0;
  bool _nextGameUnlocked = false;
  String _nextUnlockedName = '';

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _starsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
    _confettiCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))..repeat();

    _entranceAnim = CurvedAnimation(
      parent: _entranceCtrl, curve: Curves.easeOutBack);
    _starsAnim = CurvedAnimation(
      parent: _starsCtrl, curve: Curves.easeInOut);

    _entranceCtrl.forward();

    // Animate stars one by one
    Future.delayed(const Duration(milliseconds: 500), () {
      _showStarByOne();
    });

    _checkNextUnlock();
  }

  int get _starsEarned {
    final p = widget.score / widget.maxScore;
    if (p >= 0.8) return 3;
    if (p >= 0.5) return 2;
    return 1;
  }

  void _showStarByOne() {
    for (int i = 1; i <= _starsEarned; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        if (mounted) {
          setState(() => _starsShown = i);
          HapticFeedback.lightImpact();
        }
      });
    }
  }

  void _checkNextUnlock() {
    final ps = ProgressService();
    // Check if any new game is now unlocked
    final gameOrder = ['listening', 'letter_recognition',
        'sound_matching', 'memory', 'word_builder'];
    final gameNames = ['Écoute', 'Lettres', 'Sons Pareils',
        'Mémoire', 'Construction'];
    for (int i = 0; i < gameOrder.length; i++) {
      final key = gameOrder[i];
      final prevKey = i > 0 ? gameOrder[i - 1] : null;
      if (prevKey != null &&
          ps.hasCompletedGame(widget.islandId, prevKey) &&
          !ps.hasCompletedGame(widget.islandId, key)) {
        setState(() {
          _nextGameUnlocked = true;
          _nextUnlockedName = gameNames[i];
        });
        break;
      }
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _starsCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.maxScore * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3DE),
      body: Stack(children: [
        // Confetti background
        _buildConfetti(),

        SafeArea(
          child: Column(children: [
            // Rainbow strip top
            const RainbowStrip(height: 8),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: ScaleTransition(
                  scale: _entranceAnim,
                  child: Column(children: [
                    // Lumi celebrating
                    LumiMascot(
                      mood: _starsEarned >= 2
                        ? LumiMood.celebrate : LumiMood.encourage,
                      size: 70,
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      _starsEarned == 3 ? 'PARFAIT ! 🎉'
                      : _starsEarned == 2 ? 'BRAVO ! ⭐'
                      : 'BIEN ESSAYÉ ! 💪',
                      style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900,
                        color: Color(0xFF27500A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.gameTitle,
                      style: const TextStyle(
                        fontSize: 14, color: Color(0xFF3B6D11),
                        fontWeight: FontWeight.w600,
                      )),
                    const SizedBox(height: 16),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final show = i < _starsShown;
                        return AnimatedScale(
                          scale: show ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.star_rounded,
                              size: i == 1 ? 56 : 46,
                              color: show ? LKColors.star : LKColors.starEmpty,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_starsEarned == 3)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('3 étoiles parfaites !',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800,
                            color: LKColors.sunDark,
                          )),
                      ),
                    const SizedBox(height: 20),

                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: [
                        _statCard('${widget.score}/${widget.maxScore}',
                            'Réponses', LKColors.bgBlueLight, LKColors.island2Blue,
                            LKColors.textOnBlue),
                        _statCard('+${widget.score * 3} XP',
                            'Points gagnés', LKColors.correctLight, LKColors.correct,
                            LKColors.textOnGreen),
                        _statCard('$percentage%',
                            'Réussite', LKColors.bgYellowLight, LKColors.sun,
                            LKColors.textOnYellow),
                        if (_nextGameUnlocked)
                          _statCard('🔓 $_nextUnlockedName',
                              'Débloqué !', LKColors.wrongLight, LKColors.wrong,
                              const Color(0xFF993556))
                        else
                          _statCard('⭐ ${ _starsEarned * 3}',
                              'Étoiles totales', const Color(0xFFFFF0EB),
                              const Color(0xFFFF8C6B), const Color(0xFF5A1800)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lumi message
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: LKColors.correct, width: 2.5),
                      ),
                      child: Row(children: [
                        const Text('✨', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          _starsEarned == 3
                            ? 'Lumi est incroyablement fier de toi ! Tu es un champion ! 🦋'
                            : _starsEarned == 2
                            ? 'Lumi dit : très bien ! Continue et tu auras 3 étoiles ! 🌟'
                            : 'Lumi dit : ne lâche pas ! Chaque essai te rend plus fort ! 💪',
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: LKColors.textOnGreen, height: 1.4,
                          ),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    LKButton.primary(
                      '🚀 Jeu suivant !',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    LKButton.outline(
                      '🗺️ Retour à la carte',
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const WorldMapScreen()),
                          (r) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statCard(String value, String label,
      Color bg, Color border, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          fontSize: 10, color: textColor.withOpacity(0.7),
          fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiCtrl,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiAnimPainter(_confettiCtrl.value),
        size: Size.infinite,
      ),
    );
  }
}

// ── Confetti Painter ─────────────────────────────────────────
class _ConfettiAnimPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _dots = List.generate(24, (i) => (
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    color: LKColors.rainbow[i % LKColors.rainbow.length],
    size: 4.0 + _rng.nextDouble() * 6,
    speed: 0.15 + _rng.nextDouble() * 0.25,
  ));

  _ConfettiAnimPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      final y = (d.y + t * d.speed) % 1.0;
      final x = d.x + sin(t * 3 + d.y * 10) * 0.03;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        d.size,
        Paint()..color = d.color.withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiAnimPainter old) => true;
}