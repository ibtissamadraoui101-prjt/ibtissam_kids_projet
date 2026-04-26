// lib/services/tts_mobile_stub.dart
// ✅ CORRECTION : Ajout de unlockAudio() manquant
//    Sans cette fonction, la compilation Android/iOS échoue car
//    tts_service.dart appelle tts_platform.unlockAudio()

// Stubs vides pour mobile — jamais appelés car kIsWeb est false sur Android/iOS.
// Requis pour que le code compile sur Android et iOS.

void initWebTts() {}
void webSpeak(String text) {}
void webStop() {}
void unlockAudio() {}   // ✅ AJOUTÉ — était manquant, causait erreur de compilation