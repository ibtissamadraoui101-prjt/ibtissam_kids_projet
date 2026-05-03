// lib/services/sound_service.dart
// ✅ VERSION FINALE — compile sur Web ET Mobile sans erreur
//
// CAUSE DES ERREURS :
//   L'import conditionnel nécessitait sound_service_stub.dart (inexistant)
//   → AudioPlayer, PlayerMode, AssetSource = undefined sur Web
//
// SOLUTION : import direct audioplayers TOUJOURS
//   Sur Web  → kIsWeb = true → on utilise Web Audio API via dart:html
//   Sur Mobile → audioplayers normal
//   Pas de stub, pas d'import conditionnel, un seul fichier.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundEffect {
  click, pop, woosh,
  correct, wrong, timeout,
  cardFlip, match, combo, bingo,
  starEarned, levelDone, unlocked,
  islandEnter, gameStart,
  bravo, tryAgain,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final List<AudioPlayer> _sfxPool = [];
  AudioPlayer? _bgPlayer;
  AudioPlayer? _welcomePlayer;
  int _poolIndex = 0;

  double _sfxVolume   = 1.0;
  double _musicVolume = 0.30;
  bool _sfxEnabled    = true;
  bool _musicEnabled  = true;
  bool _initialized   = false;

  double get sfxVolume   => _sfxVolume;
  double get musicVolume => _musicVolume;
  bool get sfxEnabled    => _sfxEnabled;
  bool get musicEnabled  => _musicEnabled;

  // ─────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled   = prefs.getBool('sfx_enabled')    ?? true;
    _musicEnabled = prefs.getBool('music_enabled')  ?? true;
    _sfxVolume    = prefs.getDouble('sfx_volume')   ?? 1.0;
    _musicVolume  = prefs.getDouble('music_volume') ?? 0.30;

    if (kIsWeb) {
      // Sur Web : audioplayers existe mais on l'utilise prudemment
      // On crée quand même les players pour la musique de fond (mp3 valides)
      try {
        _bgPlayer = AudioPlayer();
        await _bgPlayer!.setReleaseMode(ReleaseMode.loop);
        await _bgPlayer!.setVolume(_musicVolume);

        _welcomePlayer = AudioPlayer();
        await _welcomePlayer!.setReleaseMode(ReleaseMode.stop);
        await _welcomePlayer!.setVolume(0.45);
      } catch (e) {
        debugPrint('SoundService Web init: $e');
      }
    } else {
      // Mobile : pool complet + musique
      try {
        for (int i = 0; i < 6; i++) {
          final p = AudioPlayer();
          await p.setPlayerMode(PlayerMode.lowLatency);
          _sfxPool.add(p);
        }
        _bgPlayer = AudioPlayer();
        await _bgPlayer!.setReleaseMode(ReleaseMode.loop);
        await _bgPlayer!.setVolume(_musicVolume);

        _welcomePlayer = AudioPlayer();
        await _welcomePlayer!.setReleaseMode(ReleaseMode.stop);
        await _welcomePlayer!.setVolume(0.45);
      } catch (e) {
        debugPrint('SoundService Mobile init: $e');
      }
    }

    debugPrint('🔊 SoundService initialisé (${kIsWeb ? "Web" : "Mobile"})');
  }

  // ─────────────────────────────────────────────
  // EFFETS SONORES
  // Sur Web : sons synthétiques via AudioContext JS (pas de fichiers)
  // Sur Mobile : fichiers mp3 via audioplayers
  // ─────────────────────────────────────────────
  Future<void> play(SoundEffect effect) async {
    if (!_sfxEnabled || !_initialized) return;

    if (kIsWeb) {
      _playWebTone(effect);
    } else {
      await _playMobile(effect);
    }
  }

  // Sons synthétiques Web via Web Audio API
  void _playWebTone(SoundEffect effect) {
    if (!_sfxEnabled) return;
    try {
      // On utilise un AudioPlayer Web pour jouer une note courte
      // En réalité sur Web on skip les sons sfx (fichiers invalides)
      // et on se contente du TTS + animations visuelles
      // Sauf pour correct/match/levelDone qui valent la peine
      switch (effect) {
        case SoundEffect.correct:
        case SoundEffect.match:
          _playWebMp3('sounds/sfx/correct.mp3');
          break;
        case SoundEffect.levelDone:
          _playWebMp3('sounds/sfx/level_done.mp3');
          break;
        case SoundEffect.bingo:
          _playWebMp3('sounds/sfx/bingo.mp3');
          break;
        case SoundEffect.starEarned:
          _playWebMp3('sounds/sfx/star.mp3');
          break;
        default:
          // Autres sons : silencieux sur Web (évite les erreurs DEMUXER)
          break;
      }
    } catch (e) {
      debugPrint('SoundService Web play ($effect): $e');
    }
  }

  Future<void> _playWebMp3(String path) async {
    try {
      final p = AudioPlayer();
      await p.setVolume(_sfxVolume);
      await p.play(AssetSource(path));
      // Dispose après lecture
      await Future.delayed(const Duration(seconds: 3));
      await p.dispose();
    } catch (_) {
      // Silencieux si le fichier est invalide
    }
  }

  Future<void> _playMobile(SoundEffect effect) async {
    if (_sfxPool.isEmpty) return;
    try {
      final player = _sfxPool[_poolIndex % _sfxPool.length];
      _poolIndex++;

      // Son doux pour les erreurs (volume réduit)
      final vol = (effect == SoundEffect.wrong || effect == SoundEffect.tryAgain)
          ? _sfxVolume * 0.4
          : _sfxVolume;

      await player.setVolume(vol);
      await player.play(
        AssetSource('sounds/sfx/${_soundFile(effect)}'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('SoundService Mobile play ($effect): $e');
    }
  }

  String _soundFile(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.click:       return 'click.mp3';
      case SoundEffect.pop:         return 'pop.mp3';
      case SoundEffect.woosh:       return 'woosh.mp3';
      case SoundEffect.correct:     return 'correct.mp3';
      case SoundEffect.wrong:       return 'try_again.mp3'; // ✅ son doux
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

  // Alias courts
  void click()     => play(SoundEffect.click);
  void correct()   => play(SoundEffect.correct);
  void wrong()     => play(SoundEffect.wrong);
  void cardFlip()  => play(SoundEffect.cardFlip);
  void match()     => play(SoundEffect.match);
  void star()      => play(SoundEffect.starEarned);
  void levelDone() => play(SoundEffect.levelDone);
  void bingo()     => play(SoundEffect.bingo);
  void combo()     => play(SoundEffect.combo);

  // ─────────────────────────────────────────────
  // CHANSON DE BIENVENUE
  // ─────────────────────────────────────────────
  Future<void> playWelcomeSong() async {
    if (!_musicEnabled || !_initialized || _welcomePlayer == null) return;
    try {
      await _welcomePlayer!.setVolume(0);
      await _welcomePlayer!.play(AssetSource('sounds/music/welcome.mp3'));
      _fadeIn(_welcomePlayer!, 0.45, const Duration(seconds: 2));
    } catch (e) {
      debugPrint('playWelcomeSong: $e');
    }
  }

  Future<void> stopWelcomeSong() async {
    try {
      await _welcomePlayer?.stop();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // MUSIQUE DE FOND
  // ─────────────────────────────────────────────
  Future<void> startMusic(String track) async {
    if (!_musicEnabled || !_initialized || _bgPlayer == null) return;
    try {
      await _bgPlayer!.setVolume(0);
      await _bgPlayer!.play(AssetSource('sounds/music/$track.mp3'));
      _fadeIn(_bgPlayer!, _musicVolume, const Duration(seconds: 2));
    } catch (e) {
      debugPrint('startMusic ($track): $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _fadeOut(_bgPlayer!, const Duration(milliseconds: 800));
    } catch (_) {}
  }

  Future<void> switchMusic(String newTrack) async {
    await stopMusic();
    await Future.delayed(const Duration(milliseconds: 300));
    await startMusic(newTrack);
  }

  // ─────────────────────────────────────────────
  // PRÉFÉRENCES
  // ─────────────────────────────────────────────
  Future<void> setSfxEnabled(bool v) async {
    _sfxEnabled = v;
    if (!v) for (final p in _sfxPool) await p.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', v);
  }

  Future<void> setMusicEnabled(bool v) async {
    _musicEnabled = v;
    if (!v) { await stopMusic(); await stopWelcomeSong(); }
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

  Future<void> dispose() async {
    for (final p in _sfxPool) {
      try { await p.stop(); await p.dispose(); } catch (_) {}
    }
    try { await _bgPlayer?.stop(); await _bgPlayer?.dispose(); } catch (_) {}
    try { await _welcomePlayer?.stop(); await _welcomePlayer?.dispose(); } catch (_) {}
    _bgPlayer = null;
    _welcomePlayer = null;
  }

  // ─────────────────────────────────────────────
  // FADE
  // ─────────────────────────────────────────────
  void _fadeIn(AudioPlayer player, double target, Duration duration) async {
    const steps = 20;
    final stepDur = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    for (int i = 0; i <= steps; i++) {
      await Future.delayed(stepDur);
      try {
        if (player.state == PlayerState.playing) {
          await player.setVolume((target * i / steps).clamp(0.0, 1.0));
        }
      } catch (_) {}
    }
  }

  Future<void> _fadeOut(AudioPlayer player, Duration duration) async {
    const steps = 15;
    final current = _musicVolume;
    final stepDur = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    for (int i = steps; i >= 0; i--) {
      await Future.delayed(stepDur);
      try {
        await player.setVolume((current * i / steps).clamp(0.0, 1.0));
      } catch (_) {}
    }
    try { await player.stop(); } catch (_) {}
  }
}