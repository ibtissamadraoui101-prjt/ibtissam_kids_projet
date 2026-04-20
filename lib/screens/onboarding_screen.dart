// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import 'world_map_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedAvatar = '🦁';
  bool _isLoading = false;

  static const List<String> _avatars = [
    '🦁', '🐸', '🦊', '🐧', '🦋',
    '🐬', '🦄', '🦅', '🐼', '🐯',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startAdventure() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écris ton prénom d\'abord ! 😊'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await ProgressService().createStudent(name, emoji: _selectedAvatar);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const WorldMapScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF29B6F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Logo
                const Text('🌍', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 12),
                const Text(
                  'LinguaKids Maroc',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Apprends le français en jouant !',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 50),

                // Champ prénom
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ton prénom...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1565C0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _startAdventure(),
                  ),
                ),

                const SizedBox(height: 30),

                // Choix de l'avatar
                Text(
                  'Choisis ton personnage',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _avatars.map((avatar) {
                    final isSelected = avatar == _selectedAvatar;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = avatar),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber
                                : Colors.white.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 50),

                // Bouton commencer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startAdventure,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black54,
                            ),
                          )
                        : const Text(
                            'Commencer l\'aventure ! 🚀',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}