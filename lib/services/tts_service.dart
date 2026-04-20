// lib/services/tts_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _i = TtsService._();
  factory TtsService() => _i;
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _available = false;

  bool get isAvailable => _available;
  FlutterTts get raw => _tts;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.1);
      _available = true;
      _ready = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
      _ready = true;
      _available = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_ready) await init();
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text.trim());
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}