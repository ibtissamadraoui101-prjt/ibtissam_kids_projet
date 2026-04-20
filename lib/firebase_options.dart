// lib/firebase_options.dart
// Ce fichier connecte Flutter à ton projet Firebase
// Tes vraies clés sont déjà dedans — ne les partage pas publiquement

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Sur Web (Chrome, navigateur)
    if (kIsWeb) {
      return web;
    }
    // Sur Android
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS non configuré — ajoute GoogleService-Info.plist si nécessaire.',
        );
      default:
        // Sur desktop (Windows/Mac/Linux) → utilise la config web
        return web;
    }
  }

  // ── Configuration WEB ──────────────────────────────────────
  // (copié depuis ton index.html)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtzd7HQ4CAX8K42cRrhXWDmNQqw6ihKz0',
    authDomain: 'projetibtissam-2908o.firebaseapp.com',
    projectId: 'projetibtissam-2908o',
    storageBucket: 'projetibtissam-2908o.firebasestorage.app',
    messagingSenderId: '1051481715519',
    appId: '1:1051481715519:web:6d25f5d72fb698b373598a',
    measurementId: 'G-595EFPYFXL',
  );

  // ── Configuration Android ─────────────────────────────────
  // Remplace ces valeurs par celles de ton google-services.json
  // Si tu n'as pas encore Android configuré, laisse comme web
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtzd7HQ4CAX8K42cRrhXWDmNQqw6ihKz0',
    authDomain: 'projetibtissam-2908o.firebaseapp.com',
    projectId: 'projetibtissam-2908o',
    storageBucket: 'projetibtissam-2908o.firebasestorage.app',
    messagingSenderId: '1051481715519',
    appId: '1:1051481715519:android:6d25f5d72fb698b373598a',
  );
}