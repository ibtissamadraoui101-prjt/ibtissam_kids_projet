// lib/services/firebase_service.dart
// ✅ CORRECTION : Messages d'erreur plus précis et en français
// ✅ AJOUT : Gestion du cas 'invalid-credential' (nouveau code Firebase SDK v5)
// ✅ AJOUT : Logs de debug pour faciliter le diagnostic

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_models.dart';

class FirebaseService {
  // Singleton
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Teacher? _currentTeacher;
  Teacher? get currentTeacher => _currentTeacher;
  bool get isTeacherLoggedIn => _auth.currentUser != null;

  // ─────────────────────────────────────────────
  // AUTHENTIFICATION ENSEIGNANT
  // ─────────────────────────────────────────────

  /// Connexion enseignant avec email + mot de passe
  Future<String?> loginTeacher(String email, String password) async {
    try {
      debugPrint('[Firebase] Tentative connexion: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _loadTeacherProfile(credential.user!.uid);
      debugPrint('[Firebase] ✅ Connexion réussie: ${credential.user!.uid}');
      return null; // null = succès
    } on FirebaseAuthException catch (e) {
      debugPrint('[Firebase] ❌ Auth error: ${e.code} — ${e.message}');
      return _authErrorMessage(e.code);
    } catch (e) {
      debugPrint('[Firebase] ❌ Erreur inattendue: $e');
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }
  }

  /// Créer un compte enseignant
  Future<String?> registerTeacher({
    required String email,
    required String password,
    required String name,
    required String schoolName,
  }) async {
    try {
      debugPrint('[Firebase] Création compte: $email');

      // 1. Créer l'utilisateur Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      debugPrint('[Firebase] ✅ Auth créée: ${credential.user!.uid}');

      // 2. Générer un code classe unique
      final classCode = _generateClassCode(credential.user!.uid);

      // 3. Construire l'objet Teacher
      final teacher = Teacher(
        id: credential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        schoolName: schoolName.trim(),
        classCode: classCode,
      );

      // 4. Sauvegarder dans Firestore
      await _db
          .collection('teachers')
          .doc(credential.user!.uid)
          .set(teacher.toJson());
      debugPrint('[Firebase] ✅ Profil Firestore créé, code classe: $classCode');

      _currentTeacher = teacher;
      return null; // null = succès

    } on FirebaseAuthException catch (e) {
      debugPrint('[Firebase] ❌ Auth error register: ${e.code} — ${e.message}');
      return _authErrorMessage(e.code);
    } on FirebaseException catch (e) {
      debugPrint('[Firebase] ❌ Firestore error: ${e.code} — ${e.message}');
      // L'Auth a réussi mais Firestore a échoué → on nettoie
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      return 'Erreur de sauvegarde des données. Réessaie.';
    } catch (e) {
      debugPrint('[Firebase] ❌ Erreur inattendue: $e');
      return 'Erreur lors de la création du compte. Vérifiez votre connexion.';
    }
  }

  /// Messages d'erreur Firebase en français
  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé pour cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        // Nouveau code Firebase SDK v5+ (remplace user-not-found + wrong-password)
        return 'Email ou mot de passe incorrect.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion internet. Vérifie ta connexion.';
      case 'operation-not-allowed':
        return 'Connexion par email non activée. Contacte l\'administrateur.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      default:
        return 'Erreur d\'authentification ($code). Réessaie.';
    }
  }

  /// Déconnexion enseignant
  Future<void> logoutTeacher() async {
    await _auth.signOut();
    _currentTeacher = null;
    debugPrint('[Firebase] Déconnexion réussie');
  }
  Future<void> resetPassword(String email) async {
  await _auth.sendPasswordResetEmail(email: email.trim());
  debugPrint('[Firebase] Email reset envoyé à $email');
}

  // ─────────────────────────────────────────────
  // SYNC RÉSULTATS ÉLÈVE → FIRESTORE
  // ─────────────────────────────────────────────

  Future<bool> syncScore(GameScore score) async {
    try {
      await _db
          .collection('students')
          .doc(score.studentId)
          .collection('scores')
          .doc(score.id)
          .set(score.toJson());
      return true;
    } catch (e) {
      debugPrint('FirebaseService: erreur sync score: $e');
      return false;
    }
  }

  Future<bool> syncStudent(Student student) async {
    try {
      await _db
          .collection('students')
          .doc(student.id)
          .set(student.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('FirebaseService: erreur sync student: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // LECTURE DONNÉES POUR LE TABLEAU DE BORD
  // ─────────────────────────────────────────────

  Future<List<Student>> getStudentsByClass(String classCode) async {
    try {
      final query = await _db
          .collection('students')
          .where('classCode', isEqualTo: classCode)
          .get();
      return query.docs.map((doc) => Student.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirebaseService: erreur getStudents: $e');
      return [];
    }
  }

  Future<List<GameScore>> getScoresForStudent(String studentId) async {
    try {
      final query = await _db
          .collection('students')
          .doc(studentId)
          .collection('scores')
          .orderBy('playedAt', descending: true)
          .limit(50)
          .get();
      return query.docs.map((doc) => GameScore.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('FirebaseService: erreur getScores: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // PRIVÉ
  // ─────────────────────────────────────────────

  Future<void> _loadTeacherProfile(String uid) async {
    try {
      final doc = await _db.collection('teachers').doc(uid).get();
      if (doc.exists) {
        _currentTeacher = Teacher.fromJson(doc.data()!);
        debugPrint('[Firebase] Profil enseignant chargé: ${_currentTeacher!.name}');
      } else {
        debugPrint('[Firebase] ⚠️ Profil Firestore introuvable pour $uid');
      }
    } catch (e) {
      debugPrint('FirebaseService: erreur loadTeacher: $e');
    }
  }

  String _generateClassCode(String uid) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed = uid.codeUnits.take(6).toList();
    return List.generate(6, (i) => chars[seed[i] % chars.length]).join();
  }
}