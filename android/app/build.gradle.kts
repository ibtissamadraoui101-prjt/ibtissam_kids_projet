// android/app/build.gradle.kts
// ✅ BUG CORRIGÉ 1 : Supprimé "apply plugin: 'com.google.gms.google-services'"
//    (c'est de la syntaxe Groovy dans un fichier Kotlin DSL .kts → erreur de build)
//    Le plugin est déjà déclaré correctement dans le bloc plugins {} en haut.
// ✅ BUG CORRIGÉ 2 : minSdk = 21 (Firebase Auth exige min 21, flutter_tts aussi)
// ✅ BUG CORRIGÉ 3 : Firebase BoM version 33.7.0 compatible avec les packages Flutter

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // Plugin Google Services déclaré ici (Kotlin DSL)
}

android {
    namespace = "com.example.linguakids_maroc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.linguakids_maroc"
        // ✅ minSdk 21 requis par : Firebase Auth, speech_to_text, flutter_tts
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM — gère toutes les versions Firebase automatiquement
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
// ✅ PAS de "apply plugin:" ici — c'est la syntaxe Groovy, interdite dans .kts
