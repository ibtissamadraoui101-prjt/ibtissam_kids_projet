// lib/screens/daily_mission_screen.dart
// ═══════════════════════════════════════════════════════════
// LinguaKids — Écran Mission du Jour
// Affiche les 3 lettres à sauver aujourd'hui
// Design immersif, visuel only, Lumi guide
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/lumi_mascot.dart';
import '../services/progress_service.dart';
import 'games/letter_discovery_screen.dart';

class DailyMissionScreen extends StatefulWidget {
  final String islandId;
  final List<String> todayLetters; // ex: ['A','B','C']
  final int dayNumber;

  const DailyMissionScreen({
    super.key,
    required this.islandId,
    required this.todayLetters,
    required this.dayNumber,
  });

  @override
  State<DailyMissionScreen> createState() => _DailyMissionScreenState();
}

class _DailyMissionScreenState extends State<DailyMissionScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _lumiCtrl;

  late Animation<double> _entranceAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _lumiFloat;

  // Couleurs des lettres
  static const _letterColors = [
    Color(0xFFFFD93D), // A - jaune
    Color(0xFFFF8C9E), // B - rose
    Color(0xFF85DAFF), // C - bleu
  ];
  static const _letterDarkColors = [
    Color(0xFFFFA000),
    Color(0xFFD4537E),
    Color(0xFF378ADD),
  ];

  // Progression des jeux pour ce groupe de lettres
  List<bool> _gamesDone = [false, false, false, false];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _floatCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..repeat(reverse: true);
    _lumiCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

    _entranceAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack);
    _floatAnim    = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulseAnim    = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _lumiFloat    = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _lumiCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final ps = ProgressService();
    setState(() {
      _gamesDone = [
        ps.hasCompletedGame(widget.islandId, 'discovery_${widget.dayNumber}'),
        ps.hasCompletedGame(widget.islandId, 'recognition_${widget.dayNumber}'),
        ps.hasCompletedGame(widget.islandId, 'memory_${widget.dayNumber}'),
        ps.hasCompletedGame(widget.islandId, 'writing_${widget.dayNumber}'),
      ];
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _lumiCtrl.dispose();
    super.dispose();
  }

  int get _completedCount => _gamesDone.where((d) => d).length;
  bool get _allDone => _gamesDone.every((d) => d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1B6FA8), Color(0xFF42B8E0), Color(0xFF87CEEB), Color(0xFFC8F5FF)],
            stops: [0.0, 0.30, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            // Déco de fond
            _buildBackgroundDecos(),
            // Contenu principal
            Column(children: [
              _buildTopBar(),
              Expanded(
                child: ScaleTransition(
                  scale: _entranceAnim,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(children: [
                      _buildMissionCard(),
                      const SizedBox(height: 20),
                      _buildLettersDisplay(),
                      const SizedBox(height: 20),
                      _buildGamesProgress(),
                      const SizedBox(height: 24),
                      _buildStartButton(),
                    ]),
                  ),
                ),
              ),
              _buildLumiStrip(),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecos() {
    return Stack(children: [
      Positioned(top: 30, right: 20,
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFFFFF176), Color(0xFFFFD93D)]),
            border: Border.all(color: const Color(0xFFFFA000), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.5), blurRadius: 14)]),
          child: const Center(child: Text('☀', style: TextStyle(fontSize: 20))),
        ),
      ),
      // Petits nuages
      Positioned(top: 18, left: 16,
        child: Opacity(opacity: 0.7, child: Container(
          width: 60, height: 20,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        )),
      ),
    ]);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
            child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          ),
        ),
        const Spacer(),
        // Badge jour
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFA000), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.45), blurRadius: 10)]),
          child: Text('Jour ${widget.dayNumber} 📅',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF7A3800))),
        ),
        const Spacer(),
        // Progression
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5DCAA5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3DAD8A), width: 2)),
          child: Text('$_completedCount/4 ✅',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF04342C))),
        ),
      ]),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9E0), Color(0xFFFFF0C0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD93D), width: 3),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 6)),
          const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,3)),
        ],
      ),
      child: Column(children: [
        // Icône mission + titre visuel
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🗝️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          const Text('🔤', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          const Text('🗝️', style: TextStyle(fontSize: 28)),
        ]),
        const SizedBox(height: 10),
        const Text('Mission du jour',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF7A5200))),
        const SizedBox(height: 6),
        // Sous-texte visuel
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Sauve ', style: TextStyle(fontSize: 13, color: Color(0xFF9B6C00), fontWeight: FontWeight.w700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFA000), width: 1.5),
            ),
            child: Text('${widget.todayLetters.length}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF7A3800))),
          ),
          const Text(' lettres ✉️',
            style: TextStyle(fontSize: 13, color: Color(0xFF9B6C00), fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        // Barre progression de la mission
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _completedCount / 4,
            minHeight: 10,
            backgroundColor: const Color(0xFFE8D870),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5DCAA5)),
          ),
        ),
      ]),
    );
  }

  Widget _buildLettersDisplay() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.todayLetters.length, (i) {
            final floatOffset = _floatAnim.value * (i.isEven ? 1 : -0.7);
            return Transform.translate(
              offset: Offset(0, floatOffset),
              child: _LetterBubble(
                letter: widget.todayLetters[i],
                color:  _letterColors[i % _letterColors.length],
                dark:   _letterDarkColors[i % _letterDarkColors.length],
                rescued: false,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildGamesProgress() {
    final gameIcons  = ['👂', '👁️', '🃏', '✏️'];
    final gameLabels = ['Écoute', 'Reconnais', 'Mémoire', 'Écris'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5DCAA5), width: 2.5),
        boxShadow: [BoxShadow(
          color: const Color(0xFF5DCAA5).withOpacity(0.2), blurRadius: 14, offset: const Offset(0,4))],
      ),
      child: Column(children: [
        const Text('Tes 4 aventures',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: LKColors.textOnGreen)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) {
            final done = _gamesDone[i];
            final isNext = !done && (i == 0 || _gamesDone[i-1]);
            return Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                    ? const Color(0xFF5DCAA5)
                    : isNext
                    ? const Color(0xFFFFD93D)
                    : const Color(0xFFE8E5DC),
                  border: Border.all(
                    color: done
                      ? const Color(0xFF3DAD8A)
                      : isNext
                      ? const Color(0xFFFFA000)
                      : const Color(0xFFD3D0C7),
                    width: 2.5),
                  boxShadow: done || isNext ? [
                    BoxShadow(
                      color: (done ? const Color(0xFF5DCAA5) : const Color(0xFFFFD93D)).withOpacity(0.5),
                      blurRadius: 10, spreadRadius: 1)
                  ] : [],
                ),
                child: Center(child: Text(
                  done ? '⭐' : gameIcons[i],
                  style: TextStyle(fontSize: done ? 24 : 20),
                )),
              ),
              const SizedBox(height: 5),
              Text(gameLabels[i],
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: done
                    ? const Color(0xFF085041)
                    : isNext
                    ? const Color(0xFF7A5200)
                    : const Color(0xFFB4B2A9),
                )),
            ]);
          }),
        ),
        // Connecteurs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          child: Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 3,
                color: _gamesDone[i]
                  ? const Color(0xFF5DCAA5)
                  : const Color(0xFFE8E5DC),
              ),
            )),
          ),
        ),
      ]),
    );
  }

  Widget _buildStartButton() {
    // Trouver le prochain jeu
    int nextIdx = _gamesDone.indexWhere((d) => !d);
    if (nextIdx == -1) nextIdx = -1; // Tout terminé

    if (nextIdx == -1 || _allDone) {
      return Column(children: [
        const Text('🎉🎉🎉', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF5DCAA5), Color(0xFF3DAD8A)]),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF2D8E6C), width: 3),
              boxShadow: [BoxShadow(color: const Color(0xFF5DCAA5).withOpacity(0.5),
                  blurRadius: 18, offset: const Offset(0,5))]),
            child: const Text('🗝️ Mission accomplie !',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ]);
    }

    final gameNames = ['Jeu d\'écoute', 'Jeu de reconnaissance', 'Jeu de mémoire', 'Jeu d\'écriture'];

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _launchGame(nextIdx);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD93D), Color(0xFFFFA000)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFF8C00), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.55),
                    blurRadius: 20, spreadRadius: 3, offset: const Offset(0,5)),
                const BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,3)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_getGameIcon(nextIdx), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Commencer',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9B6C00))),
                Text(gameNames[nextIdx],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF7A3800))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  String _getGameIcon(int idx) {
    return ['👂', '👁️', '🃏', '✏️'][idx];
  }

  Widget _buildLumiStrip() {
    return AnimatedBuilder(
      animation: _lumiFloat,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _lumiFloat.value),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD93D), width: 2.5),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0,3))],
          ),
          child: Row(children: [
            LumiMascot(mood: LumiMood.guide, size: 38),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _allDone
                ? '🎉 Bravo ! Tu as sauvé ${widget.todayLetters.join(", ")} !'
                : '✨ Complète les 4 jeux pour obtenir la clé !',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: LKColors.textOnYellow),
            )),
          ]),
        ),
      ),
    );
  }

  void _launchGame(int gameIdx) {
    Widget screen;
    switch (gameIdx) {
      case 0:
        screen = LetterDiscoveryScreen(
          islandId: widget.islandId,
          letters: widget.todayLetters,
          dayNumber: widget.dayNumber,
        );
        break;
      default:
        screen = LetterDiscoveryScreen(
          islandId: widget.islandId,
          letters: widget.todayLetters,
          dayNumber: widget.dayNumber,
        );
    }
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => screen,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    )).then((_) => _loadProgress());
  }
}

// ── Letter Bubble ────────────────────────────────────────────
class _LetterBubble extends StatelessWidget {
  final String letter;
  final Color  color, dark;
  final bool   rescued;

  const _LetterBubble({
    required this.letter, required this.color,
    required this.dark, required this.rescued,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 76, height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: rescued
              ? [color.withOpacity(0.3), dark.withOpacity(0.15)]
              : [Colors.white, color.withOpacity(0.9)],
            center: const Alignment(-0.3, -0.3),
          ),
          border: Border.all(
            color: rescued ? dark.withOpacity(0.3) : dark,
            width: 3,
            style: rescued ? BorderStyle.solid : BorderStyle.solid,
          ),
          boxShadow: rescued ? [] : [
            BoxShadow(color: color.withOpacity(0.55), blurRadius: 18, spreadRadius: 2),
          ],
        ),
        child: Center(child: Text(
          rescued ? '⭐' : letter,
          style: TextStyle(
            fontSize: rescued ? 32 : 38,
            fontWeight: FontWeight.w900,
            color: rescued ? dark : dark,
            shadows: rescued ? [] : [
              Shadow(color: dark.withOpacity(0.3), blurRadius: 4, offset: const Offset(0,2)),
            ],
          ),
        )),
      ),
      const SizedBox(height: 6),
      Text(rescued ? 'Sauvée!' : letter,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: rescued ? const Color(0xFF3DAD8A) : Colors.white,
        )),
    ]);
  }
}