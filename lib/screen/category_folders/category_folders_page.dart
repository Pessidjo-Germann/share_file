import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/screen/liste_document/list_doc.dart';
 
class CategoryFoldersPage extends StatelessWidget {
  // Les catégories définies
  final List<String> categories = [
    'Scolarite',
    'Service études',
    'Comptabilite',
    'Autre'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dossiers par Catégorie'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryTile(category: category);
        },
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String category;

  const CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(category),
        onTap: () {
          // Naviguer vers la page des dossiers de la catégorie sélectionnée
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderListPage(category: category),
            ),
          );
        },
      ),
    );
  }
}

class FoldersByCategoryPage extends StatelessWidget {
  final String category;

  const FoldersByCategoryPage({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dossiers dans $category'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('folder')
            .where('category', isEqualTo: category)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final folders = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                title: Text(folder['name']),
                subtitle: Text('Créé le: ${folder['createdAt'].toDate()}'),
                onTap: () {
                  // Naviguer vers la page de détails du dossier
                  // TODO: Implémenter la navigation vers la page de détails du dossier
                },
              );
            },
          );
        },
      ),
    );
  }
}
