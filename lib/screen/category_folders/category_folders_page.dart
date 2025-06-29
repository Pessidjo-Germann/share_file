import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/screen/liste_document/list_doc.dart';

class CategoryFoldersPage extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Scolarite',
      'icon': Icons.school,
      'color': const Color(0xFF667eea),
    },
    {
      'name': 'Service études',
      'icon': Icons.business_center,
      'color': const Color(0xFF764ba2),
    },
    {
      'name': 'Comptabilite',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF0984e3),
    },
    {
      'name': 'Autre',
      'icon': Icons.dashboard_customize,
      'color': const Color(0xFFe17055),
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Catégories de Dossiers',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryTile(category: category);
          },
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final Map<String, dynamic> category;

  const CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderListPage(category: category['name']!),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [category['color']!.withOpacity(0.8), category['color']!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category['color']!.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon']! as IconData,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 15),
            Text(
              category['name']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
