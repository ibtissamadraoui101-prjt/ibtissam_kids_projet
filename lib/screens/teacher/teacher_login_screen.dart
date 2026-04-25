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
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _schoolCtrl   = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  late TabController _tabCtrl;
  bool _isLoading      = false;
  bool _obscure        = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _errorMsg = null));

    // Si déjà connecté → aller direct au dashboard
    if (FirebaseService().isTeacherLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final isLogin = _tabCtrl.index == 0;
    String? error;

    if (isLogin) {
      error = await FirebaseService().loginTeacher(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
    } else {
      error = await FirebaseService().registerTeacher(
        email:      _emailCtrl.text.trim(),
        password:   _passwordCtrl.text.trim(),
        name:       _nameCtrl.text.trim(),
        schoolName: _schoolCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const TeacherDashboardScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _tabCtrl.index == 0;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F2E), Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── En-tête ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('👩‍🏫  Espace Enseignant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Logo ─────────────────────────────────
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Center(
                  child: Text('🏫', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 8),
              Text('LinguaKids — Enseignants',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13)),
              const SizedBox(height: 24),

              // ── Onglets ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: const Color(0xFF1A237E),
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Connexion'),
                      Tab(text: 'Créer un compte'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Formulaire ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!isLogin) ...[
                          _buildField(
                            ctrl: _nameCtrl,
                            label: 'Votre nom complet',
                            icon: Icons.person_outline,
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            ctrl: _schoolCtrl,
                            label: 'Nom de l\'école',
                            icon: Icons.school_outlined,
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Email requis';
                            if (!v!.contains('@')) return 'Email invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          ctrl: _passwordCtrl,
                          label: 'Mot de passe',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Mot de passe requis';
                            if (v!.length < 6) return '6 caractères minimum';
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined
                                       : Icons.visibility_off_outlined,
                              color: Colors.white54, size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Erreur
                        if (_errorMsg != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMsg!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13)),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 16),

                        // Bouton
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22, width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black54))
                                : Text(
                                    isLogin ? 'Se connecter' : 'Créer le compte',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white60, size: 20),
          suffixIcon: suffix,
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.white60, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(color: Colors.orange, fontSize: 11),
        ),
      ),
    );
  }
}