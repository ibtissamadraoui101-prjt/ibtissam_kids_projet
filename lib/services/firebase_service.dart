// lib/services/firebase_service.dart
// Gère : Auth enseignant, sync Firestore, lecture données élèves
// Utilisé par : progress_service, teacher_dashboard, teacher_login

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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _loadTeacherProfile(credential.user!.uid);
      return null; // null = succès
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun compte trouvé pour cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'invalid-email':
          return 'Email invalide.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessaie dans 5 minutes.';
        default:
          return 'Erreur : ${e.message}';
      }
    } catch (e) {
      return 'Erreur de connexion : $e';
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Générer un code classe unique (6 caractères)
      final classCode = _generateClassCode(credential.user!.uid);

      final teacher = Teacher(
        id: credential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        schoolName: schoolName.trim(),
        classCode: classCode,
      );

      // Sauvegarder dans Firestore
      await _db
          .collection('teachers')
          .doc(credential.user!.uid)
          .set(teacher.toJson());

      _currentTeacher = teacher;
      return null; // succès
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Cet email est déjà utilisé.';
      }
      if (e.code == 'weak-password') {
        return 'Mot de passe trop faible (6 caractères minimum).';
      }
      return 'Erreur : ${e.message}';
    } catch (e) {
      return 'Erreur lors de la création : $e';
    }
  }

  /// Déconnexion enseignant
  Future<void> logoutTeacher() async {
    await _auth.signOut();
    _currentTeacher = null;
  }

  // ─────────────────────────────────────────────
  // SYNC RÉSULTATS ÉLÈVE → FIRESTORE
  // ─────────────────────────────────────────────

  /// Envoyer un résultat de jeu vers Firestore
  /// Appelle uniquement quand internet disponible
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

  /// Créer ou mettre à jour le profil élève dans Firestore
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

  /// Récupère tous les élèves d'une classe
  Future<List<Student>> getStudentsByClass(String classCode) async {
    try {
      final query = await _db
          .collection('students')
          .where('classCode', isEqualTo: classCode)
          .get();

      return query.docs
          .map((doc) => Student.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('FirebaseService: erreur getStudents: $e');
      return [];
    }
  }

  /// Récupère les scores d'un élève (50 derniers)
  Future<List<GameScore>> getScoresForStudent(String studentId) async {
    try {
      final query = await _db
          .collection('students')
          .doc(studentId)
          .collection('scores')
          .orderBy('playedAt', descending: true)
          .limit(50)
          .get();

      return query.docs
          .map((doc) => GameScore.fromJson(doc.data()))
          .toList();
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