import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _emailController.text = _user!.email ?? '';
      _nameController.text = _user!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (_user == null || _emailController.text.trim() == _user!.email) return;

    try {
      await _user!.verifyBeforeUpdateEmail(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Un lien de vérification a été envoyé à votre nouvelle adresse e-mail.')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur est survenue.';
      if (e.code == 'requires-recent-login') {
        errorMessage =
            'Veuillez vous reconnecter pour confirmer le changement d\'email.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Cet email est déjà utilisé par un autre compte.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _updateDisplayName() async {
    if (_user == null ||
        _nameController.text.trim().isEmpty ||
        _nameController.text.trim() == _user.displayName) return;

    try {
      await _user.updateDisplayName(_nameController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom mis à jour avec succès')),
      );
      setState(() {}); // To rebuild and show the new name in the header
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.message}')),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Paramètres du Compte',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildSettingsCard(
                icon: Icons.email,
                title: 'Changer l\'Email',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Nouvel Email',
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 20),
                    _buildUpdateButton(
                      onPressed: _updateEmail,
                      text: 'Mettre à jour l\'email',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingsCard(
                icon: Icons.person,
                title: 'Changer votre nom',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Nouveau nom',
                      icon: Icons.badge,
                    ),
                    const SizedBox(height: 20),
                    _buildUpdateButton(
                      onPressed: _updateDisplayName,
                      text: 'Mettre à jour le nom',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (_user?.displayName?.isNotEmpty ?? false)
                  ? _user!.displayName![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _user?.displayName ?? 'Utilisateur',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _user?.email ?? 'email@example.com',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF636E72),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF667eea)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: const Color(0xFF636E72)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
      ),
    );
  }

  Widget _buildUpdateButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFF667eea),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Déconnexion',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFFe17055),
        ),
      ),
    );
  }
}
