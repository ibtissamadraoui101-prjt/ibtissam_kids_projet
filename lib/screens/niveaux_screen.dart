import 'package:flutter/material.dart';
import 'package:linguakids_maroc/screens/memory_game_screen.dart';

class NiveauxScreen extends StatelessWidget {
  const NiveauxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisis ton niveau'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: const [
          NiveauTile(niveau: 'CP', couleur: Colors.blue),
          NiveauTile(niveau: 'CE1', couleur: Colors.green),
          NiveauTile(niveau: 'CE2', couleur: Colors.orange),
          NiveauTile(niveau: 'CM1', couleur: Colors.purple),
          NiveauTile(niveau: 'CM2', couleur: Colors.red),
        ],
      ),
    );
  }
}

class NiveauTile extends StatelessWidget {
  final String niveau;
  final Color couleur;

  const NiveauTile({
    super.key,
    required this.niveau,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: couleur.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur,
          child: Text(
            niveau[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          niveau,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MemoryGameScreen(niveau: niveau)),
              );
        },
      ),
    );
  }
}