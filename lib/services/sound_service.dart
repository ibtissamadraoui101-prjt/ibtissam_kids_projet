// lib/services/sound_service.dart
// 🔊 SERVICE AUDIO COMPLET
// • Effets sonores pour chaque action (clic, correct, erreur, étoile…)
// • Musique de fond douce en boucle
// • Volume adaptatif (son + musique indépendants)
// • Cache des players pour éviter la latence

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tous les sons disponibles dans l'application
enum SoundEffect {
  // ── Interactions UI ──────────────
  click,        // clic bouton générique       (très court, 80ms)
  pop,          // ouverture carte/menu        (150ms)
  woosh,        // fermeture / glissement      (200ms)

  // ── Jeux : feedback ──────────────
  correct,      // bonne réponse               (joyeux, 500ms)
  wrong,        // mauvaise réponse            (doux, 400ms)
  timeout,      // temps écoulé                (alarme douce, 600ms)

  // ── Jeux : progression ───────────
  cardFlip,     // retournement carte Memory   (whoosh court, 180ms)
  match,        // paire trouvée Memory        (petit fanfare, 700ms)
  combo,        // combo x3+                   (escalade joyeuse, 600ms)
  bingo,        // BINGO ! complet             (explosion joyeuse, 1.5s)

  // ── Récompenses ──────────────────
  starEarned,   // étoile gagnée               (scintillement, 800ms)
  levelDone,    // niveau complété             (fanfare complète, 2s)
  unlocked,     // île/niveau débloqué         (magique, 1.2s)

  // ── Navigation ───────────────────
  islandEnter,  // entrée dans une île         (son marin/aventure, 1s)
  gameStart,    // début d'un jeu              (compte à rebours, 0.8s)

  // ── Encouragement ────────────────
  bravo,        // encouragement vocal enfant  (bravo !, 0.5s)
  tryAgain,     // réessaie !                  (doux, 0.5s)
}

class SoundService {
  // Singleton
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Players
  final _sfxPool   = <AudioPlayer>[];    // pool de 6 players pour effets
  AudioPlayer?     _bgPlayer;            // player dédié à la musique de fond
  int              _poolIndex = 0;

  // Paramètres
  double  _sfxVolume   = 1.0;
  double  _musicVolume = 0.35;
  bool    _sfxEnabled  = true;
  bool    _musicEnabled = true;
  bool    _initialized = false;

  // Getters
  double get sfxVolume    => _sfxVolume;
  double get musicVolume  => _musicVolume;
  bool   get sfxEnabled   => _sfxEnabled;
  bool   get musicEnabled => _musicEnabled;

  // ─────────────────────────────────────────────
  // INITIALISATION
  // ─────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Charger les préférences sauvegardées
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled    = prefs.getBool('sfx_enabled')    ?? true;
    _musicEnabled  = prefs.getBool('music_enabled')  ?? true;
    _sfxVolume     = prefs.getDouble('sfx_volume')   ?? 1.0;
    _musicVolume   = prefs.getDouble('music_volume') ?? 0.35;

    // Créer le pool de 6 players SFX (pour sons simultanés)
    for (int i = 0; i < 6; i++) {
      final p = AudioPlayer();
      await p.setPlayerMode(PlayerMode.lowLatency);
      _sfxPool.add(p);
    }

    // Player musique de fond
    _bgPlayer = AudioPlayer();
    await _bgPlayer!.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer!.setVolume(_musicVolume);

    debugPrint('🔊 SoundService initialisé');
  }

  // ─────────────────────────────────────────────
  // JOUER UN EFFET SONORE
  // ─────────────────────────────────────────────
  Future<void> play(SoundEffect effect) async {
    if (!_sfxEnabled || !_initialized) return;

    try {
      // Rotation dans le pool pour éviter les conflits
      final player = _sfxPool[_poolIndex % _sfxPool.length];
      _poolIndex++;

      await player.setVolume(_sfxVolume);
      await player.play(
        AssetSource('sounds/sfx/${_soundFile(effect)}'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('SoundService play error ($effect): $e');
    }
  }

  // Alias courts pour les sons les plus utilisés
  void click()      => play(SoundEffect.click);
  void correct()    => play(SoundEffect.correct);
  void wrong()      => play(SoundEffect.wrong);
  void cardFlip()   => play(SoundEffect.cardFlip);
  void match()      => play(SoundEffect.match);
  void star()       => play(SoundEffect.starEarned);
  void levelDone()  => play(SoundEffect.levelDone);
  void bingo()      => play(SoundEffect.bingo);
  void combo()      => play(SoundEffect.combo);

  // ─────────────────────────────────────────────
  // MUSIQUE DE FOND
  // ─────────────────────────────────────────────

  /// Démarrer la musique de fond
  /// [track] : 'world_map', 'memory', 'quiz', 'bingo', 'celebration'
  Future<void> startMusic(String track) async {
    if (!_musicEnabled || !_initialized || _bgPlayer == null) return;
    try {
      await _bgPlayer!.setVolume(0); // fade in
      await _bgPlayer!.play(AssetSource('sounds/music/$track.mp3'));

      // Fade in sur 2 secondes
      _fadeIn(_bgPlayer!, _musicVolume, const Duration(seconds: 2));
    } catch (e) {
      debugPrint('SoundService startMusic error ($track): $e');
    }
  }

  /// Arrêter la musique avec fade out
  Future<void> stopMusic() async {
    if (_bgPlayer == null) return;
    try {
      await _fadeOut(_bgPlayer!, const Duration(milliseconds: 800));
    } catch (e) {
      debugPrint('SoundService stopMusic error: $e');
    }
  }

  /// Changer de musique avec crossfade
  Future<void> switchMusic(String newTrack) async {
    await stopMusic();
    await Future.delayed(const Duration(milliseconds: 400));
    await startMusic(newTrack);
  }

  // ─────────────────────────────────────────────
  // PARAMÈTRES (avec sauvegarde)
  // ─────────────────────────────────────────────

  Future<void> setSfxEnabled(bool v) async {
    _sfxEnabled = v;
    if (!v) for (final p in _sfxPool) await p.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', v);
  }

  Future<void> setMusicEnabled(bool v) async {
    _musicEnabled = v;
    if (!v) await stopMusic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', v);
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
  }

  Future<void> setMusicVolume(double v) async {
    _musicVolume = v.clamp(0.0, 1.0);
    _bgPlayer?.setVolume(_musicVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────
  Future<void> dispose() async {
    for (final p in _sfxPool) {
      await p.stop();
      await p.dispose();
    }
    await _bgPlayer?.stop();
    await _bgPlayer?.dispose();
    _bgPlayer = null;
  }

  // ─────────────────────────────────────────────
  // PRIVÉ — Mapping son → fichier
  // ─────────────────────────────────────────────
  String _soundFile(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.click:       return 'click.mp3';
      case SoundEffect.pop:         return 'pop.mp3';
      case SoundEffect.woosh:       return 'woosh.mp3';
      case SoundEffect.correct:     return 'correct.mp3';
      case SoundEffect.wrong:       return 'wrong.mp3';
      case SoundEffect.timeout:     return 'timeout.mp3';
      case SoundEffect.cardFlip:    return 'card_flip.mp3';
      case SoundEffect.match:       return 'match.mp3';
      case SoundEffect.combo:       return 'combo.mp3';
      case SoundEffect.bingo:       return 'bingo.mp3';
      case SoundEffect.starEarned:  return 'star.mp3';
      case SoundEffect.levelDone:   return 'level_done.mp3';
      case SoundEffect.unlocked:    return 'unlock.mp3';
      case SoundEffect.islandEnter: return 'island_enter.mp3';
      case SoundEffect.gameStart:   return 'game_start.mp3';
      case SoundEffect.bravo:       return 'bravo.mp3';
      case SoundEffect.tryAgain:    return 'try_again.mp3';
    }
  }

  // ─────────────────────────────────────────────
  // Fade in/out
  // ─────────────────────────────────────────────
  void _fadeIn(AudioPlayer player, double target, Duration duration) async {
    const steps = 20;
    final stepDur = Duration(
        milliseconds: duration.inMilliseconds ~/ steps);
    for (int i = 0; i <= steps; i++) {
      await Future.delayed(stepDur);
      if (player.state == PlayerState.playing) {
        await player.setVolume((target * i / steps).clamp(0.0, 1.0));
      }
    }
  }

  Future<void> _fadeOut(AudioPlayer player, Duration duration) async {
    final current = _musicVolume;
    const steps = 15;
    final stepDur = Duration(
        milliseconds: duration.inMilliseconds ~/ steps);
    for (int i = steps; i >= 0; i--) {
      await Future.delayed(stepDur);
      await player.setVolume((current * i / steps).clamp(0.0, 1.0));
    }
    await player.stop();
  }
}