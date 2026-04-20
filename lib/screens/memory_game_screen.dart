// lib/screens/memory_game_screen.
import '../services/progress_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../models/game_models.dart';
import '../services/tts_service.dart';
import '../services/progress_service.dart';
import '../services/adaptive_engine.dart';

class GameCard {
  final Word word;
  bool isFlipped;
  bool isMatched;
  GameCard({required this.word, this.isFlipped = false, this.isMatched = false});
}

// ══════════════════════════════════════════════════════════════════════════════
class MemoryGameScreen extends StatefulWidget {
  final GameLevelData levelData;
  const MemoryGameScreen({super.key, required this.levelData});
  @override State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<GameCard> cards;
  int score = 0, moves = 0;
  GameCard? first, second;
  bool checking = false;
  late stt.SpeechToText _speechToText;
  bool sttReady = false;
  final _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _build();
    _speechToText = stt.SpeechToText();
    _initStt();
  }

  void _build() {
    final words = widget.levelData.vocabulary.take(6).toList();
    final temp = [...words.map((w) => GameCard(word: w)), ...words.map((w) => GameCard(word: w))];
    temp.shuffle();
    cards = temp;
  }

  Future<void> _initStt() async {
    try {
      final ok = await _speechToText.initialize(
        onError: (e) => debugPrint('STT: $e'),
        onStatus: (s) => debugPrint('STT: $s'),
      );
      if (mounted) setState(() => sttReady = ok);
    } catch (_) {}
  }

  @override
  void dispose() {
    _speechToText.stop();
    _tts.stop();
    super.dispose();
  }

  void _onTap(int i) {
    if (checking || cards[i].isMatched || cards[i].isFlipped) return;
    setState(() => cards[i].isFlipped = true);
    if (first == null) {
      first = cards[i];
    } else if (cards[i] != first) {
      second = cards[i];
      checking = true;
      moves++;
      Future.delayed(const Duration(milliseconds: 600), _check);
    }
  }

  void _check() {
    if (first!.word.id == second!.word.id) {
      _tts.speak(first!.word.word);
      _showMatch(first!.word);
    } else {
      setState(() {
        cards[cards.indexOf(first!)].isFlipped = false;
        cards[cards.indexOf(second!)].isFlipped = false;
        first = null;
        second = null;
        checking = false;
      });
    }
  }

  void _showMatch(Word word) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MatchDialog(
        word: word,
        tts: _tts,
        onStart: () {
          Navigator.pop(_);
          _rep(word, 1);
        },
      ),
    );
  }

  void _rep(Word word, int n) {
    if (n > 3) {
      _success(word);
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RepDialog(
        word: word,
        repetitionNumber: n,
        speechToText: _speechToText,
        flutterTts: _tts.raw,
        sttReady: sttReady,
        ttsAvail: _tts.isAvailable,
        onSuccess: () {
          Navigator.pop(ctx);
          _rep(word, n + 1);
        },
        onRetry: () {
          Navigator.pop(ctx);
          _rep(word, n);
        },
      ),
    );
  }

  void _success(Word word) {
    final msgs = ['🎉 Paire gagnée !', '🌟 Bravo, continue !', '💪 Excellent travail !'];
    final msg = msgs[DateTime.now().millisecond % msgs.length];
    _tts.speak(msg);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green[50],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('✅  ${word.word}  —  ${word.traductionArabic ?? word.traductionDarija ?? ""}',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(_);
                _mark(word);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
              child: const Text('Continuer →', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  void _mark(Word word) {
    setState(() {
      for (var c in cards) {
        if (c.word.id == word.id) {
          c.isMatched = true;
          c.isFlipped = false;
        }
      }
      score++;
      first = null;
      second = null;
      checking = false;
    });
    if (cards.every((c) => c.isMatched)) {
      Future.delayed(const Duration(milliseconds: 400), _end);
    }
  }

  void _end() {

  // ── AJOUTER CES LIGNES ──────────────────────────
  ProgressService().recordScore(
    levelId: widget.levelData.id,
    gameType: 'memory',
    score: score,           // nombre de paires trouvées
    maxScore: cards.length ~/ 2,
  );
     _tts.speak(AdaptiveEngine().encouragementMessage(
    score * 100 ~/ (cards.length ~/ 2),
  ));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.amber[50],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Félicitations !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (_) => const Icon(Icons.star, color: Colors.amber, size: 36)),
            ),
            const SizedBox(height: 14),
            Text('Paires : $score  •  Coups : $moves',
                style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
              child: const Text('Retour', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = cards.length ~/ 2;
    return WillPopScope(
      onWillPop: () async => await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Quitter ?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuer')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitter')),
              ],
            ),
          ) ??
          false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Memory — ${widget.levelData.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('$score/$total  •  $moves coups', style: const TextStyle(fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: score / total,
              minHeight: 6,
              backgroundColor: Colors.blue[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                itemCount: cards.length,
                itemBuilder: (_, i) => _buildCard(cards[i], i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(GameCard card, int i) {
    final show = card.isFlipped || card.isMatched;
    return GestureDetector(
      onTap: () => _onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green[100]
              : card.isFlipped
                  ? Colors.blue[50]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: card.isMatched
                ? Colors.green
                : card.isFlipped
                    ? const Color(0xFF1565C0)
                    : Colors.grey[350]!,
            width: 2.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: show
            ? Stack(
                children: [
                  Center(child: Text(card.word.emoji, style: const TextStyle(fontSize: 48))),
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Text(
                      card.word.word,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  if (card.isMatched)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              )
            : Center(child: Icon(Icons.help_outline, size: 40, color: Colors.grey[500])),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _MatchDialog extends StatelessWidget {
  final Word word;
  final TtsService tts;
  final VoidCallback onStart;
  const _MatchDialog({required this.word, required this.tts, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.green[50],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 40)),
          const Text('Bonne paire !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 14),
          Text(word.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 6),
          Text(word.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
            child: Text(
              word.traductionArabic ?? word.traductionDarija ?? '',
              style: const TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => tts.speak(word.word),
            icon: const Icon(Icons.volume_up),
            label: const Text('Écouter encore'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.green[700]),
          ),
          const SizedBox(height: 6),
          Text(
            'Répète le mot 3 fois pour valider !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.mic, color: Colors.white),
            label: const Text('Commencer la répétition', style: TextStyle(color: Colors.white, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _RepDialog extends StatefulWidget {
  final Word word;
  final int repetitionNumber;
  final stt.SpeechToText speechToText;
  final FlutterTts flutterTts;
  final bool sttReady;
  final bool ttsAvail;
  final VoidCallback onSuccess;
  final VoidCallback onRetry;

  const _RepDialog({
    required this.word,
    required this.repetitionNumber,
    required this.speechToText,
    required this.flutterTts,
    required this.sttReady,
    required this.ttsAvail,
    required this.onSuccess,
    required this.onRetry,
  });

  @override
  State<_RepDialog> createState() => _RepDialogState();
}

class _RepDialogState extends State<_RepDialog> with SingleTickerProviderStateMixin {
  bool ttsOn = false;
  bool ready = false;
  bool listening = false;
  Timer? _timer;
  late AnimationController _wCtrl;
  late Animation<double> _wAnim;

  @override
  void initState() {
    super.initState();
    _wCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _wAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _wCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _playTts());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wCtrl.dispose();
    widget.speechToText.stop();
    super.dispose();
  }

  Future<void> _playTts() async {
    if (!widget.ttsAvail) {
      if (mounted) setState(() {
        ttsOn = false;
        ready = true;
      });
      return;
    }
    if (mounted) setState(() {
      ttsOn = true;
      ready = false;
    });
    widget.flutterTts.setCompletionHandler(() {
      if (mounted) setState(() {
        ttsOn = false;
        ready = true;
      });
    });
    widget.flutterTts.setErrorHandler((_) {
      if (mounted) setState(() {
        ttsOn = false;
        ready = true;
      });
    });
    try {
      await widget.flutterTts.stop();
      await widget.flutterTts.speak(
        widget.repetitionNumber == 1 ? 'Répète ce mot : ${widget.word.word}' : widget.word.word,
      );
    } catch (_) {
      if (mounted) setState(() {
        ttsOn = false;
        ready = true;
      });
    }
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && ttsOn) setState(() {
        ttsOn = false;
        ready = true;
      });
    });
  }

  Future<void> _replayTts() async {
    if (listening) return;
    setState(() {
      ttsOn = true;
      ready = false;
    });
    await widget.flutterTts.stop();
    await widget.flutterTts.speak(widget.word.word);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && ttsOn) setState(() {
        ttsOn = false;
        ready = true;
      });
    });
  }

  Future<void> _listen() async {
    if (!widget.sttReady || listening || ttsOn || !ready) return;
    setState(() => listening = true);
    await widget.flutterTts.stop();
    _timer = Timer(const Duration(seconds: 8), () async {
      if (listening) {
        await _stop();
        _snack('Délai dépassé !', Colors.orange);
        widget.onRetry();
      }
    });
    try {
      await widget.speechToText.listen(
        onResult: (r) {
          if (r.finalResult && mounted) {
            _stop();
            final rec = r.recognizedWords.toLowerCase().trim();
            if (_match(rec, widget.word.word.toLowerCase())) {
              _snack('Bravo ! Répétition ${widget.repetitionNumber}/3 ✓', Colors.green);
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 600), widget.onSuccess);
            } else {
              _snack('Réessaie !', Colors.orange);
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 600), widget.onRetry);
            }
          }
        },
        localeId: 'fr-FR',
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: false,
      );
    } catch (_) {
      await _stop();
      widget.onRetry();
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    if (listening) {
      await widget.speechToText.stop();
      if (mounted) setState(() => listening = false);
    }
  }

  bool _match(String a, String b) {
    final na = _norm(a), nb = _norm(b);
    return na.contains(nb) || nb.contains(na) || _lev(na, nb) <= 2;
  }

  String _norm(String s) {
    const f = 'àâäæçéèêëìîïòôöœùûüñ';
    const t = 'aaaaaaceeeeiioooeuuun';
    var r = s.toLowerCase();
    for (int i = 0; i < f.length; i++) r = r.replaceAll(f[i], t[i]);
    return r.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  int _lev(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    List<int> p = List.generate(b.length + 1, (i) => i);
    for (int i = 0; i < a.length; i++) {
      List<int> c = [i + 1, ...List.filled(b.length, 0)];
      for (int j = 0; j < b.length; j++) {
        c[j + 1] = a[i] == b[j] ? p[j] : 1 + [p[j], p[j + 1], c[j]].reduce((x, y) => x < y ? x : y);
      }
      p = c;
    }
    return p[b.length];
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 15)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.blue[50],
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          ...List.generate(3, (i) {
            final done = i < widget.repetitionNumber - 1;
            final cur = i == widget.repetitionNumber - 1;
            return Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: done ? Colors.green : cur ? const Color(0xFF1565C0) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text('${i + 1}', style: TextStyle(color: cur ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            );
          }),
          const SizedBox(width: 8),
          Text(
            'Répétition ${widget.repetitionNumber}/3',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue[200]!, width: 2),
            ),
            child: Column(
              children: [
                Text(widget.word.emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                Text(
                  widget.word.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1565C0), letterSpacing: 1.5),
                ),
                if (widget.word.traductionArabic != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.word.traductionArabic!, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _statusBox(),
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        if (widget.ttsAvail && !listening)
          IconButton(
            onPressed: ttsOn ? null : _replayTts,
            icon: Icon(Icons.replay, color: ttsOn ? Colors.grey[400] : const Color(0xFF1565C0)),
            tooltip: 'Réécouter',
          ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _action(),
          icon: Icon(_icon()),
          label: Text(_label()),
          style: ElevatedButton.styleFrom(
            backgroundColor: _color(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _statusBox() {
    if (ttsOn) {
      return _box(
        Colors.purple[50]!,
        Colors.purple[200]!,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volume_up, color: Colors.purple[700], size: 20),
            const SizedBox(width: 8),
            Text('Écoute la prononciation…', style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _wAnim,
              builder: (_, __) => Row(
                children: List.generate(
                  4,
                  (i) {
                    const hs = [10.0, 16.0, 12.0, 18.0];
                    return Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: hs[i] * _wAnim.value,
                      decoration: BoxDecoration(color: Colors.purple[400], borderRadius: BorderRadius.circular(2)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (listening) {
      return _box(
        Colors.red[50]!,
        Colors.red[200]!,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _wAnim,
              builder: (_, __) => Icon(Icons.mic, color: Colors.red.withOpacity(0.4 + 0.6 * _wAnim.value), size: 22),
            ),
            const SizedBox(width: 8),
            Text('Je t\'écoute !', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (ready) {
      return _box(
        Colors.green[50]!,
        Colors.green[200]!,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: Colors.green[700], size: 20),
            const SizedBox(width: 8),
            Text('Appuie sur "Parler !"', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return _box(
      Colors.grey[100]!,
      Colors.grey[300]!,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[500])),
          const SizedBox(width: 8),
          Text('Préparation…', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _box(Color bg, Color border, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
        child: child,
      );

  VoidCallback? _action() {
    if (ttsOn || !ready) return null;
    if (listening) return _stop;
    return _listen;
  }

  IconData _icon() {
    if (ttsOn) return Icons.volume_up;
    if (listening) return Icons.stop;
    return Icons.mic;
  }

  String _label() {
    if (ttsOn) return 'Écoute…';
    if (listening) return 'Arrêter';
    if (ready) return 'Parler !';
    return 'Patiente…';
  }

  Color _color() {
    if (ttsOn) return Colors.grey;
    if (listening) return Colors.red;
    if (ready) return const Color(0xFF1565C0);
    return Colors.grey;
  }
}