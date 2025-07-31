import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_file_iai/constante.dart';
import 'package:share_file_iai/screen/document_preview/document_preview_page.dart';

class FileListPage extends StatefulWidget {
  const FileListPage({super.key, required this.name, required this.id});
  final String name, id;

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  double? progress;
  String? _progressText;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: textPresentation(msg: widget.name, fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('folder')
            .doc(widget.id)
            .collection('files')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final files = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Affichage des fichiers
                if (files.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun fichier dans ce dossier',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez votre premier fichier ci-dessous',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final data = file.data() as Map<String, dynamic>;
                      final fileName = data['name'] ?? 'Nom indisponible';
                      final fileUrl = data['url'] ?? '';

                      return Card(
                        margin: const EdgeInsets.all(8),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getFileColor(fileName).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _getFileIcon(fileName),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Taille: ${_formatFileSize(data['fileSize'])}'),
                              if (data['uploadedAt'] != null)
                                Text(
                                  'Ajouté le ${_formatDate(data['uploadedAt'].toDate())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'preview',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('Prévisualiser'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'download',
                                child: Row(
                                  children: [
                                    Icon(Icons.download),
                                    SizedBox(width: 8),
                                    Text('Télécharger'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share),
                                    SizedBox(width: 8),
                                    Text('Partager'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Supprimer',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'preview':
                                  _previewFile(file);
                                  break;
                                case 'download':
                                  _downloadFile(fileUrl, fileName);
                                  break;
                                case 'share':
                                  _showShareModal(file);
                                  break;
                                case 'delete':
                                  _showDeleteConfirmation(file);
                                  break;
                              }
                            },
                          ),
                          onTap: () => _previewFile(file),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // Indicateur de progression pendant l'upload
                if (progress != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(_progressText ?? 'Chargement en cours...'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text('${(progress! * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),

                // Bouton d'ajout de fichier
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: _showUploadOptions,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Ajouter un fichier',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icon(Icons.image, color: Colors.green);
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icon(Icons.video_file, color: Colors.purple);
      case 'mp3':
      case 'wav':
        return Icon(Icons.audio_file, color: Colors.orange);
      case 'doc':
      case 'docx':
        return Icon(Icons.description, color: Colors.blue);
      case 'txt':
        return Icon(Icons.text_snippet, color: Colors.grey);
      default:
        return Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return 'Inconnue';

    final bytes = size as int;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _previewFile(QueryDocumentSnapshot file) {
    final data = file.data() as Map<String, dynamic>;
    final fileName = data['name'] ?? 'Nom indisponible';
    final fileUrl = data['url'] ?? '';

    // Naviguer vers la page de prévisualisation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewPage(
          folderId: widget.id,
          fileId: file.id,
          fileName: fileName,
          fileUrl: fileUrl,
        ),
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir un fichier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.file_present, color: Colors.orange),
                title: const Text('Parcourir les fichiers'),
                onTap: () {
                  Navigator.pop(modalContext);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      await _uploadSelectedFile(File(result.files.single.path!));
    }
  }

  Future<void> _uploadSelectedFile(File file) async {
    try {
      setState(() {
        progress = 0.0;
        _progressText = 'Téléversement en cours...';
      });

      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String fileName = p.basename(file.path);
      final String supabasePath = 'uploads/${user.uid}/$fileName';

      // Upload file to Supabase Storage
      // Note: Supabase storage 'upload' method does not support progress reporting.
      await Supabase.instance.client.storage.from('files').upload(
            supabasePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String fileUrl = Supabase.instance.client.storage
          .from('files')
          .getPublicUrl(supabasePath);

      final fileSize = file.lengthSync();
      final mimeType = lookupMimeType(file.path);

      // Add file details to Firestore
      await FirebaseFirestore.instance
          .collection('folder')
          .doc(widget.id)
          .collection('files')
          .add({
        'name': fileName,
        'url': fileUrl,
        'createdBy': user.uid,
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileSize': fileSize,
        'mimeType': mimeType,
        'tags': <String>[], // Default empty tags
        'sharedWith': <String>[], // Default empty sharedWith
      });

      setState(() {
        progress = null;
        _progressText = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier téléversé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        progress = null;
        _progressText = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléversement: $e'),
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

  Future<void> _deleteFile(QueryDocumentSnapshot file) async {
    try {
      final data = file.data() as Map<String, dynamic>;
      final fileUrl = data['url'] ?? '';

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('folder')
          .doc(widget.id)
          .collection('files')
          .doc(file.id)
          .delete();

      // Delete from Supabase Storage
      if (fileUrl.isNotEmpty) {
        try {
          final bucketName = 'files';
          final pathStartIndex =
              fileUrl.indexOf('$bucketName/') + bucketName.length + 1;
          final supabasePath = fileUrl.substring(pathStartIndex);

          await Supabase.instance.client.storage
              .from(bucketName)
              .remove([supabasePath]);
        } catch (e) {
          print(
              'Erreur lors de la suppression du fichier de Supabase Storage: $e');
        }
      }

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

  Future<void> _downloadFile(String url, String fileName) async {
    // The flutter_file_downloader package handles permissions automatically on Android
    // and downloads to the default downloads directory.
    final encodedUrl = Uri.encodeFull(url);

    setState(() {
      _progressText = 'Téléchargement en cours...';
      progress = 0.0;
    });

    FileDownloader.downloadFile(
      url: encodedUrl,
      name: fileName,
      onProgress: (fileName, progressValue) {
        setState(() {
          // progressValue is a percentage from 0 to 100
          progress = progressValue / 100;
        });
      },
      onDownloadCompleted: (path) {
        setState(() {
          progress = null;
          _progressText = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fichier téléchargé: $path'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onDownloadError: (String error) {
        setState(() {
          progress = null;
          _progressText = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de téléchargement: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.purple;
      case 'mp3':
      case 'wav':
        return Colors.orange;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showShareModal(QueryDocumentSnapshot file) {
    List<String> selectedUsers = [];
    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;

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

            final users = snapshot.data!.docs
                .where((doc) => doc.id != currentUser?.uid)
                .toList();

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Partager avec'),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userId = user.id;
                          final userName =
                              user['name'] ?? 'Utilisateur inconnu';
                          final isSelected = selectedUsers.contains(userId);

                          return CheckboxListTile(
                            title: Text(userName),
                            value: isSelected,
                            onChanged: (bool? value) {
                              modalState(() {
                                if (value == true) {
                                  if (!selectedUsers.contains(userId)) {
                                    selectedUsers.add(userId);
                                  }
                                } else {
                                  selectedUsers.remove(userId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              Size(double.infinity, 50), // Make button wide
                        ),
                        onPressed: selectedUsers.isNotEmpty
                            ? () {
                                _shareFile(file.id, selectedUsers);
                                Navigator.pop(context);
                              }
                            : null, // Disable button if no user is selected
                        child: Text('Partager'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _shareFile(String fileId, List<String> userIds) async {
    if (userIds.isEmpty) {
      // This case should be handled by the disabled button, but as a safeguard:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez sélectionner au moins un utilisateur.')),
        );
      }
      return;
    }

    try {
      final fileRef = FirebaseFirestore.instance
          .collection('folder')
          .doc(widget.id)
          .collection('files')
          .doc(fileId);

      await fileRef.update({
        'sharedWith': FieldValue.arrayUnion(userIds),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier partagé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage du fichier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
