import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SharedFoldersPage extends StatelessWidget {
  final String currentUserId; // L'ID de l'utilisateur connecté

  SharedFoldersPage({required this.currentUserId});

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
            print(currentUserId);
            return Center(child: Text('Aucun dossier partagé.'));
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                title: Text(folder['name']),
                subtitle: Text('Catégorie: ${folder['category']}'),
                onTap: () {
                  // Ici, tu peux naviguer vers une page de détails du dossier ou afficher les fichiers dans le dossier
                },
              );
            },
          );
        },
      ),
    );
  }
}
