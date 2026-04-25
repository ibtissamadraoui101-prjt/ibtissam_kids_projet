// lib/services/tts_stub.dart
// Stub pour les plateformes non-web (Android, iOS)
// Ce fichier remplace dart:js sur mobile pour éviter les erreurs de compilation.

class JsContext {
  void callMethod(String name, [List? args]) {}
}

final context = JsContext();