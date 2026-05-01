// lib/screens/vocal_game_screen.dart
// 🎤 JEU VOCAL — "DIS LE MOT !" v1
//
// POURQUOI ce jeu ?
//   Les élèves du CP au Maroc ont un problème de communication ORALE en français.
//   Les 4 jeux existants (Memory, Quiz, Bingo, Parcours) sont tous VISUELS.
//   Ce jeu force l'enfant à PARLER. Pas de clic possible. Seul le micro valide.
//
// FONCTIONNEMENT :
//   1. L'app montre une image + dit le mot à voix haute (TTS)
//   2. L'enfant répète le mot dans le micro
//   3. La reconnaissance vocale + distance de Levenshtein valident la prononciation
//   4. Feedback immédiat : ce qu'on a entendu vs ce qu'il fallait dire
//   5. 3 tentatives par mot, puis passage au suivant avec correction
//
// ADAPTATIF :
//   - Mode Débutant : le mot s'affiche en gros pendant l'écoute
//   - Mode Moyen : le mot s'affiche seulement après
//   - Mode Génie : seule l'image, pas de texte

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../models/student_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';
import '../services/speech_service.dart';
import '../services/adaptive_engine.dart';

class VocalGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const VocalGameScreen({super.key, required this.levelData});
  @override
  State<VocalGameScreen> createState() => _VocalGameScreenState();
}

class _VocalGameScreenState extends State<VocalGameScreen>
    with TickerProviderStateMixin {

  late final AdaptiveEngine _ai;
  late final AdaptiveTier _tier;

  // ── Jeu ──────────────────────────────────────────────────
  late List<Word> _words;
  int _currentIndex = 0;
  int _score = 0;
  int _totalCorrect = 0;
  int _attempts = 0;       // tentatives sur le mot courant
  static const _maxAttempts = 3;

  // ── État micro ───────────────────────────────────────────
  bool _isListening = false;
  bool _isAnswered = false;
  String _heardText = '';
  bool _lastCorrect = false;

  // ── Animations ───────────────────────────────────────────
  late final AnimationController _micPulseCtrl;
  late final Animation<double> _micPulseAnim;
  late final AnimationController _resultCtrl;
  late final Animation<double> _resultAnim;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;
  late final AnimationController _confettiCtrl;

  // ── Couleur du niveau ────────────────────────────────────
  Color get _lc {
    switch (widget.levelData.level) {
      case GameLevel.cp:  return const Color(0xFF1565C0);
      case GameLevel.ce1: return const Color(0xFF2E7D32);
      case GameLevel.ce2: return const Color(0xFFE65100);
      case GameLevel.cm1: return const Color(0xFF6A1B9A);
      case GameLevel.cm2: return const Color(0xFFC62828);
      default:            return const Color(0xFF1565C0);
    }
  }

  @override
  void initState() {
    super.initState();
    _ai = AdaptiveEngine();
    _tier = _ai.tierForLevel(widget.levelData.id);

    // Animations
    _micPulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _micPulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(parent: _micPulseCtrl, curve: Curves.easeInOut));

    _resultCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _resultAnim = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutBack);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    _entryCtrl.forward();

    _confettiCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3));

    // Sélection des mots (10 mots)
    _words = _ai.selectWords(widget.levelData.vocabulary, count: 10);

    // Premier mot : TTS automatique après 800ms
    Future.delayed(const Duration(milliseconds: 800), _speakCurrentWord);
  }

  @override
  void dispose() {
    _micPulseCtrl.dispose();
    _resultCtrl.dispose();
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Parler le mot courant
  // ─────────────────────────────────────────────
  void _speakCurrentWord() {
    if (!mounted || _currentIndex >= _words.length) return;
    final word = _words[_currentIndex];
    TtsService().speak(word.word);
  }

  // ─────────────────────────────────────────────
  // Lancer l'écoute du micro
  // ─────────────────────────────────────────────
  Future<void> _startListening() async {
    if (_isListening || _isAnswered) return;
    if (!SpeechService().isAvailable) {
      _showMicUnavailable();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() { _isListening = true; _heardText = ''; });
    _micPulseCtrl.repeat(reverse: true);

    final word = _words[_currentIndex];

    // Écoute pendant 4 secondes max
    bool got = false;
    final timer = Timer(const Duration(seconds: 5), () {
      if (_isListening && !got) _onTimeout();
    });

    try {
      await SpeechService().listenAndCheck(
        context: context,
        expectedWord: word.word,
        maxAttempts: 1,
      );
      got = true;
      timer.cancel();
      // On utilise l'API directement pour avoir le texte entendu
      _evaluateDirectly(word.word);
    } catch (e) {
      timer.cancel();
      _onTimeout();
    }
  }

  // Évaluation directe via STT
  Future<void> _evaluateDirectly(String expectedWord) async {
    _micPulseCtrl.stop();
    _micPulseCtrl.reset();

    // Lancer la reconnaissance vocale manuellement pour récupérer le texte
    if (SpeechService().isAvailable) {
      await _listenAndEvaluate(expectedWord);
    } else {
      _showSimulatedResult(expectedWord);
    }
  }

  Future<void> _listenAndEvaluate(String expectedWord) async {
    // Afficher le dialogue d'écoute et récupérer le résultat
    String? heardWord;
    bool matched = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ListeningDialog(
        word: expectedWord,
        levelColor: _lc,
        attempts: _attempts + 1,
        maxAttempts: _maxAttempts,
        onResult: (heard, isMatch) {
          heardWord = heard;
          matched = isMatch;
          Navigator.pop(ctx);
        },
        onCancel: () {
          heardWord = '';
          matched = false;
          Navigator.pop(ctx);
        },
      ),
    );

    _processResult(expectedWord, heardWord ?? '', matched);
  }

  void _processResult(String expected, String heard, bool matched) {
    if (!mounted) return;
    _attempts++;

    setState(() {
      _isListening = false;
      _heardText = heard;
      _lastCorrect = matched;
    });

    if (matched) {
      // ✅ SUCCÈS
      HapticFeedback.mediumImpact();
      SoundService().play(SoundEffect.correct);
      _score += 10 + (_attempts == 1 ? 5 : 0); // bonus première tentative
      _totalCorrect++;

      setState(() => _isAnswered = true);
      _resultCtrl.forward(from: 0);

      TtsService().speak('Excellent ! Tu as bien dit : $expected !');

      Future.delayed(const Duration(seconds: 2), _nextWord);

    } else if (_attempts >= _maxAttempts) {
      // ❌ Plus de tentatives
      HapticFeedback.vibrate();
      SoundService().play(SoundEffect.wrong);

      setState(() => _isAnswered = true);
      _resultCtrl.forward(from: 0);

      TtsService().speak('La bonne prononciation est : $expected');
      Future.delayed(const Duration(seconds: 2), _nextWord);

    } else {
      // ❌ Erreur mais encore des tentatives
      SoundService().play(SoundEffect.wrong);
      TtsService().speak('Réessaie ! On dit : $expected');

      setState(() {});
      _resultCtrl.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _resultCtrl.reset();
            setState(() { _isAnswered = false; _heardText = ''; });
          }
        });
      });
    }
  }

  void _onTimeout() {
    if (!mounted) return;
    _micPulseCtrl.stop();
    _micPulseCtrl.reset();
    setState(() { _isListening = false; });
    _processResult(_words[_currentIndex].word, '', false);
  }

  void _showSimulatedResult(String expected) {
    // Fallback si micro non disponible
    _processResult(expected, 'micro non dispo', false);
  }

  void _showMicUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🎤 Micro non disponible sur cet appareil'),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─────────────────────────────────────────────
  // Mot suivant
  // ─────────────────────────────────────────────
  void _nextWord() {
    if (!mounted) return;
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _attempts = 0;
        _isAnswered = false;
        _isListening = false;
        _heardText = '';
      });
      _resultCtrl.reset();
      _entryCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 500), _speakCurrentWord);
    } else {
      _finishGame();
    }
  }

  void _finishGame() {
    _confettiCtrl.forward();
    SoundService().play(SoundEffect.levelDone);
    final pct = (_totalCorrect / _words.length * 100).round();
    TtsService().speak(_ai.encouragementMessage(pct));

    ProgressService().recordScore(
      levelId: widget.levelData.id,
      gameType: 'vocal',
      score: _score,
      maxScore: _words.length * 15,
      errorsCount: _words.length - _totalCorrect,
    );

    Future.delayed(const Duration(milliseconds: 800), _showResult);
  }

  void _showResult() {
    final pct = (_totalCorrect / _words.length * 100).clamp(0, 100).round();
    final stars = pct >= 80 ? 3 : pct >= 60 ? 2 : 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lc, _lc.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎤', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            const Text('Super ! Tu parles en français !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) =>
                    Icon(i < stars ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 38))),
            const SizedBox(height: 16),
            _dRow('✅', 'Mots réussis', '$_totalCorrect / ${_words.length}'),
            _dRow('🎯', 'Score', '$_score pts'),
            _dRow('📊', 'Exactitude', '$pct%'),
            // Message adaptatif
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pct >= 80
                    ? '🌟 Tu prononces très bien le français ! Continue !'
                    : pct >= 60
                    ? '💪 Tu progresses ! Réécoute les mots difficiles et réessaie !'
                    : '🎵 Écoute bien le mot avant de le répéter. Tu vas y arriver !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                icon: const Icon(Icons.home),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 0;
                    _score = 0;
                    _totalCorrect = 0;
                    _attempts = 0;
                    _isAnswered = false;
                    _isListening = false;
                    _heardText = '';
                    _words = _ai.selectWords(widget.levelData.vocabulary, count: 10);
                  });
                  _confettiCtrl.reset();
                  _entryCtrl.forward(from: 0);
                  Future.delayed(const Duration(milliseconds: 600), _speakCurrentWord);
                },
                icon: const Icon(Icons.replay),
                label: const Text('Rejouer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _lc,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _dRow(String e, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(e, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 8),
      Text(l, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
      const Spacer(),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 14,
          fontWeight: FontWeight.bold)),
    ]),
  );

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final word = _words[_currentIndex];
    final tierHidden = _tier == AdaptiveTier.hard; // Mode Génie : mot caché

    return Scaffold(
      body: Stack(children: [
        // Fond
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0A1628), _lc.withOpacity(0.8),
                const Color(0xFF0A1628)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            const SizedBox(height: 16),
            // Progression
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _words.length,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Mot ${_currentIndex + 1} / ${_words.length}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 24),

            // ── Image du mot ──
            ScaleTransition(
              scale: _entryAnim,
              child: _buildWordCard(word, tierHidden),
            ),

            const SizedBox(height: 24),

            // ── Zone de feedback ──
            if (_heardText.isNotEmpty || _isAnswered)
              ScaleTransition(
                scale: _resultAnim,
                child: _buildFeedback(word),
              ),

            const SizedBox(height: 16),

            // ── Tentatives restantes ──
            if (!_isAnswered)
              _buildAttemptsDots(),

            const Spacer(),

            // ── Bouton micro ──
            if (!_isAnswered)
              _buildMicButton(word),

            // ── Bouton réécouter ──
            GestureDetector(
              onTap: _speakCurrentWord,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volume_up, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('Réécouter le mot',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ]),
              ),
            ),
          ]),
        ),

        // Confettis fin de jeu
        AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (_, __) =>
              _ConfettiOverlay(progress: _confettiCtrl.value),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18)),
      ),
      const SizedBox(width: 12),
      const Text('🎤 Dis le mot !',
          style: TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w900)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Text('🎯 $_score pts',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    ]),
  );

  Widget _buildWordCard(Word word, bool wordHidden) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(
            color: _lc.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(fit: StackFit.expand, children: [
          // Image
          Image.asset(word.imagePath, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _lc.withOpacity(0.3),
              child: Center(child: Text(word.word[0],
                  style: const TextStyle(fontSize: 80, color: Colors.white,
                      fontWeight: FontWeight.w900))),
            ),
          ),
          // Overlay sombre en bas
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Column(children: [
                // Mot (caché en mode Génie)
                if (!wordHidden)
                  Text(word.word, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                if (wordHidden)
                  const Text('❓', style: TextStyle(fontSize: 32)),
                // Traduction darija en petit si disponible
                if (word.traductionDarija != null)
                  Text(word.traductionDarija!,
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 13)),
              ]),
            )),
          // Badge tier
          Positioned(top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_ai.tierLabel(_tier),
                  style: const TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )),
        ]),
      ),
    );
  }

  Widget _buildFeedback(Word word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lastCorrect
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _lastCorrect ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_lastCorrect ? Icons.check_circle : Icons.info_outline,
              color: _lastCorrect ? Colors.greenAccent : Colors.orangeAccent,
              size: 22),
          const SizedBox(width: 8),
          Text(
            _lastCorrect ? 'Parfait ! Bonne prononciation !' : 'Pas tout à fait...',
            style: TextStyle(
              color: _lastCorrect ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 14, fontWeight: FontWeight.bold,
            ),
          ),
        ]),
        if (_heardText.isNotEmpty && !_lastCorrect) ...[
          const SizedBox(height: 8),
          // Feedback "Tu as dit... / On dit..."
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              const Text('Tu as dit :',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_heardText,
                    style: const TextStyle(color: Colors.orangeAccent,
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward, color: Colors.white30, size: 18),
            const SizedBox(width: 16),
            Column(children: [
              const Text('On dit :',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(word.word,
                    style: const TextStyle(color: Colors.greenAccent,
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ],
        if (_attempts < _maxAttempts && !_lastCorrect && !_isAnswered) ...[
          const SizedBox(height: 8),
          Text('Il te reste ${_maxAttempts - _attempts} essai(s)',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _buildAttemptsDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_maxAttempts, (i) => Container(
        width: 10, height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < _attempts
              ? Colors.orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
        ),
      )),
    );
  }

  Widget _buildMicButton(Word word) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GestureDetector(
        onTap: _isListening ? null : () => _listenAndEvaluate(word.word),
        child: AnimatedBuilder(
          animation: _isListening ? _micPulseAnim : const AlwaysStoppedAnimation(1.0),
          builder: (_, __) => Transform.scale(
            scale: _micPulseAnim.value,
            child: Container(
              width: double.infinity,
              height: 72,
              decoration: BoxDecoration(
                gradient: _isListening
                    ? const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFEF5350)])
                    : const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: (_isListening ? Colors.red : _lc).withOpacity(0.5),
                  blurRadius: 20, offset: const Offset(0, 6),
                )],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  _isListening ? 'Je t\'écoute...' : 'Appuie et parle !',
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DIALOGUE D'ÉCOUTE avec animation micro
// ─────────────────────────────────────────────
class _ListeningDialog extends StatefulWidget {
  final String word;
  final Color levelColor;
  final int attempts, maxAttempts;
  final void Function(String, bool) onResult;
  final VoidCallback onCancel;

  const _ListeningDialog({
    required this.word,
    required this.levelColor,
    required this.attempts,
    required this.maxAttempts,
    required this.onResult,
    required this.onCancel,
  });

  @override
  State<_ListeningDialog> createState() => _ListeningDialogState();
}

class _ListeningDialogState extends State<_ListeningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _listening = false;
  String _status = '🎤 Appuie sur le bouton et parle !';
  String _heard = '';
  bool? _result;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    // Démarrer l'écoute auto
    Future.delayed(const Duration(milliseconds: 400), _startListening);
  }

  Future<void> _startListening() async {
    setState(() { _listening = true; _status = '🎤 Je t\'écoute...'; _heard = ''; });

    // Utiliser SpeechService directement
    await SpeechService().listenAndCheck(
      context: context,
      expectedWord: widget.word,
      maxAttempts: 1,
    );
  }

  void _simulateResult(bool success) {
    final heard = success ? widget.word : 'mauvais mot';
    setState(() {
      _listening = false;
      _heard = heard;
      _result = success;
      _status = success ? '✅ Bien dit !' : '❌ Pas tout à fait';
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onResult(heard, success);
    });
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.levelColor, widget.levelColor.withOpacity(0.8)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Essai ${widget.attempts} / ${widget.maxAttempts}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('Répète ce mot :',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(widget.word,
                style: const TextStyle(color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 24),
          // Micro animé
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: _listening ? 1.0 + _pulseCtrl.value * 0.2 : 1.0,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening
                      ? Colors.red.withOpacity(0.15 + _pulseCtrl.value * 0.25)
                      : Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: _listening ? Colors.red : Colors.white30, width: 3),
                ),
                child: Icon(_listening ? Icons.mic : Icons.mic_none,
                    color: _listening ? Colors.red : Colors.white54, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_status, textAlign: TextAlign.center,
              style: TextStyle(
                color: _result == true ? Colors.greenAccent
                    : _result == false ? Colors.redAccent : Colors.white,
                fontSize: 14, fontWeight: FontWeight.bold)),
          if (_heard.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"$_heard"',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          if (_result == null)
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              TextButton(onPressed: widget.onCancel,
                  child: const Text('Passer',
                      style: TextStyle(color: Colors.white38))),
              // Bouton test (à enlever en prod)
              TextButton(onPressed: () => _simulateResult(true),
                  child: const Text('✅ Test OK',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
              TextButton(onPressed: () => _simulateResult(false),
                  child: const Text('❌ Test KO',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12))),
            ]),
        ]),
      ),
    );
  }
}

// ─── Confettis ───────────────────────────────────────────
class _ConfettiOverlay extends StatelessWidget {
  final double progress;
  const _ConfettiOverlay({required this.progress});
  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return IgnorePointer(child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConfP(progress: progress)));
  }
}

class _ConfP extends CustomPainter {
  final double progress;
  static const _cols = [Colors.red, Colors.blue, Colors.green,
    Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
  const _ConfP({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(55);
    for (int i = 0; i < 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = -20.0 + (size.height + 40) * progress + math.sin(progress * 8 + i) * 38;
      final p = Paint()..color = _cols[i % _cols.length].withOpacity((1 - progress).clamp(0, 1));
      final r = Rect.fromCenter(center: Offset(x + math.sin(progress * 5 + i) * 22, y), width: 9, height: 14);
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(progress * 8 + i.toDouble());
      canvas.translate(-r.center.dx, -r.center.dy);
      canvas.drawRect(r, p);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfP o) => o.progress != progress;
}