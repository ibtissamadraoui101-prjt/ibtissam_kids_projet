// lib/firebase_options.dart
// ✅ BUG CORRIGÉ : Android appId et apiKey pris depuis google-services.json
// ✅ iOS ajouté (config web temporaire — voir instructions en bas)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Web ─────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtzd7HQ4CAX8K42cRrhXWDmNQqw6ihKz0',
    authDomain: 'projetibtissam-2908o.firebaseapp.com',
    projectId: 'projetibtissam-2908o',
    storageBucket: 'projetibtissam-2908o.firebasestorage.app',
    messagingSenderId: '1051481715519',
    appId: '1:1051481715519:web:6d25f5d72fb698b373598a',
    measurementId: 'G-595EFPYFXL',
  );

  // ── Android ──────────────────────────────────────────────────────────
  // ✅ CORRIGÉ : mobilesdk_app_id + current_key depuis google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD38OYB7LOPhKiTH2MBS0eVk2CKV0Y63uw',
    authDomain: 'projetibtissam-2908o.firebaseapp.com',
    projectId: 'projetibtissam-2908o',
    storageBucket: 'projetibtissam-2908o.firebasestorage.app',
    messagingSenderId: '1051481715519',
    appId: '1:1051481715519:android:e1d713603e2c494e73598a',
  );

  // ── iOS ─────────────────────────────────────────────────────────────
  // ⚠️  Config temporaire (identique web).
  //     Pour déploiement réel sur iPhone :
  //       1. Firebase Console → Project Settings → Add app → iOS
  //       2. Bundle ID : com.example.linguakidsMaroc
  //       3. Télécharger GoogleService-Info.plist
  //       4. Glisser dans ios/Runner/ via Xcode (pas juste copier le fichier)
  //       5. Remplacer les valeurs ci-dessous par celles du .plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtzd7HQ4CAX8K42cRrhXWDmNQqw6ihKz0',
    authDomain: 'projetibtissam-2908o.firebaseapp.com',
    projectId: 'projetibtissam-2908o',
    storageBucket: 'projetibtissam-2908o.firebasestorage.app',
    messagingSenderId: '1051481715519',
    appId: '1:1051481715519:web:6d25f5d72fb698b373598a',
  );
}