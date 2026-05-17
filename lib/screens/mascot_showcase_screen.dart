import 'package:flutter/material.dart';
import '../widgets/blob_mascot.dart';

class MascotShowcaseScreen extends StatefulWidget {
  const MascotShowcaseScreen({Key? key}) : super(key: key);

  @override
  State<MascotShowcaseScreen> createState() => _MascotShowcaseScreenState();
}

class _MascotShowcaseScreenState extends State<MascotShowcaseScreen> {
  double _sizeSlider = 140;
  bool _animate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text('🎨 Blob Mascot Test'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Main display
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: BlobMascot(
                  size: _sizeSlider,
                  animate: _animate,
                ),
              ),
              const SizedBox(height: 40),

              // Size slider
              Text(
                'Size: ${_sizeSlider.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: _sizeSlider,
                min: 80,
                max: 240,
                divisions: 16,
                onChanged: (v) => setState(() => _sizeSlider = v),
              ),

              // Animation toggle
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Animation'),
                value: _animate,
                onChanged: (v) => setState(() => _animate = v),
              ),

              // Test scenarios
              const SizedBox(height: 30),
              const Text(
                'Test Scenarios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Sizes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SizeCard('Small', 80),
                  _SizeCard('Medium', 140),
                  _SizeCard('Large', 200),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SizeCard(String label, double size) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: BlobMascot(size: size),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
