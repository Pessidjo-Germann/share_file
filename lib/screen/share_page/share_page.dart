import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_file_iai/widgets/file_card.dart';

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
                  _SharedWithMeView(
                      currentUserId: currentUserId, usersMap: _usersMap),
                  _SharedByMeView(
                      currentUserId: currentUserId, usersMap: _usersMap),
                ],
              ),
      ),
    );
  }
}

class _SharedWithMeView extends StatefulWidget {
  final String currentUserId;
  final Map<String, String> usersMap;

  const _SharedWithMeView(
      {required this.currentUserId, required this.usersMap});

  @override
  __SharedWithMeViewState createState() => __SharedWithMeViewState();
}

class __SharedWithMeViewState extends State<_SharedWithMeView> {
  late Stream<QuerySnapshot> _filesStream;
  late Stream<QuerySnapshot> _foldersStream;

  @override
  void initState() {
    super.initState();
    _filesStream = FirebaseFirestore.instance
        .collectionGroup('files')
        .where('sharedWith', arrayContains: widget.currentUserId)
        .snapshots();

    _foldersStream = FirebaseFirestore.instance
        .collection('folder')
        .where('sharedWith', arrayContains: widget.currentUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream:
          Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<QuerySnapshot>>(
        _filesStream,
        _foldersStream,
        (a, b) => [a, b],
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Erreur: ${snapshot.error}');
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final files = snapshot.data![0].docs;
        final folders = snapshot.data![1].docs;
        final allItems = [...files, ...folders];

        if (allItems.isEmpty) {
          return Center(
              child: Text('Aucun fichier ou dossier partagé avec vous.'));
        }

        return ListView.builder(
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final item = allItems[index];
            final data = item.data() as Map<String, dynamic>;
            final itemName = data['name'] ?? 'Élément sans nom';
            final createdBy = data['createdBy'] ?? '';
            final sharedByName =
                widget.usersMap[createdBy] ?? 'Utilisateur inconnu';

            // Déterminer si c'est un fichier ou un dossier
            final isFile = data.containsKey('url');

            if (isFile) {
              // Assurez-vous que la référence parente n'est pas nulle avant d'accéder à son ID
              final folderId = item.reference.parent.parent?.id;
              if (folderId == null) {
                // Gérer le cas où folderId est nul, peut-être logger une erreur ou afficher un widget d'erreur
                return ListTile(
                  leading: Icon(Icons.error),
                  title: Text("Erreur: Impossible de charger ce fichier."),
                );
              }
              return FileCard(
                fileDoc: item as QueryDocumentSnapshot<Map<String, dynamic>>,
                folderId: folderId,
                showActions: false,
              );
            } else {
              // C'est un dossier, utilisez le ListTile existant
              return ListTile(
                leading: Icon(Icons.folder),
                title: Text(itemName),
                subtitle: Text('Partagé par: $sharedByName'),
                // Optionnel : Ajoutez un onTap pour naviguer dans les dossiers partagés
              );
            }
          },
        );
      },
    );
  }
}

class _SharedByMeView extends StatefulWidget {
  final String currentUserId;
  final Map<String, String> usersMap;

  const _SharedByMeView({required this.currentUserId, required this.usersMap});

  @override
  State<_SharedByMeView> createState() => _SharedByMeViewState();
}

class _SharedByMeViewState extends State<_SharedByMeView> {
  Future<void> _deleteFile(QueryDocumentSnapshot file) async {
    try {
      final data = file.data() as Map<String, dynamic>;
      final fileUrl = data['url'] ?? '';
      final folderId = file.reference.parent.parent?.id;

      if (folderId == null) {
        throw Exception("Impossible de trouver le dossier parent.");
      }

      // Supprimer de Firestore
      await FirebaseFirestore.instance
          .collection('folder')
          .doc(folderId)
          .collection('files')
          .doc(file.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(QueryDocumentSnapshot file) {
    final data = file.data() as Map<String, dynamic>;
    final fileName = data['name'] ?? 'Fichier';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le fichier'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer "$fileName" ?\n\nCette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteFile(file);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('files')
          .where('createdBy', isEqualTo: widget.currentUserId)
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
            final folderId = file.reference.parent.parent?.id;

            if (folderId == null) {
              return ListTile(
                leading: Icon(Icons.error),
                title: Text("Erreur: Impossible de charger ce fichier."),
              );
            }

            return FileCard(
              fileDoc: file as QueryDocumentSnapshot<Map<String, dynamic>>,
              folderId: folderId,
              showActions: true, // Les actions sont visibles
              onDelete: () => _showDeleteConfirmation(file),
            );
          },
        );
      },
    );
  }
}
