# 🔊 Guide des sons — LinguaKids Maroc

## Structure des dossiers à créer

```
assets/
└── sounds/
    ├── sfx/              ← effets sonores courts
    │   ├── click.mp3
    │   ├── pop.mp3
    │   ├── woosh.mp3
    │   ├── correct.mp3
    │   ├── wrong.mp3
    │   ├── timeout.mp3
    │   ├── card_flip.mp3
    │   ├── match.mp3
    │   ├── combo.mp3
    │   ├── bingo.mp3
    │   ├── star.mp3
    │   ├── level_done.mp3
    │   ├── unlock.mp3
    │   ├── island_enter.mp3
    │   ├── game_start.mp3
    │   ├── bravo.mp3
    │   └── try_again.mp3
    │
    └── music/            ← musiques de fond (boucles 30-60s)
        ├── world_map.mp3
        ├── memory.mp3
        ├── quiz.mp3
        ├── bingo.mp3
        └── celebration.mp3
```

---

## 🎵 Sites GRATUITS pour télécharger les sons

### Effets sonores (SFX)
| Fichier | Description | Lien de recherche |
|---|---|---|
| `click.mp3` | Clic bouton joyeux | [freesound.org "button click children"](https://freesound.org/search/?q=button+click) |
| `correct.mp3` | Bonne réponse | [freesound.org "correct answer ding"](https://freesound.org/search/?q=correct+answer) |
| `wrong.mp3` | Mauvaise réponse douce | [freesound.org "wrong answer soft"](https://freesound.org/search/?q=wrong+buzzer+soft) |
| `card_flip.mp3` | Retournement carte | [freesound.org "card flip"](https://freesound.org/search/?q=card+flip) |
| `match.mp3` | Paire trouvée | [freesound.org "success chime"](https://freesound.org/search/?q=success+chime) |
| `combo.mp3` | Combo x3 | [freesound.org "combo power up"](https://freesound.org/search/?q=combo+power+up) |
| `star.mp3` | Étoile gagnée | [freesound.org "star sparkle"](https://freesound.org/search/?q=star+sparkle) |
| `level_done.mp3` | Niveau terminé | [freesound.org "level complete fanfare"](https://freesound.org/search/?q=level+complete) |
| `bingo.mp3` | BINGO ! | [freesound.org "bingo win"](https://freesound.org/search/?q=bingo+win) |
| `unlock.mp3` | Débloqué | [freesound.org "unlock magical"](https://freesound.org/search/?q=unlock+magical) |

### Sites alternatifs 100% gratuits
- **Pixabay Audio** : https://pixabay.com/sound-effects/ (recherche "children game")
- **Zapsplat** : https://www.zapsplat.com (compte gratuit requis)
- **Mixkit** : https://mixkit.co/free-sound-effects/game/ (no login needed!)
- **OpenGameArt** : https://opengameart.org/content/8-bit-sound-effects

### 🎯 Recommendation Mixkit (le plus simple)
Mixkit est 100% gratuit, pas besoin de compte, licence libre.
Voici les sons exacts à télécharger :
- https://mixkit.co/free-sound-effects/click/ → `click.mp3`
- https://mixkit.co/free-sound-effects/win/ → `correct.mp3`, `level_done.mp3`
- https://mixkit.co/free-sound-effects/arcade/ → `wrong.mp3`, `combo.mp3`

---

## 🎵 Musiques de fond gratuites

### Option 1 : Pixabay (recommandé)
Recherche "children learning background music" sur https://pixabay.com/music/
- Télécharge 5 morceaux différents (~30-60s chacun)
- Renomme-les : `world_map.mp3`, `memory.mp3`, `quiz.mp3`, `bingo.mp3`, `celebration.mp3`

### Option 2 : Bensound
https://www.bensound.com/royalty-free-music/track/cute (licence Creative Commons)

### Option 3 : Purple Planet Music
https://www.purple-planet.com/childrens (gratuit pour les apps)

---

## ⚡ Installation rapide (commandes terminal)

```bash
# 1. Créer les dossiers
mkdir -p assets/sounds/sfx assets/sounds/music

# 2. Télécharger des sons de test depuis Mixkit (exemples)
# (remplace par tes vrais fichiers téléchargés)
curl -L "https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3" -o assets/sounds/sfx/click.mp3
curl -L "https://assets.mixkit.co/active_storage/sfx/1435/1435-preview.mp3" -o assets/sounds/sfx/correct.mp3
curl -L "https://assets.mixkit.co/active_storage/sfx/2672/2672-preview.mp3" -o assets/sounds/sfx/wrong.mp3
curl -L "https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3" -o assets/sounds/sfx/star.mp3
curl -L "https://assets.mixkit.co/active_storage/sfx/1993/1993-preview.mp3" -o assets/sounds/sfx/level_done.mp3

# 3. Copier le même son pour les fichiers manquants (temporaire)
for f in pop woosh timeout card_flip match combo bingo unlock island_enter game_start bravo try_again; do
  cp assets/sounds/sfx/click.mp3 assets/sounds/sfx/${f}.mp3
done

# 4. Son de musique de fond (temporaire)
for m in world_map memory quiz bingo celebration; do
  cp assets/sounds/sfx/correct.mp3 assets/sounds/music/${m}.mp3
done

# 5. Mettre à jour les dépendances
flutter pub get
```

---

## 🔊 Comment utiliser dans le code

```dart
import '../services/sound_service.dart';

// Initialiser dans main.dart (une seule fois)
await SoundService().init();

// Dans n'importe quel écran :
SoundService().click();           // clic bouton
SoundService().correct();         // bonne réponse
SoundService().wrong();           // mauvaise réponse
SoundService().star();            // étoile gagnée
SoundService().levelDone();       // niveau terminé
SoundService().bingo();           // BINGO !
SoundService().play(SoundEffect.combo);  // combo

// Musique de fond
SoundService().startMusic('world_map');  // démarrer
SoundService().switchMusic('memory');    // changer
SoundService().stopMusic();              // arrêter
```

---

## 📱 Configuration Android requise

Dans `android/app/src/main/AndroidManifest.xml`, ajoute si pas déjà présent :
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Dans `android/app/build.gradle.kts`, minSdk doit être ≥ 21 (déjà fait).

## 🍎 Configuration iOS requise

Dans `ios/Runner/Info.plist`, ajoute :
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Micro pour la reconnaissance vocale</string>
```
(Déjà présent normalement pour speech_to_text)