import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_file_iai/constante.dart';
import 'package:share_file_iai/screen/liste_fichier/list_file.dart';
import 'package:share_file_iai/widget/primary_button.dart';
import '../../models/tag.dart';
import '../../services/tag_service.dart';
import '../../widgets/tag_widgets.dart';

class FolderListPage extends StatelessWidget {
  final String category;
  const FolderListPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String initalValue = '';
    final TextEditingController _folderNameController = TextEditingController();
    List<String> selectedUsers = [];
    final TagService _tagService = TagService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Dossiers'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('folder')
            .where('category', isEqualTo: category)
            .where('createdBy', isEqualTo: user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!.docs;
          // Créer un Map pour regrouper les dossiers par catégorie

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.folder,
                      color: Colors.yellow[700], size: 40), // Icône dossier
                  title: Text(folder['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catégorie: ${folder['category']}'),
                      if (folder['tags'] != null && folder['tags'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: StreamBuilder<List<Tag>>(
                            stream: _tagService.getUserTags(),
                            builder: (context, tagSnapshot) {
                              if (!tagSnapshot.hasData)
                                return const SizedBox.shrink();

                              final allTags = tagSnapshot.data!;
                              final folderTagIds =
                                  List<String>.from(folder['tags'] ?? []);
                              final folderTags = allTags
                                  .where((tag) => folderTagIds.contains(tag.id))
                                  .toList();

                              return Wrap(
                                spacing: 4,
                                children: folderTags
                                    .map((tag) => TagChip(tag: tag))
                                    .toList(),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    initialValue: initalValue,
                    onSelected: (value) {
                      if (value == 'put') {
                        //on modifie le nom du dossiers
                        _showModifyFolderModal(
                            context, _folderNameController, folders[index].id);
                      } else if (value == 'delete') {
                        //on supprime
                        _showDeleteFolder(
                            context, folders[index].id, folder['name']);
                      } else if (value == 'share') {
                        _showUser(context, selectedUsers, folders[index].id);
                      } else if (value == 'tags') {
                        _showEditTagsModal(
                            context, folders[index].id, folder['tags'] ?? []);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'put', // Valeur retournée lors de la sélection
                          child: Text('Renomer'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'tags',
                          child: Text('Modifier les tags'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'share',
                          child: Text(
                            'Partager',
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            'Supprimer',
                          ),
                        ),
                      ];
                    },
                  ),
                  onTap: () {
                    // Action lors de la sélection du dossier (par exemple, afficher les fichiers)
                    print('hello');
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FileListPage(
                                  name: folder['name'],
                                  id: folders[index].id,
                                )));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUser(
      BuildContext context, List<String> selectedUsers, String folderId) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length +
                    1, // Inclus l'élément supplémentaire pour le bouton
                itemBuilder: (context, index) {
                  // Vérifier si on est sur le dernier élément (bouton)
                  if (index == users.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: PrimaryButton(
                        color: Colors.red,
                        press: () {
                          shareFolder(folderId, context, selectedUsers);
                          Navigator.pop(context);
                        },
                        name: 'Partager',
                      ),
                    );
                  } else {
                    // Accéder aux données utilisateur uniquement si on n'est pas sur le bouton
                    final user = users[index];
                    final userId = user.id;
                    final userName = user['name'];
                    return CardUser(
                      userName: userName,
                      userId: userId,
                      selectedUsers: selectedUsers,
                    );
                  }
                },
              );
            },
          );
        });
  }

  void _showModifyFolderModal(BuildContext context,
      TextEditingController _folderNameController, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Pour permettre à la modal de prendre plus d'espace
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Gérer le clavier
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau nom',
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
                PrimaryButton(
                    press: () {
                      if (_folderNameController.text.isNotEmpty &&
                          _folderNameController.text != '') {
                        _updateFolderName(
                            context, id, _folderNameController.text);
                        Navigator.pop(context);
                      } else {
                        // Afficher un message d'erreur si le formulaire est incomplet
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.red,
                              content:
                                  Text('Veuillez remplir tous les champs')),
                        );
                      }
                    },
                    name: 'Enregistrer')
              ],
            ),
          ),
        );
      },
    );
  }
}

class CardUser extends StatefulWidget {
  const CardUser({
    super.key,
    required this.userName,
    required this.userId,
    required this.selectedUsers,
  });

  final dynamic userName;
  final String userId;
  final List<String> selectedUsers;

  @override
  State<CardUser> createState() => _CardUserState();
}

class _CardUserState extends State<CardUser> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.userName),
      trailing: Checkbox(
        value: widget.selectedUsers.contains(widget.userId),
        onChanged: (bool? isSelected) {
          setState(() {
            if (isSelected == true) {
              widget.selectedUsers.add(widget.userId);
            } else {
              widget.selectedUsers.remove(widget.userId);
            }
          });
        },
      ),
    );
  }
}

void _showDeleteFolder(BuildContext context, String id, String name) {
  showModalBottomSheet(
    context: context,
    isScrollControlled:
        true, // Pour permettre à la modal de prendre plus d'espace
    builder: (BuildContext context) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets, // Gérer le clavier
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supprimer le document $name',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                        press: () {
                          _deleteFolder(context, id);
                          Navigator.pop(context);
                        },
                        name: 'Oui'),
                  ),
                  Expanded(
                    child: PrimaryButton(
                        color: Colors.red,
                        press: () {
                          Navigator.pop(context);
                        },
                        name: 'NON'),
                  )
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}

void _deleteFolder(BuildContext context, String folderId) async {
  try {
    await FirebaseFirestore.instance
        .collection('folder')
        .doc(folderId)
        .delete();

    // Affiche un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dossier supprimé avec succès')),
    );
  } catch (e) {
    // Affiche un message d'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la suppression: $e')),
    );
  }
}

void _updateFolderName(
    BuildContext context, String folderId, String newName) async {
  try {
    await FirebaseFirestore.instance
        .collection('folder')
        .doc(folderId)
        .update({'name': newName}); // Met à jour le nom du dossier

    // Affiche un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nom du dossier mis à jour avec succès')),
    );
  } catch (e) {
    // Affiche un message d'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
    );
  }
}

void shareFolder(
    String folderId, BuildContext context, List<String> userIds) async {
  try {
    // Récupérer le dossier existant
    DocumentSnapshot folderSnapshot = await FirebaseFirestore.instance
        .collection('folder')
        .doc(folderId)
        .get();

    if (folderSnapshot.exists) {
      // Mettre à jour le dossier avec la liste des utilisateurs autorisés
      await FirebaseFirestore.instance
          .collection('folder')
          .doc(folderId)
          .update({
        'sharedWith': FieldValue.arrayUnion(userIds),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dossier partagé avec succès!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le dossier n\'existe pas.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors du partage du dossier: $e')),
    );
  }
}

void _showEditTagsModal(
    BuildContext context, String folderId, List<dynamic> currentTagIds) {
  final TagService tagService = TagService();
  List<String> selectedTagIds = List<String>.from(currentTagIds);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modifier les tags',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Tag>>(
                    stream: tagService.getUserTags(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final tags = snapshot.data ?? [];
                      if (tags.isEmpty) {
                        return const Text(
                          'Aucun tag disponible. Créez-en un dans la section Tags.',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return TagSelector(
                        availableTags: tags,
                        selectedTagIds: selectedTagIds,
                        onTagsChanged: (newSelectedIds) {
                          setState(() {
                            selectedTagIds = newSelectedIds;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('Annuler',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('folder')
                                  .doc(folderId)
                                  .update({'tags': selectedTagIds});

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tags mis à jour avec succès'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Enregistrer',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
