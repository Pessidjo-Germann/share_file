import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_file_iai/models/document_file.dart';
import 'package:share_file_iai/models/tag.dart';
import 'package:share_file_iai/services/tag_service.dart';
import 'package:share_file_iai/widgets/tag_widgets.dart';
import 'package:share_file_iai/screen/document_preview/document_preview_page.dart';

class FileCard extends StatelessWidget {
  final QueryDocumentSnapshot fileDoc;
  final String folderId;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool showActions;

  const FileCard({
    Key? key,
    required this.fileDoc,
    required this.folderId,
    this.onDownload,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = fileDoc.data() as Map<String, dynamic>;
    final fileName = data['name'] ?? 'Nom indisponible';
    final fileUrl = data['url'] ?? '';
    final uploadedAt = data['uploadedAt'] != null
        ? data['uploadedAt'].toDate()
        : DateTime.now();
    final fileSize = data['fileSize'];
    final tags = List<String>.from(data['tags'] ?? []);

    // Créer un objet DocumentFile temporaire pour déterminer le type
    final documentFile = DocumentFile.fromFirestore(data, fileDoc.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _previewFile(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et actions
              Row(
                children: [
                  _buildFileIcon(documentFile),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          documentFile.documentType.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showActions) _buildActionButtons(context),
                ],
              ),

              const SizedBox(height: 12),

              // Informations du fichier
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(uploadedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (fileSize != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatFileSize(fileSize),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),

              // Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                StreamBuilder<List<Tag>>(
                  stream: TagService().getUserTags(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final allTags = snapshot.data!;
                    final fileTags =
                        allTags.where((tag) => tags.contains(tag.id)).toList();

                    if (fileTags.isEmpty) return const SizedBox.shrink();

                    return Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          fileTags.map((tag) => TagChip(tag: tag)).toList(),
                    );
                  },
                ),
              ],

              // Aperçu pour les images
              if (documentFile.documentType == DocumentType.image) ...[
                const SizedBox(height: 8),
                _buildImagePreview(context, data['path'] ?? ''),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(DocumentFile documentFile) {
    IconData iconData;
    Color iconColor;

    switch (documentFile.documentType) {
      case DocumentType.image:
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case DocumentType.pdf:
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case DocumentType.text:
      case DocumentType.word:
        iconData = Icons.description;
        iconColor = Colors.blue[700]!;
        break;
      case DocumentType.excel:
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case DocumentType.powerpoint:
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case DocumentType.video:
        iconData = Icons.video_library;
        iconColor = Colors.purple;
        break;
      case DocumentType.audio:
        iconData = Icons.audiotrack;
        iconColor = Colors.orange[700]!;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: () => _previewFile(context),
          tooltip: 'Prévisualiser',
          color: Colors.blue,
        ),
        IconButton(
          icon: const Icon(Icons.download, size: 20),
          onPressed: onDownload,
          tooltip: 'Télécharger',
          color: Colors.green,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Partager'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info, size: 18),
                  SizedBox(width: 8),
                  Text('Informations'),
                ],
              ),
            ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context, String path) {
    if (path.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('Aperçu non disponible (chemin manquant)'),
        ),
      );
    }

    return FutureBuilder<String>(
      future: Supabase.instance.client.storage
          .from('files')
          .createSignedUrl(path, 3600), // URL valide pour 1 heure
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 4),
                  const Text('Erreur de chargement de l\'aperçu'),
                ],
              ),
            ),
          );
        }

        final signedUrl = snapshot.data!;
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: signedUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        );
      },
    );
  }

  void _previewFile(BuildContext context) {
    final data = fileDoc.data() as Map<String, dynamic>;
    final fileName = data['name'] ?? 'Nom indisponible';
    final fileUrl = data['url'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewPage(
          folderId: folderId,
          fileId: fileDoc.id,
          // fileName: fileName,
          // fileUrl: fileUrl,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'share':
        _shareFile(context);
        break;
      case 'info':
        _showFileInfo(context);
        break;
      case 'delete':
        if (onDelete != null) onDelete!();
        break;
    }
  }

  void _shareFile(BuildContext context) {
    // La fonctionnalité de partage de lien direct est désactivée car les URL
    // ne sont pas publiques. Une logique de partage plus avancée est nécessaire.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Le partage de lien direct n\'est pas disponible pour les fichiers privés.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showFileInfo(BuildContext context) {
    final data = fileDoc.data() as Map<String, dynamic>;
    final fileName = data['name'] ?? 'Nom indisponible';
    final fileSize = data['fileSize'];
    final uploadedAt = data['uploadedAt'] != null
        ? data['uploadedAt'].toDate()
        : DateTime.now();
    final createdBy = data['createdBy'] ?? 'Inconnu';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations du fichier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nom', fileName),
            _buildInfoRow('Taille',
                fileSize != null ? _formatFileSize(fileSize) : 'Inconnue'),
            _buildInfoRow('Date d\'ajout', _formatDateTime(uploadedAt)),
            _buildInfoRow('ID du fichier', fileDoc.id),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
