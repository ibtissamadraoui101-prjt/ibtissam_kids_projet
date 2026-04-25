// lib/services/tts_web.dart
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

web.SpeechSynthesisVoice? _frenchVoice;
bool _voicesLoaded = false;
bool _unlocked = false;

void _loadVoices() {
  try {
    // ── CORRECTION : .toDart convertit JSArray en List Dart ──
    final voicesList = web.window.speechSynthesis.getVoices().toDart;
    if (voicesList.isEmpty) return;

    const priorities = ['fr-fr', 'fr-ca', 'fr-be', 'fr'];

    for (final lang in priorities) {
      for (final v in voicesList) {
        if (v.lang.toLowerCase().startsWith(lang)) {
          _frenchVoice = v;
          debugPrint('[TTS Web] ✅ Voix: ${v.name} (${v.lang})');
          break;
        }
      }
      if (_frenchVoice != null) break;
    }

    _voicesLoaded = true;

    if (_frenchVoice == null) {
      debugPrint('[TTS Web] ⚠️ Aucune voix fr trouvée');
    }
  } catch (e) {
    debugPrint('[TTS Web] Erreur chargement voix: $e');
  }
}

void initWebTts() {
  try {
    web.window.speechSynthesis.addEventListener(
      'voiceschanged',
      (web.Event _) { _loadVoices(); }.toJS,
    );
    _loadVoices();
    debugPrint('[TTS Web] Initialisé');
  } catch (e) {
    debugPrint('[TTS Web] Erreur init: $e');
  }
}

void unlockAudio() {
  if (_unlocked) return;
  try {
    final u = web.SpeechSynthesisUtterance(' ')
      ..volume = 0
      ..rate = 1.0;
    web.window.speechSynthesis.speak(u);
    _unlocked = true;
    debugPrint('[TTS Web] 🔓 Audio déverrouillé');
  } catch (_) {}
}

void webSpeak(String text) {
  try {
    final synth = web.window.speechSynthesis;
    synth.cancel();
    if (!_voicesLoaded) _loadVoices();

    final utterance = web.SpeechSynthesisUtterance(text)
      ..lang = 'fr-FR'
      ..rate = 0.82
      ..pitch = 1.1
      ..volume = 1.0;

    if (_frenchVoice != null) utterance.voice = _frenchVoice;

    utterance.addEventListener('error', (web.Event event) {
      try {
        final e = event as web.SpeechSynthesisErrorEvent;
        if (e.error != 'interrupted' && e.error != 'canceled') {
          debugPrint('[TTS Web] Erreur: ${e.error}');
        }
      } catch (_) {}
    }.toJS);

    synth.speak(utterance);
    debugPrint('[TTS Web] 🔊 "$text"');
  } catch (e) {
    debugPrint('[TTS Web] Exception: $e');
  }
}

void webStop() {
  try { web.window.speechSynthesis.cancel(); } catch (_) {}
}