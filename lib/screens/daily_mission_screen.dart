// lib/screens/daily_mission_screen.dart
// ════════════════════════════════════════════════════════════
// MISSION DU JOUR — 3 lettres, 4 jeux dans l'ordre
// Jeu 1 : Voir + Écouter (letter_discovery_screen)
// Jeu 2 : Reconnaître    (letter_recognition_game_cp)
// Jeu 3 : Mémoriser      (memory_matching_game_cp)
// Jeu 4 : Écrire         (letter_writing_game_cp)
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/lumi_mascot.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../data/letter_games_data.dart';
import 'games/letter_discovery_screen.dart';
import 'games/letter_recognition_game_cp.dart';
import 'games/memory_matching_game_cp.dart';
import 'games/letter_writing_game_cp.dart';

class DailyMissionScreen extends StatefulWidget {
  final String islandId;
  final List<String> todayLetters;
  final int dayNumber;

  const DailyMissionScreen({
    super.key,
    required this.islandId,
    required this.todayLetters,
    required this.dayNumber,
  });

  @override
  State<DailyMissionScreen> createState() => _State();
}

class _State extends State<DailyMissionScreen> with TickerProviderStateMixin {
  List<bool> _done = [false, false, false, false];

  late AnimationController _floatCtrl, _pulseCtrl, _entranceCtrl;
  late Animation<double> _float, _pulse, _entrance;

  // Couleurs des 3 lettres du jour
  static const _colors = [
    Color(0xFFFFD93D),
    Color(0xFFFF8C9E),
    Color(0xFF85DAFF)
  ];
  static const _darks = [
    Color(0xFFFFA000),
    Color(0xFFD4537E),
    Color(0xFF378ADD)
  ];

  // Config des 4 jeux
  static const _gameIcons = ['👁', '👂', '🃏', '✏️'];
  static const _gameLabels = [
    'Voir & Écouter',
    'Reconnaître',
    'Mémoriser',
    'Écrire'
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _float = Tween(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulse = Tween(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entrance =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack);
    _entranceCtrl.forward();
    _loadProgress();
    // Lumi accueille
    Future.delayed(const Duration(milliseconds: 600), () {
      TtsService().speak(
          'Bonjour ! Aujourd\'hui on sauve ${widget.todayLetters.join(", ")} !');
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final ps = ProgressService();
    setState(() {
      _done = [
        ps.hasCompletedGame(widget.islandId, 'discovery_${widget.dayNumber}'),
        ps.hasCompletedGame(widget.islandId, 'recognition_${widget.dayNumber}'),
        ps.hasCompletedGame(widget.islandId, 'memory_${widget.dayNumber}'),
        ps.hasCompletedGame(widget.islandId, 'writing_${widget.dayNumber}'),
      ];
    });
  }

  int get _nextGame {
    for (int i = 0; i < _done.length; i++) {
      if (!_done[i]) return i;
    }
    return -1;
  }

  bool get _allDone => _done.every((d) => d);

  void _launchGame(int idx) {
    if (idx < 0) return;
    HapticFeedback.mediumImpact();
    final theme = IslandTheme.all.firstWhere((t) => t.id == widget.islandId,
        orElse: () => IslandTheme.all[0]);

    Widget screen;
    switch (idx) {
      case 0:
        screen = LetterDiscoveryScreen(
            islandId: widget.islandId,
            letters: widget.todayLetters,
            dayNumber: widget.dayNumber);
        break;
      case 1:
        screen = LetterRecognitionGameCP(
            islandId: widget.islandId,
            letters: widget.todayLetters,
            dayNumber: widget.dayNumber,
            theme: theme);
        break;
      case 2:
        screen = MemoryMatchingGameCP(
            islandId: widget.islandId,
            letters: widget.todayLetters,
            dayNumber: widget.dayNumber,
            theme: theme);
        break;
      case 3:
      default:
        screen = LetterWritingGameCP(
            islandId: widget.islandId,
            letters: widget.todayLetters,
            dayNumber: widget.dayNumber,
            theme: theme);
        break;
    }

    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => screen,
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        )).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B6FA8),
              Color(0xFF42B8E0),
              Color(0xFF87CEEB),
              Color(0xFFC8F5FF)
            ],
            stops: [0, 0.30, 0.65, 1],
          ),
        ),
        child: SafeArea(
            child: Column(children: [
          _topBar(),
          Expanded(
              child: ScaleTransition(
            scale: _entrance,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(children: [
                _missionCard(),
                const SizedBox(height: 16),
                _lettersRow(),
                const SizedBox(height: 16),
                _gamesGrid(),
                const SizedBox(height: 20),
                _startButton(),
              ]),
            ),
          )),
          _lumiBar(),
        ])),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.5)),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 18))),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFA000), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFFD93D).withValues(alpha:0.45),
                        blurRadius: 10)
                  ]),
              child: Text('Jour ${widget.dayNumber} 📅',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7A3800)))),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF5DCAA5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3DAD8A), width: 2)),
              child: Text('${_done.where((d) => d).length}/4 ✅',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF04342C)))),
        ]),
      );

  Widget _missionCard() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFF9E0), Color(0xFFFFF0C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD93D), width: 3),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFFD93D).withValues(alpha:0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ]),
        child: Column(children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🗝️', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('🔤', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('🗝️', style: TextStyle(fontSize: 28)),
          ]),
          const SizedBox(height: 10),
          const Text('Mission du jour',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7A5200))),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Sauve ',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9B6C00),
                    fontWeight: FontWeight.w700)),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFFFA000), width: 1.5)),
                child: const Text('3',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7A3800)))),
            const Text(' lettres ✉️',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9B6C00),
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: _done.where((d) => d).length / 4,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE8D870),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF5DCAA5)))),
        ]),
      );

  Widget _lettersRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.todayLetters.length, (i) {
          final l = widget.todayLetters[i];
          final data = kLetterDB[l];
          return AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _float.value * (i.isEven ? 1 : -0.7)),
              child: Column(children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                          colors: [Colors.white, _colors[i].withValues(alpha:0.9)],
                          center: const Alignment(-0.3, -0.3)),
                      border: Border.all(color: _darks[i], width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: _colors[i].withValues(alpha:0.55),
                            blurRadius: 18,
                            spreadRadius: 2)
                      ]),
                  child: data != null
                      ? ClipOval(
                          child: Image.asset(data.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Text(l,
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: _darks[i])))))
                      : Center(
                          child: Text(l,
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: _darks[i]))),
                ),
                const SizedBox(height: 4),
                Text(l,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 3)
                        ])),
                if (data != null)
                  Text(data.word,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha:0.8))),
              ]),
            ),
          );
        }),
      );

  Widget _gamesGrid() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF5DCAA5), width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF5DCAA5).withValues(alpha:0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ]),
        child: Column(children: [
          const Text('Tes 4 aventures aujourd\'hui',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF085041))),
          const SizedBox(height: 12),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                final done = _done[i];
                final isNext = !done && (i == 0 || _done[i - 1]);
                return GestureDetector(
                  onTap: isNext ? () => _launchGame(i) : null,
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 58,
                      height: 58,
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
                          boxShadow: done || isNext
                              ? [
                                  BoxShadow(
                                      color: (done
                                              ? const Color(0xFF5DCAA5)
                                              : const Color(0xFFFFD93D))
                                          .withValues(alpha:0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1)
                                ]
                              : []),
                      child: Center(
                          child: Text(done ? '⭐' : _gameIcons[i],
                              style: TextStyle(fontSize: done ? 22 : 20))),
                    ),
                    const SizedBox(height: 5),
                    Text(_gameLabels[i],
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: done
                                ? const Color(0xFF085041)
                                : isNext
                                    ? const Color(0xFF7A5200)
                                    : const Color(0xFFB4B2A9))),
                  ]),
                );
              })),
          // Connecteurs entre jeux
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
              child: Row(
                  children: List.generate(
                      3,
                      (i) => Expanded(
                          child: Container(
                              height: 3,
                              color: _done[i]
                                  ? const Color(0xFF5DCAA5)
                                  : const Color(0xFFE8E5DC)))))),
        ]),
      );

  Widget _startButton() {
    final idx = _nextGame;
    if (_allDone) {
      return Column(children: [
        const Text('🎉🎉🎉', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 12),
        GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5DCAA5), Color(0xFF3DAD8A)]),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: const Color(0xFF2D8E6C), width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF5DCAA5).withValues(alpha:0.5),
                          blurRadius: 18,
                          offset: const Offset(0, 5))
                    ]),
                child: const Text('🗝️ Mission accomplie !',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)))),
      ]);
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: GestureDetector(
          onTap: () => _launchGame(idx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD93D), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFF8C00), width: 3),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFFD93D).withValues(alpha:0.55),
                      blurRadius: 20,
                      spreadRadius: 3,
                      offset: const Offset(0, 5))
                ]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_gameIcons[idx], style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Commencer',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9B6C00))),
                Text(_gameLabels[idx],
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7A3800))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _lumiBar() => AnimatedBuilder(
        animation: _float,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _float.value),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD93D), width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha:0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child: Row(children: [
              LumiMascot(
                  mood: _allDone ? LumiMood.celebrate : LumiMood.guide,
                  size: 38),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      _allDone
                          ? '🎉 Bravo ! Tu as sauvé ${widget.todayLetters.join(", ")} !'
                          : '✨ Complète les 4 jeux pour sauver les lettres !',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7A5200)))),
            ]),
          ),
        ),
      );
}
