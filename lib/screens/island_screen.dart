// lib/screens/island_screen.dart
// CORRIGÉ : imports propres, SoundMatchingScreen importé depuis letter_recognition_screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../widgets/lumi_mascot.dart';
import '../widgets/lk_widgets.dart';
import 'games/listening_game_screen.dart';
import 'games/letter_recognition_screen.dart'; // contient aussi SoundMatchingScreen
import 'games/memory_game_screen.dart';
import 'games/word_builder_screen.dart';

class IslandScreen extends StatefulWidget {
  final String islandId;
  final IslandTheme theme;

  const IslandScreen({
    super.key,
    required this.islandId,
    required this.theme,
  });

  @override
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen>
    with TickerProviderStateMixin {

  late AnimationController _heroCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _heroAnim;
  late Animation<double> _floatAnim;

  static const _gameOrder = [
    'listening',
    'letter_recognition',
    'sound_matching',
    'memory',
    'word_builder',
  ];

  static const _gameConfig = [
    _GameCfg('listening',          '👂', 'Jeu d\'écoute',       'Tape la bonne image !'),
    _GameCfg('letter_recognition', '🔤', 'Reconnais la lettre', 'Trouve le bon son !'),
    _GameCfg('sound_matching',     '🎵', 'Sons pareils ?',      'Même ou différent ?'),
    _GameCfg('memory',             '🃏', 'Jeu de mémoire',      'Retourne les cartes !'),
    _GameCfg('word_builder',       '🏗️', 'Construis le mot',    'Assemble les syllabes !'),
  ];

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _heroAnim  = CurvedAnimation(parent: _heroCtrl,  curve: Curves.easeOutCubic);
    _floatAnim = Tween<double>(begin: -5, end: 5).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  _GState _stateOf(String key) {
    final ps  = ProgressService();
    final idx = _gameOrder.indexOf(key);
    if (idx == 0) {
      return ps.hasCompletedGame(widget.islandId, key)
          ? _GState.done : _GState.current;
    }
    final prevDone = ps.hasCompletedGame(widget.islandId, _gameOrder[idx - 1]);
    if (!prevDone) return _GState.locked;
    return ps.hasCompletedGame(widget.islandId, key)
        ? _GState.done : _GState.current;
  }

  int _starsOf(String key) =>
      ProgressService().starsFor('${widget.islandId}-$key');

  int get _totalStars =>
      _gameConfig.fold(0, (s, g) => s + _starsOf(g.key));

  String get _lumiMsg {
    final ps = ProgressService();
    final allDone =
        _gameConfig.every((g) => ps.hasCompletedGame(widget.islandId, g.key));
    if (allDone) return 'Incroyable ! Tu as tout terminé ! 🎉';
    for (final g in _gameConfig) {
      if (_stateOf(g.key) == _GState.current) {
        return 'Continue "${g.title}" pour débloquer la suite ! 🌟';
      }
    }
    return 'Choisis un jeu pour commencer l\'aventure ! ✨';
  }

  void _goTo(String key) {
    HapticFeedback.mediumImpact();
    Widget screen;
    switch (key) {
      case 'listening':
        screen = ListeningGameScreen(
            islandId: widget.islandId, theme: widget.theme);
        break;
      case 'letter_recognition':
        screen = LetterRecognitionScreen(
            islandId: widget.islandId, theme: widget.theme);
        break;
      case 'sound_matching':
        // SoundMatchingScreen est défini dans letter_recognition_screen.dart
        screen = SoundMatchingScreen(
            islandId: widget.islandId, theme: widget.theme);
        break;
      case 'memory':
        screen = MemoryGameScreen(
            islandId: widget.islandId, theme: widget.theme);
        break;
      case 'word_builder':
        screen = WordBuilderScreen(
            islandId: widget.islandId, theme: widget.theme);
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKColors.bgCream,
      body: Column(children: [
        _buildHero(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(children: [
              _buildLumiTip(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('TES 5 AVENTURES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                      color: LKColors.textLight, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 8),
              ...(_gameConfig.map(_buildCard)),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: _buildCTA(),
    );
  }

  Widget _buildHero() {
    return FadeTransition(
      opacity: _heroAnim,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: widget.theme.primary,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: widget.theme.dark,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32))),
            ),
          ),
          Positioned(top: 18, right: 22,
            child: Container(width: 34, height: 34,
              decoration: const BoxDecoration(
                  color: LKColors.sun, shape: BoxShape.circle)),
          ),
          Positioned(bottom: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.theme.decorEmojis
                  .map((e) => Text(e, style: const TextStyle(fontSize: 16)))
                  .toList(),
            ),
          ),
          Positioned(top: 46, left: 14,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.9), width: 2)),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: LKColors.textDark, size: 18),
                ),
              ),
            ),
          ),
          Positioned(top: 52, left: 0, right: 0,
            child: SafeArea(child: Column(children: [
              Text(widget.theme.name,
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                  shadows: [Shadow(color: Colors.black26,
                      blurRadius: 4, offset: Offset(0, 2))],
                )),
              const SizedBox(height: 2),
              Text(widget.theme.subtitle,
                style: TextStyle(fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                LKStars(earned: _totalStars.clamp(0, 3), size: 18),
                const SizedBox(width: 8),
                Text('$_totalStars / ${_gameConfig.length * 3}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85))),
              ]),
            ])),
          ),
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Positioned(
              bottom: 36, right: 20,
              child: Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: LumiMascot(mood: LumiMood.happy, size: 44),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLumiTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LKColors.bgYellowLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LKColors.sun, width: 2.5),
      ),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: const BoxDecoration(
              color: LKColors.sun, shape: BoxShape.circle),
          child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lumi dit :',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                  color: LKColors.textOnYellow)),
            const SizedBox(height: 2),
            Text(_lumiMsg,
              style: const TextStyle(fontSize: 11,
                  color: Color(0xFF9B6C00),
                  fontWeight: FontWeight.w600, height: 1.4)),
          ],
        )),
      ]),
    );
  }

  Widget _buildCard(_GameCfg g) {
    final state = _stateOf(g.key);
    final stars = _starsOf(g.key);
    switch (state) {
      case _GState.done:
        return LKGameCard.done(
            emoji: g.emoji, title: g.title, subtitle: g.subtitle,
            stars: stars, onTap: () => _goTo(g.key));
      case _GState.current:
        return LKGameCard.current(
            emoji: g.emoji, title: g.title, subtitle: g.subtitle,
            onTap: () => _goTo(g.key));
      case _GState.locked:
        return LKGameCard.locked(
            emoji: g.emoji, title: g.title, subtitle: g.subtitle);
    }
  }

  Widget _buildCTA() {
    String? nextKey;
    for (final g in _gameConfig) {
      if (_stateOf(g.key) == _GState.current) { nextKey = g.key; break; }
    }
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16,
          MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LKColors.sun, width: 2.5)),
      ),
      child: nextKey != null
        ? LKButton.primary('⭐ Continuer l\'aventure !',
            onPressed: () => _goTo(nextKey!))
        : LKButton.green('🎉 Toutes les aventures terminées !'),
    );
  }
}

enum _GState { done, current, locked }

class _GameCfg {
  final String key, emoji, title, subtitle;
  const _GameCfg(this.key, this.emoji, this.title, this.subtitle);
}