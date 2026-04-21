// lib/screens/game_selection_screen.dart
// Design festif pour enfants :
// Chemin de 4 jeux débloqués un par un.
// Memory → Quiz → Bingo → Parcours
// Chaque jeu a sa couleur, son emoji, ses étoiles.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'memory_game_screen.dart';
import 'quiz_game_screen.dart';
import 'bingo_game_screen.dart';
import 'parcours_game_screen.dart';

// Données d'un jeu dans le chemin
class _GameInfo {
  final String type;
  final String title;
  final String emoji;
  final String description;
  final Color color1;
  final Color color2;
  final String lockedMessage;

  const _GameInfo({
    required this.type,
    required this.title,
    required this.emoji,
    required this.description,
    required this.color1,
    required this.color2,
    required this.lockedMessage,
  });
}

class GameSelectionScreen extends StatefulWidget {
  final GameLevelData levelData;
  const GameSelectionScreen({super.key, required this.levelData});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with TickerProviderStateMixin {
  // Animation de rebond pour le jeu actif
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // Animation de confettis quand on termine tous les jeux
  late AnimationController _confettiCtrl;
  late Animation<double> _confettiAnim;

  // Animation d'entrée des cartes
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  static const List<_GameInfo> _games = [
    _GameInfo(
      type: 'memory',
      title: 'Memory',
      emoji: '🃏',
      description: 'Retourne les cartes\net trouve les paires !',
      color1: Color(0xFF1565C0),
      color2: Color(0xFF42A5F5),
      lockedMessage: 'Joue d\'abord !',
    ),
    _GameInfo(
      type: 'quiz',
      title: 'Quiz',
      emoji: '❓',
      description: 'Réponds aux\nquestions !',
      color1: Color(0xFF2E7D32),
      color2: Color(0xFF66BB6A),
      lockedMessage: 'Finis le Memory d\'abord !',
    ),
    _GameInfo(
      type: 'bingo',
      title: 'Bingo',
      emoji: '🎯',
      description: 'Écoute et clique\nla bonne image !',
      color1: Color(0xFF6A1B9A),
      color2: Color(0xFFAB47BC),
      lockedMessage: 'Finis le Quiz d\'abord !',
    ),
    _GameInfo(
      type: 'parcours',
      title: 'Parcours',
      emoji: '🏆',
      description: 'Avance case\npar case !',
      color1: Color(0xFFE65100),
      color2: Color(0xFFFF7043),
      lockedMessage: 'Finis le Bingo d\'abord !',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _confettiAnim = Tween<double>(begin: 0, end: 1).animate(_confettiCtrl);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    // Si tous les jeux sont terminés → confettis !
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allDone = _games.every((g) =>
          ProgressService().hasCompletedGame(widget.levelData.id, g.type));
      if (allDone) {
        _confettiCtrl.forward();
        TtsService().speak('Bravo ! Tu as tout terminé !');
      }
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _confettiCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService(),
      builder: (context, _) {
        final allDone = _games.every((g) =>
            ProgressService().hasCompletedGame(widget.levelData.id, g.type));
        final completedCount =
            ProgressService().completedGameCount(widget.levelData.id);
        final stars = ProgressService().starsFor(widget.levelData.id);

        return Scaffold(
          body: Stack(
            children: [
              // Fond dégradé festif
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A1628),
                      Color(0xFF1A237E),
                      Color(0xFF283593),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Étoiles décoratives de fond
              const _BackgroundStars(),
              // Bulles flottantes décoratives
              const _FloatingBubbles(),
              // Contenu principal
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, completedCount, stars),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          children: [
                            // Info du niveau
                            _buildLevelInfo(),
                            const SizedBox(height: 20),
                            // Chemin des jeux
                            _buildGamePath(completedCount),
                            const SizedBox(height: 20),
                            // Bannière victoire si tout terminé
                            if (allDone) _buildVictoryBanner(stars),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Confettis par-dessus tout
              if (allDone)
                AnimatedBuilder(
                  animation: _confettiAnim,
                  builder: (_, __) => _ConfettiOverlay(
                    progress: _confettiAnim.value,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // En-tête
  // ──────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, int completedCount, int stars) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.levelData.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.levelData.getProgression(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Étoiles du niveau
          if (stars > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars
                        ? Colors.amber
                        : Colors.white.withOpacity(0.3),
                    size: 16,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Compteur jeux
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$completedCount / 4 jeux',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Carte info niveau
  // ──────────────────────────────────────────────
  Widget _buildLevelInfo() {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, child) => FadeTransition(
        opacity: _entryAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(_entryAnim),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Icône niveau
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getLevelEmoji(),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.levelData.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barre de progression des jeux
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ProgressService().completedGameCount(widget.levelData.id)} jeux terminés sur 4',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ProgressService()
                                  .completedGameCount(widget.levelData.id) /
                              4,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Stats
            Column(
              children: [
                _miniStat(
                    '${widget.levelData.vocabulary.length}', '📖', 'mots'),
                const SizedBox(height: 4),
                _miniStat('${widget.levelData.estimatedDuration}', '⏱', 'min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String emoji, String label) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 9),
          ),
        ],
      );

  // ──────────────────────────────────────────────
  // Chemin des 4 jeux
  // ──────────────────────────────────────────────
  Widget _buildGamePath(int completedCount) {
    return Column(
      children: [
        // Instruction
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎮', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Complète les jeux dans l\'ordre !',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Les 4 cartes de jeux
        ...List.generate(_games.length, (i) {
          final game = _games[i];
          final isCompleted = ProgressService()
              .hasCompletedGame(widget.levelData.id, game.type);
          final isUnlocked = ProgressService()
              .isGameUnlocked(widget.levelData.id, game.type);
          final isActive = isUnlocked && !isCompleted;

          return AnimatedBuilder(
            animation: _entryAnim,
            builder: (_, child) => FadeTransition(
              opacity: _entryAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(i % 2 == 0 ? -0.5 : 0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entryCtrl,
                  curve: Interval(
                    i * 0.15,
                    (i * 0.15 + 0.6).clamp(0, 1),
                    curve: Curves.easeOut,
                  ),
                )),
                child: child,
              ),
            ),
            child: Column(
              children: [
                // Connecteur entre les jeux
                if (i > 0) _buildGameConnector(isUnlocked),
                // Carte du jeu
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, isActive ? _bounceAnim.value * 0.5 : 0),
                    child: _GameCard(
                      gameInfo: game,
                      isCompleted: isCompleted,
                      isUnlocked: isUnlocked,
                      isActive: isActive,
                      levelData: widget.levelData,
                      onTap: () => _onGameTap(game, isUnlocked, isCompleted),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGameConnector(bool nextUnlocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: nextUnlocked
                  ? Colors.amber.withOpacity(0.7)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            Icons.keyboard_double_arrow_down,
            color: nextUnlocked
                ? Colors.amber.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
            size: 18,
          ),
          Container(
            width: 3,
            height: 8,
            decoration: BoxDecoration(
              color: nextUnlocked
                  ? Colors.amber.withOpacity(0.7)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Bannière victoire
  // ──────────────────────────────────────────────
  Widget _buildVictoryBanner(int stars) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFD600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          const Text(
            'Niveau terminé !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: i < stars ? Colors.white : Colors.white38,
                  size: 38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              stars >= 3
                  ? '⭐ Parfait ! Tu maîtrises ce niveau !'
                  : stars >= 2
                      ? '👍 Bien joué ! Le niveau suivant est débloqué !'
                      : '💪 Continue à t\'entraîner !',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tap sur un jeu
  // ──────────────────────────────────────────────
  void _onGameTap(_GameInfo game, bool isUnlocked, bool isCompleted) {
    if (!isUnlocked) {
      // Afficher message de blocage animé
      _showBlockedDialog(game);
      return;
    }

    TtsService().speak('C\'est parti pour ${game.title} !');

    Widget screen;
    switch (game.type) {
      case 'memory':
        screen = MemoryGameScreen(levelData: widget.levelData);
        break;
      case 'quiz':
        screen = QuizGameScreen(levelData: widget.levelData);
        break;
      case 'bingo':
        screen = BingoGameScreen(levelData: widget.levelData);
        break;
      case 'parcours':
        screen = ParcourGameScreen(levelData: widget.levelData);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) => ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
          ),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showBlockedDialog(_GameInfo game) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                game.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  game.lockedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                ),
                child: const Text(
                  'OK, je comprends !',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLevelEmoji() {
    final theme = (widget.levelData.theme ?? '').toLowerCase();
    if (theme.contains('alpha'))   return '🔤';
    if (theme.contains('chiffre')) return '🔢';
    if (theme.contains('couleur')) return '🎨';
    if (theme.contains('salut'))   return '👋';
    if (theme.contains('animal'))  return '🐾';
    if (theme.contains('nourrit') || theme.contains('food')) return '🍎';
    if (theme.contains('famille')) return '👨‍👩‍👧';
    if (theme.contains('météo'))   return '⛅';
    if (theme.contains('école'))   return '🎒';
    if (theme.contains('maison'))  return '🏠';
    if (theme.contains('verbe'))   return '✍️';
    if (theme.contains('émotion')) return '😊';
    if (theme.contains('métier'))  return '👷';
    return '📖';
  }
}

// ─────────────────────────────────────────────────────────────
// Carte d'un jeu (Memory, Quiz, Bingo, Parcours)
// ─────────────────────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final _GameInfo gameInfo;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isActive;
  final GameLevelData levelData;
  final VoidCallback onTap;

  const _GameCard({
    required this.gameInfo,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isActive,
    required this.levelData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: !isUnlocked
                ? [const Color(0xFF1C2833), const Color(0xFF2C3E50)]
                : isCompleted
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                    : [gameInfo.color1, gameInfo.color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? Colors.white
                : isCompleted
                    ? Colors.green.shade300
                    : Colors.white.withOpacity(0.15),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: (isCompleted
                            ? Colors.green
                            : isActive
                                ? Colors.white
                                : gameInfo.color1)
                        .withOpacity(0.35),
                    blurRadius: isActive ? 24 : 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Emoji du jeu
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  !isUnlocked ? '🔒' : isCompleted ? '✅' : gameInfo.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        gameInfo.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TERMINÉ ✓',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (isActive && !isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '▶ EN COURS',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    !isUnlocked
                        ? '🔒 ${gameInfo.lockedMessage}'
                        : gameInfo.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🎮  JOUER MAINTENANT !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  if (isCompleted) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🔄  Rejouer pour t\'améliorer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUnlocked)
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                color: isCompleted
                    ? Colors.green.shade300
                    : Colors.white.withOpacity(0.6),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Étoiles décoratives de fond
// ─────────────────────────────────────────────────────────────
class _BackgroundStars extends StatelessWidget {
  const _BackgroundStars();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _BgStarPainter());
}

class _BgStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.35);
    const positions = [
      [0.05, 0.04], [0.15, 0.01], [0.27, 0.07], [0.40, 0.03],
      [0.53, 0.05], [0.66, 0.02], [0.78, 0.08], [0.90, 0.04],
      [0.08, 0.12], [0.20, 0.15], [0.33, 0.10], [0.46, 0.14],
      [0.59, 0.11], [0.72, 0.16], [0.85, 0.09], [0.95, 0.13],
      [0.03, 0.22], [0.16, 0.26], [0.29, 0.20], [0.42, 0.25],
      [0.55, 0.19], [0.68, 0.24], [0.81, 0.18], [0.93, 0.23],
    ];
    for (final pos in positions) {
      canvas.drawCircle(
        Offset(size.width * pos[0], size.height * pos[1]),
        1.2,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// Bulles flottantes décoratives
// ─────────────────────────────────────────────────────────────
class _FloatingBubbles extends StatelessWidget {
  const _FloatingBubbles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          _bubble(left: 20, top: 80, size: 60, opacity: 0.04),
          _bubble(right: 30, top: 150, size: 40, opacity: 0.05),
          _bubble(left: 50, bottom: 200, size: 80, opacity: 0.03),
          _bubble(right: 10, bottom: 100, size: 50, opacity: 0.04),
        ],
      ),
    );
  }

  Widget _bubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Confettis — animation de célébration
// ─────────────────────────────────────────────────────────────
class _ConfettiOverlay extends StatelessWidget {
  final double progress; // 0.0 → 1.0

  const _ConfettiOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height,
        ),
        painter: _ConfettiPainter(progress: progress),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static const _colors = [
    Colors.red, Colors.blue, Colors.green,
    Colors.yellow, Colors.purple, Colors.orange, Colors.pink,
  ];

  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height + 20;
      final y = startY + (endY - startY) * progress;
      final offsetX = math.sin(progress * 6 + i) * 30;

      final paint = Paint()
        ..color = _colors[i % _colors.length].withOpacity(
          (1 - progress).clamp(0, 1),
        );

      final rect = Rect.fromCenter(
        center: Offset(x + offsetX, y + rng.nextDouble() * 200 * progress),
        width: 8,
        height: 12,
      );

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(progress * 10 + i.toDouble());
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}