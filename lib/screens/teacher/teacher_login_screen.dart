// lib/screens/teacher/teacher_login_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import 'teacher_dashboard_screen.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();

  bool _isLogin = true; // true=connexion, false=inscription
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        _isLogin = _tabCtrl.index == 0;
        _errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;

    if (_isLogin) {
      error = await FirebaseService().loginTeacher(
        _emailCtrl.text,
        _passwordCtrl.text,
      );
    } else {
      if (_nameCtrl.text.trim().isEmpty || _schoolCtrl.text.trim().isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Remplis tous les champs.';
        });
        return;
      }
      error = await FirebaseService().registerTeacher(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text,
        schoolName: _schoolCtrl.text,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const TeacherDashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        title: const Text(
          '👩‍🏫 Espace Enseignant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Onglets connexion / inscription
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: const Color(0xFF1A237E),
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Connexion'),
                Tab(text: 'Créer un compte'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Champs selon l'onglet
                  if (!_isLogin) ...[
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Votre nom complet',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _schoolCtrl,
                      label: 'Nom de l\'école',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _passwordCtrl,
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white60,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Bouton soumettre
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black54,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Se connecter' : 'Créer le compte',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white60, size: 20),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}