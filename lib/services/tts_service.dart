// lib/services/tts_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_web.dart'
    if (dart.library.io) 'tts_mobile_stub.dart' as tts_platform;

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _mobileTts;
  bool _mobileReady = false;
  bool get isAvailable => true;

  FlutterTts get raw {
    _mobileTts ??= FlutterTts();
    return _mobileTts!;
  }

  Future<void> init() async {
    if (kIsWeb) {
      tts_platform.initWebTts();
      debugPrint('[TtsService] ✅ Mode WEB — dart:html speechSynthesis');
      return;
    }
    try {
      _mobileTts = FlutterTts();
      await _mobileTts!.setLanguage('fr-FR');
      await _mobileTts!.setSpeechRate(0.85);
      await _mobileTts!.setVolume(1.0);
      await _mobileTts!.setPitch(1.1);
      _mobileReady = true;
    } catch (e) {
      debugPrint('[TtsService] Erreur init mobile: $e');
    }
  }

  /// Appeler au 1er tap dans l'app pour débloquer Chrome
  void unlockAudio() {
    if (kIsWeb) tts_platform.unlockAudio();
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (kIsWeb) {
      tts_platform.webSpeak(text.trim());
    } else {
      await _speakMobile(text.trim());
    }
  }

  Future<void> _speakMobile(String text) async {
    if (!_mobileReady) await init();
    try {
      await _mobileTts?.stop();
      await _mobileTts?.speak(text);
    } catch (e) {
      debugPrint('[TtsService] Erreur speak mobile: $e');
    }
  }

  Future<void> stop() async {
    if (kIsWeb) {
      tts_platform.webStop();
    } else {
      try { await _mobileTts?.stop(); } catch (_) {}
    }
  }
}