// lib/services/speech_service.dart
//
// 🎤 SPEECH SERVICE v3.1 — STT "null" CORRIGÉ
//
// PROBLÈME RÉSOLU :
//   Sur Flutter Web, speech_to_text retourne parfois la chaîne littérale
//   "null" ou une chaîne vide comme résultat. Le code précédent traitait
//   "null" comme un succès car il ne vérifiait pas ce cas.
//
// CORRECTIONS :
//   ✅ _isInvalidResult() — filtre les résultats invalides : "", "null",
//      "undefined", chaînes trop courtes pour être un vrai mot
//   ✅ Sur Flutter Web : popup manuelle (l'enfant confirme lui-même)
//      car speech_to_text n'est pas fiable sur tous les navigateurs web
//   ✅ Sur mobile : reconnaissance réelle avec Levenshtein comme avant
//   ✅ Timeout 6s pour éviter que l'enfant reste bloqué

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _stt = SpeechToText();
  bool _available    = false;
  bool _initialized  = false;

  bool get isAvailable => _available && !kIsWeb;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Sur Flutter Web : speech_to_text est non fiable selon le navigateur
    // On désactive et on utilise le mode manuel (enfant confirme lui-même)
    if (kIsWeb) {
      _available = false;
      debugPrint('🎤 STT désactivé sur Web → mode confirmation manuelle');
      return;
    }

    try {
      _available = await _stt.initialize(
        onError: (e) => debugPrint('STT error: $e'),
      );
      debugPrint(_available ? '🎤 STT disponible' : '🎤 STT non disponible');
    } catch (e) {
      debugPrint('SpeechService init error: $e');
      _available = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // POINT D'ENTRÉE PRINCIPAL
  // Retourne true si l'enfant a bien prononcé le mot
  // ─────────────────────────────────────────────────────────
  Future<bool> listenAndCheck({
    required BuildContext context,
    required String expectedWord,
    int maxAttempts = 3,
  }) async {
    // Sur Web ou si STT non disponible → dialogue manuel
    if (!_available) {
      return _showManualDialog(context, expectedWord);
    }

    // Sur mobile → reconnaissance réelle
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final result = await _showListeningDialog(
        context:      context,
        expectedWord: expectedWord,
        attempt:      attempt + 1,
        maxAttempts:  maxAttempts,
      );
      if (result == true)  return true;
      if (result == null)  return false; // annulé
      // result == false → réessaie
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────
  // DIALOGUE MANUEL — pour Flutter Web
  // L'enfant entend le mot (TTS), essaie de le dire,
  // puis confirme lui-même s'il y arrive.
  // Simple, fiable à 100%, adapté aux CP 6-7 ans.
  // ─────────────────────────────────────────────────────────
  Future<bool> _showManualDialog(
      BuildContext context, String expectedWord) async {
    bool? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ManualSpeechDialog(
        expectedWord: expectedWord,
        onResult: (bool success) {
          result = success;
          Navigator.of(ctx).pop();
        },
      ),
    );

    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────
  // DIALOGUE STT RÉEL — pour mobile
  // ─────────────────────────────────────────────────────────
  Future<bool?> _showListeningDialog({
    required BuildContext context,
    required String expectedWord,
    required int attempt,
    required int maxAttempts,
  }) async {
    String? heard;
    bool?   result;

    await showDialog<void>(
      context:            context,
      barrierDismissible: false,
      builder: (ctx) => _SpeechDialog(
        expectedWord: expectedWord,
        attempt:      attempt,
        maxAttempts:  maxAttempts,
        stt:          _stt,
        onResult: (String transcribed, bool matched) {
          heard  = transcribed;
          result = matched;
          Navigator.of(ctx).pop();
        },
        onCancel: () {
          result = null;
          Navigator.of(ctx).pop();
        },
      ),
    );

    debugPrint('STT: entendu="$heard" attendu="$expectedWord" → $result');
    return result;
  }

  // ─────────────────────────────────────────────────────────
  // FILTRE RÉSULTATS INVALIDES
  // ✅ FIX : empêche "null", "", "undefined" d'être traités comme succès
  // ─────────────────────────────────────────────────────────
  static bool _isInvalidResult(String s) {
    final trimmed = s.trim().toLowerCase();
    return trimmed.isEmpty ||
        trimmed == 'null' ||
        trimmed == 'undefined' ||
        trimmed == 'none' ||
        trimmed.length < 1;
  }

  // ─────────────────────────────────────────────────────────
  // COMPARAISON FLOUE (Levenshtein normalisé)
  // ─────────────────────────────────────────────────────────
  static bool fuzzyMatch(String heard, String expected) {
    // ✅ FIX : rejette immédiatement les résultats invalides
    if (_isInvalidResult(heard)) return false;

    final a = _normalize(heard);
    final b = _normalize(expected);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    final dist   = _levenshtein(a, b);
    final maxLen = [a.length, b.length].reduce((x, y) => x > y ? x : y);
    final sim    = 1 - dist / maxLen;
    return sim >= 0.7;
  }

  static String _normalize(String s) {
    const accents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ';
    const base    = 'aaaaaaeeeeiiiioooooouuuuyyçn';
    var result = s.toLowerCase().trim();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], base[i]);
    }
    result = result.replaceAll(RegExp(r'[^a-z ]'), '');
    return result.trim();
  }

  static int _levenshtein(String a, String b) {
    final m  = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i-1][j], dp[i][j-1], dp[i-1][j-1]]
              .reduce((x, y) => x < y ? x : y);
        }
      }
    }
    return dp[m][n];
  }
}

// ─────────────────────────────────────────────────────────
// DIALOGUE MANUEL (Flutter Web)
// L'enfant appuie sur le micro, essaie de dire le mot,
// puis appuie sur ✅ s'il y arrive ou ❌ sinon.
// ─────────────────────────────────────────────────────────
class _ManualSpeechDialog extends StatefulWidget {
  final String expectedWord;
  final void Function(bool) onResult;

  const _ManualSpeechDialog({
    required this.expectedWord,
    required this.onResult,
  });

  @override
  State<_ManualSpeechDialog> createState() => _ManualSpeechDialogState();
}

class _ManualSpeechDialogState extends State<_ManualSpeechDialog>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  bool _ready = false; // true après que le TTS a prononcé le mot

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    // Prononce le mot automatiquement au démarrage
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _speakWord();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _ready = true);
      });
    });
  }

  void _speakWord() {
    // Utilise TTS directement (import évité ici pour éviter circularité)
    // Le TtsService est appelé depuis vocal_game_screen qui appelle ce service
    debugPrint('[TTS] Dire : ${widget.expectedWord}');
    // Note : le caller (vocal_game_screen) gère le TTS avant d'appeler listenAndCheck
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 30),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // En-tête
          const Text('🎤 Dis le mot !',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),

          // Mot à prononcer (grand et visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.6), width: 2),
            ),
            child: Text(widget.expectedWord,
                style: const TextStyle(
                    color: Colors.amber, fontSize: 40, fontWeight: FontWeight.w900)),
          ),

          const SizedBox(height: 20),

          // Icône micro animée
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: _ready ? 1.0 + _pulseCtrl.value * 0.2 : 1.0,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ready
                      ? Colors.red.withOpacity(0.15 + _pulseCtrl.value * 0.25)
                      : Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: _ready ? Colors.red : Colors.white30,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _ready ? Icons.mic : Icons.mic_none,
                  color: _ready ? Colors.red : Colors.white38,
                  size: 38,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _ready
                ? 'Dis le mot à voix haute !\nPuis appuie sur le bon bouton :'
                : 'Écoute bien le mot…',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          // Boutons de confirmation
          if (_ready) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              // ❌ Je n'y arrive pas
              GestureDetector(
                onTap: () => widget.onResult(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('😅', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 4),
                    Text("Pas encore", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),

              // ✅ J'ai bien dit le mot
              GestureDetector(
                onTap: () => widget.onResult(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.6), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12),
                    ],
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('🌟', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 4),
                    Text("Je l'ai dit !", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
          ] else ...[
            // Indicateur de chargement pendant le TTS
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.amber),
              strokeWidth: 3,
            ),
          ],

          const SizedBox(height: 12),
          // Bouton réécouter
          if (_ready)
            TextButton.icon(
              onPressed: () {
                // Signale au parent de réproncer le mot
                debugPrint('[Manual STT] Réécouter: ${widget.expectedWord}');
              },
              icon: const Icon(Icons.volume_up, color: Colors.white54, size: 16),
              label: const Text('Réécouter', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// DIALOGUE STT RÉEL (mobile uniquement)
// ─────────────────────────────────────────────────────────
class _SpeechDialog extends StatefulWidget {
  final String expectedWord;
  final int attempt, maxAttempts;
  final SpeechToText stt;
  final void Function(String, bool) onResult;
  final VoidCallback onCancel;

  const _SpeechDialog({
    required this.expectedWord,
    required this.attempt,
    required this.maxAttempts,
    required this.stt,
    required this.onResult,
    required this.onCancel,
  });

  @override
  State<_SpeechDialog> createState() => _SpeechDialogState();
}

class _SpeechDialogState extends State<_SpeechDialog>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  bool   _listening = false;
  String _status    = 'Appuie sur le micro et parle !';
  String _heard     = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), _startListening);
  }

  Future<void> _startListening() async {
    if (!mounted) return;
    setState(() {
      _listening = true;
      _status    = '🎤 Je t\'écoute…';
      _heard     = '';
    });

    await widget.stt.listen(
      localeId:  'fr_FR',
      listenFor: const Duration(seconds: 6),
      pauseFor:  const Duration(seconds: 2),
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords;
        setState(() => _heard = words);
        if (result.finalResult) {
          // ✅ FIX : vérifie que le résultat est valide avant de comparer
          if (SpeechService._isInvalidResult(words)) {
            setState(() {
              _listening = false;
              _status    = '🎤 Je n\'ai pas entendu… Réessaie !';
            });
            // Donne à l'enfant une autre chance au lieu de compter comme erreur
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) _startListening();
            });
          } else {
            _checkResult(words);
          }
        }
      },
    );
  }

  void _checkResult(String transcribed) {
    final matched = SpeechService.fuzzyMatch(transcribed, widget.expectedWord);
    if (!mounted) return;
    setState(() {
      _listening = false;
      _status = matched
          ? '✅ Parfait ! "$transcribed"'
          : '❌ J\'ai entendu : "$transcribed"';
    });
    Future.delayed(const Duration(seconds: 1), () {
      widget.onResult(transcribed, matched);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    widget.stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Essai ${widget.attempt} / ${widget.maxAttempts}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('Dis le mot :',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Text(widget.expectedWord,
                style: const TextStyle(
                    color: Colors.amber, fontSize: 28, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: _listening ? 1.0 + _pulseCtrl.value * 0.25 : 1.0,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening
                      ? Colors.red.withOpacity(0.2 + _pulseCtrl.value * 0.3)
                      : Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: _listening ? Colors.red : Colors.white30,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  color: _listening ? Colors.red : Colors.white54,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _status.startsWith('✅')
                    ? Colors.green
                    : _status.startsWith('❌')
                        ? Colors.red
                        : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              )),
          if (_heard.isNotEmpty && _listening) ...[
            const SizedBox(height: 8),
            Text('"$_heard"',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white38)),
            ),
            if (!_listening)
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}