import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:share_file_iai/constante.dart';
import 'package:share_file_iai/screen/document_preview/document_preview_page.dart';

class SharedFolderContentPage extends StatefulWidget {
  const SharedFolderContentPage(
      {super.key, required this.name, required this.id});
  final String name, id;

  @override
  State<SharedFolderContentPage> createState() =>
      _SharedFolderContentPageState();
}

class _SharedFolderContentPageState extends State<SharedFolderContentPage> {
  double? progress;
  String? _progressText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          if (files.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun fichier dans ce dossier partagé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final data = file.data() as Map<String, dynamic>;
                    final fileName = data['name'] ?? 'Nom indisponible';
                    final fileUrl = data['url'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                            if (data['fileSize'] != null)
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
                            const PopupMenuItem(
                              value: 'preview',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility),
                                  SizedBox(width: 8),
                                  Text('Prévisualiser'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'download',
                              child: Row(
                                children: [
                                  Icon(Icons.download),
                                  SizedBox(width: 8),
                                  Text('Télécharger'),
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
                            }
                          },
                        ),
                        onTap: () => _previewFile(file),
                      ),
                    );
                  },
                ),
              ),
              if (progress != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(_progressText ?? 'Téléchargement en cours...'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text('${(progress! * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return const Icon(Icons.image, color: Colors.green);
      case 'mp4':
      case 'avi':
      case 'mov':
        return const Icon(Icons.video_file, color: Colors.purple);
      case 'mp3':
      case 'wav':
        return const Icon(Icons.audio_file, color: Colors.orange);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue);
      case 'txt':
        return const Icon(Icons.text_snippet, color: Colors.grey);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return 'Inconnue';

    final bytes = size as int;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _previewFile(QueryDocumentSnapshot file) {
    final data = file.data() as Map<String, dynamic>;
    final fileName = data['name'] ?? 'Nom indisponible';
    final fileUrl = data['url'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewPage(
          folderId: widget.id,
          fileId: file.id,
          // fileName: fileName,
          // fileUrl: fileUrl,
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    final encodedUrl = Uri.encodeFull(url);

    setState(() {
      _progressText = 'Téléchargement en cours...';
      progress = 0.0;
    });

    FileDownloader.downloadFile(
      url: encodedUrl,
      name: fileName,
      onProgress: (fileName, progressValue) {
        if (mounted) {
          setState(() {
            progress = progressValue / 100;
          });
        }
      },
      onDownloadCompleted: (path) {
        if (mounted) {
          setState(() {
            progress = null;
            _progressText = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fichier téléchargé: $path'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onDownloadError: (String error) {
        if (mounted) {
          setState(() {
            progress = null;
            _progressText = null;
          });
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
}
