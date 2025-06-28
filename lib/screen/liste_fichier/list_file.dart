import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_file_iai/constante.dart';

class FileListPage extends StatefulWidget {
  const FileListPage({super.key, required this.name, required this.id});
  final String name, id;

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  double? progress;
  @override
  Widget build(BuildContext context) {
    File? _file;
      User? user = FirebaseAuth.instance.currentUser;
    final picker = ImagePicker();
    Future<void> uploadFile() async {
      if (_file == null) return;

      try {
        // Créer un chemin de stockage pour le fichier dans Firebase Storage
        String fileName = basename(_file!.path);
        final storageRef =
            FirebaseStorage.instance.ref().child('uploads/$fileName');

        // Téléverser le fichier
        final uploadTask = storageRef.putFile(_file!);
        final snapshot = await uploadTask.whenComplete(() => null);

        // Obtenir l'URL du fichier téléchargé
        final fileUrl = await snapshot.ref.getDownloadURL();

        // Ajouter les détails du fichier dans Firestore
        await FirebaseFirestore.instance
            .collection('folder')
            .doc(widget.id)
            .collection('files') // Collection dynamique pour les fichiers
            .add({
          'name': fileName,
          'url': fileUrl,
           'createdBy': user!.uid,  // ID de l'utilisateur qui télécharge le fichier
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fichier téléversé avec succès !')));
      } catch (e) {
        print('Erreur lors du téléversement: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du téléversement: $e')));
      }
    }

    Future pickFile() async {
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery); // Choisir un fichier depuis la galerie

      setState(() {
        if (pickedFile != null) {
          _file = File(pickedFile.path); // Stocker le fichier choisi
          uploadFile();
        } else {
          print('No file selected.');
        }
      });
    }

    return Scaffold(
        appBar: AppBar(
          title:
              textPresentation(msg: widget.name, fontWeight: FontWeight.bold),
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
                return Center(child: CircularProgressIndicator());
              }

              final files = snapshot.data!.docs;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                        shrinkWrap: true,
                        // physics: NeverScrollableScrollPhysics(),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          if (files.isEmpty) {
                            return textPresentation(
                                msg: 'Aucun fichier dans ce dossier',
                                fontWeight: FontWeight.bold);
                          }

                          // Vérification des champs
                          final fileName = file['name'] ?? 'Nom indisponible';
                          final uploadedAt = file['uploadedAt'] != null
                              ? file['uploadedAt'].toDate()
                              : 'Date indisponible';

                          return ListTile(
                            leading: Icon(Icons.insert_drive_file,
                                color: Colors.blue),
                            title: Text(fileName),
                            subtitle: Text('Téléchargé le $uploadedAt'),
                            trailing: IconButton(
                              icon: progress != null
                                  ? CircularProgressIndicator()
                                  : Icon(Icons.download, color: Colors.green),
                              onPressed: () {
                                _downloadFile(
                                    file['url'], file['name'], context);
                              },
                            ),
                          );
                        }),
                    SizedBox(height: 30),
                    GestureDetector(
                      onTap: pickFile,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          width: MediaQuery.of(context).size.width / 2,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: textPresentation(
                              msg: 'Importer un fichier',
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }));
  }

  Future<void> _downloadFile(
      String url, String fileName, BuildContext context) async {
    try {
      // Demande la permission d'écrire dans le stockage
      var status = await Permission.storage.request();

      if (status.isGranted) {
        // Obtenir le répertoire Downloads
        Directory downloadsDirectory =
            Directory('/storage/emulated/0/Download');

        if (await downloadsDirectory.exists()) {
          String savePath = '${downloadsDirectory.path}/$fileName';

          // Télécharger le fichier
          Dio dio = Dio();
          FileDownloader.downloadFile(
              url: url,
              onProgress: (fileName, progresse) {
                // setState(() {
                progress = progresse;
                // });
              },
              onDownloadCompleted: (path) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Téléchargement terminé dans $path')));
              });

          // Afficher un message de succès
        } else {
          print('Erreur: Impossible de trouver le répertoire Downloads');
          throw Exception('Impossible d\'accéder au répertoire Downloads');
        }
      } else if (status.isDenied) {
        // Si la permission est refusée
        print('Permission refusée');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Permission refusée pour accéder au stockage')));
      } else if (status.isPermanentlyDenied) {
        // Si la permission est refusée de façon permanente, demander à l'utilisateur de l'activer manuellement
        openAppSettings();
      }
    } catch (e) {
      print('Erreur lors du téléchargement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')));
    }
  }
}
