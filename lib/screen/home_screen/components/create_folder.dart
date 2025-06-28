import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/widget/bouton_continuer_2.dart';

class CreateFolderForm extends StatefulWidget {
  @override
  _CreateFolderFormState createState() => _CreateFolderFormState();
}

class _CreateFolderFormState extends State<CreateFolderForm> {
  final TextEditingController _folderNameController = TextEditingController();
  String? _selectedCategory;
  bool isLoading = false;

  final List<String> _categories = [
    'Scolarite',
    'Service études',
    'Comptabilite',
    'Autre'
  ]; // Liste des catégories

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Créer un Nouveau Document',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _folderNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du Document',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
            value: _selectedCategory,
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 20),
          isLoading
              ? const CircularProgressIndicator()
              : BottonContinuer2(
                  size: MediaQuery.of(context).size,
                  press: () {
                    if (_folderNameController.text.isNotEmpty &&
                        _folderNameController.text != '' &&
                        _selectedCategory != null) {
                      _createFolder(context);
                    } else {
                      // Afficher un message d'erreur si le formulaire est incomplet
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Veuillez remplir tous les champs')),
                      );
                    }
                  },
                  name: 'Creer')
        ],
      ),
    );
  }

  void _createFolder(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    // Récupérer le nom du dossier et la catégorie
    String folderName = _folderNameController.text;
    String? category = _selectedCategory;
    if (folderName.isNotEmpty && folderName != '') {
      // Créer un document dans Firestore avec les informations du dossier
      try {
        await FirebaseFirestore.instance.collection('folder').add({
          'name': folderName,
          'category': category,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user!.uid, // Ajoute l'ID de l'utilisateur créateur
        });

        setState(() {
          isLoading = true;
        });
        // Fermer la modal après la création
        Navigator.pop(context);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Dossier "$folderName" créé dans la catégorie "$category"')),
        );
      } catch (e) {
        isLoading = false;
        Navigator.pop(context);
        // Gérer les erreurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du dossier : $e')),
        );
      }
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Vous ne pouvez pas creer de Dossier sans nom')),
      );
    }
  }
}
