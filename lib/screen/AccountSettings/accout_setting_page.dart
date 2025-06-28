import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/widget/bouton_continuer_2.dart';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO: Initialize fields with actual user data
    _emailController.text = 'user@example.com'; // Fetch current email
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
    Future<void> _updateEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email mis à jour avec succès')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur est survenue.';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Veuillez vous reconnecter pour confirmer le changement d\'email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Redirigez l'utilisateur vers la page de connexion ou effectuez toute autre action nécessaire après la déconnexion.
    Navigator.pushReplacementNamed(context, '/login'); 
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de Compte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section pour le changement d'email
              const Text(
                'Changer l\'Email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Nouvel Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              BottonContinuer2(
                  size: size,
                  press: () {
                    // TODO: Implémenter la logique de mise à jour de l'email
                    print('Email mis à jour: ${_emailController.text}');
                  },
                  name: ('Mettre à jour l\'email')),
          
              const SizedBox(height: 30),
          
              // Section pour le changement de mot de passe
              const Text(
                'Changer votre nom',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
                  BottonContinuer2(size: size,
                    press: _updateEmail,
                   name:  ('Mettre à jour le nom')),
           
              const SizedBox(height: 30),
          
              // Bouton pour se déconnecter
          
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Background color
                ),
                onPressed: _signOut,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
