import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SharedFoldersPage extends StatefulWidget {
  @override
  _SharedFoldersPageState createState() => _SharedFoldersPageState();
}

class _SharedFoldersPageState extends State<SharedFoldersPage> {
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dossiers Partagés'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('folder')
            .where('sharedWith',
                arrayContains:
                    currentUserId) // Récupère les dossiers partagés avec l'utilisateur
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!.docs;

          if (folders.isEmpty) {
            return Center(child: Text('Aucun dossier partagé avec vous.'));
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final data = folder.data() as Map<String, dynamic>;
              final folderName = data['name'] ?? 'Dossier sans nom';
              final category = data['category'] ?? 'Aucune catégorie';

              return ListTile(
                title: Text(folderName),
                subtitle: Text('Catégorie: $category'),
                onTap: () {
                  // Ici, tu peux naviguer vers une page de détails du dossier
                  // par exemple, en utilisant Navigator.push avec l'ID du dossier
                },
              );
            },
          );
        },
      ),
    );
  }
}
