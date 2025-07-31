import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SharedFoldersPage extends StatefulWidget {
  @override
  _SharedFoldersPageState createState() => _SharedFoldersPageState();
}

class _SharedFoldersPageState extends State<SharedFoldersPage> {
  late String currentUserId;
  Map<String, String> _usersMap = {};
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final usersMap = <String, String>{};
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        usersMap[doc.id] = data['name'] as String? ?? 'Utilisateur inconnu';
      }
      setState(() {
        _usersMap = usersMap;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      print("Erreur lors de la récupération des utilisateurs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Partages'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Partagés avec moi'),
              Tab(text: 'Partagés par moi'),
            ],
          ),
        ),
        body: _isLoadingUsers
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _SharedWithMeView(currentUserId: currentUserId),
                  _SharedByMeView(
                      currentUserId: currentUserId, usersMap: _usersMap),
                ],
              ),
      ),
    );
  }
}

class _SharedWithMeView extends StatelessWidget {
  final String currentUserId;

  const _SharedWithMeView({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('folder')
          .where('sharedWith', arrayContains: currentUserId)
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
              leading: Icon(Icons.folder_shared),
              title: Text(folderName),
              subtitle: Text('Catégorie: $category'),
            );
          },
        );
      },
    );
  }
}

class _SharedByMeView extends StatelessWidget {
  final String currentUserId;
  final Map<String, String> usersMap;

  const _SharedByMeView({required this.currentUserId, required this.usersMap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('files')
          .where('createdBy', isEqualTo: currentUserId)
          .where('sharedWith', isNotEqualTo: []).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final files = snapshot.data!.docs;
        if (files.isEmpty) {
          return Center(child: Text('Vous n\'avez partagé aucun fichier.'));
        }
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final data = file.data() as Map<String, dynamic>;
            final fileName = data['name'] ?? 'Fichier sans nom';
            final sharedWithIds = List<String>.from(data['sharedWith'] ?? []);
            final sharedWithNames =
                sharedWithIds.map((id) => usersMap[id] ?? 'ID: $id').join(', ');
            return ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text(fileName),
              subtitle: Text('Partagé avec: $sharedWithNames'),
            );
          },
        );
      },
    );
  }
}
