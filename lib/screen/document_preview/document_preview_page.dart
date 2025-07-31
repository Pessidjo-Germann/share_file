import 'package:flutter/material.dart';
import 'package:share_file_iai/models/document_file.dart';
import 'package:share_file_iai/services/document_preview_service.dart';
import 'package:share_file_iai/models/tag.dart';
import 'package:share_file_iai/services/tag_service.dart';
import 'package:share_file_iai/widgets/tag_widgets.dart';
import 'package:share_file_iai/widget/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentPreviewPage extends StatefulWidget {
  final String folderId;
  final String fileId;

  const DocumentPreviewPage({
    Key? key,
    required this.folderId,
    required this.fileId,
  }) : super(key: key);

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  final DocumentPreviewService _previewService = DocumentPreviewService();
  final TagService _tagService = TagService();
  DocumentFile? _document;
  String? _signedUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  List<String> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final document = await _previewService.getDocumentDetails(
          widget.folderId, widget.fileId);

      if (document == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Document non trouvé.'),
                backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      String? signedUrl;
      if (document.path.isNotEmpty) {
        try {
          signedUrl = await Supabase.instance.client.storage
              .from('files')
              .createSignedUrl(document.path, 300); // 5 minutes
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Erreur de création du lien: $e'),
                  backgroundColor: Colors.red),
            );
          }
        }
      }

      setState(() {
        _document = document;
        _signedUrl = signedUrl;
        _isLoading = false;
        if (document != null) {
          _nameController.text = document.name;
          _selectedTagIds = List.from(document.tags);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors du chargement du document: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document introuvable')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Document introuvable', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_document!.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_previewService.canEditDocument(_document!))
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _nameController.text = _document!.name;
                    _selectedTagIds = List.from(_document!.tags);
                  }
                });
              },
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: 'copy_link',
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('Copier le lien'),
                  ],
                ),
              ),
              if (_previewService.canEditDocument(_document!))
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aperçu du document
          _buildDocumentPreview(),
          const SizedBox(height: 24),

          // Informations du document
          _buildDocumentInfo(),
          const SizedBox(height: 24),

          // Tags
          _buildTagsSection(),
          const SizedBox(height: 24),

          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modifier le document',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Nom du document
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du document',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 20),

          // Tags
          const Text(
            'Tags',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Tag>>(
            stream: _tagService.getUserTags(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final tags = snapshot.data ?? [];
              if (tags.isEmpty) {
                return const Text(
                  'Aucun tag disponible. Créez-en un dans la gestion des tags.',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return TagSelector(
                availableTags: tags,
                selectedTagIds: _selectedTagIds,
                onTagsChanged: (selectedIds) {
                  setState(() {
                    _selectedTagIds = selectedIds;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 30),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  press: _saveChanges,
                  name: 'Enregistrer',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  press: () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = _document!.name;
                      _selectedTagIds = List.from(_document!.tags);
                    });
                  },
                  name: 'Annuler',
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _buildPreviewContent(),
    );
  }

  Widget _buildPreviewContent() {
    if (_signedUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              "Le lien pour ce fichier .",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    switch (_document!.documentType) {
      case DocumentType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _signedUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 48, color: Colors.red),
                    Text('Erreur lors du chargement'),
                  ],
                ),
              );
            },
          ),
        );

      case DocumentType.pdf:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Document PDF', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openDocument(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ouvrir'),
              ),
            ],
          ),
        );

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getDocumentIcon(),
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                _document!.documentType.displayName,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openDocument(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ouvrir'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDocumentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Nom', _document!.name),
            _buildInfoRow('Type', _document!.documentType.displayName),
            _buildInfoRow('Taille', _document!.formattedFileSize),
            _buildInfoRow('Uploadé le', _formatDate(_document!.uploadedAt)),
            if (_document!.mimeType != null)
              _buildInfoRow('Type MIME', _document!.mimeType!),
          ],
        ),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (_document!.tags.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Aucun tag associé à ce document',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Tag>>(
              stream: _tagService.getUserTags(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final allTags = snapshot.data!;
                final documentTags = allTags
                    .where((tag) => _document!.tags.contains(tag.id))
                    .toList();

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      documentTags.map((tag) => TagChip(tag: tag)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openDocument(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir le document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _downloadDocument(),
                icon: const Icon(Icons.download),
                label: const Text('Télécharger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyLink(),
                icon: const Icon(Icons.link),
                label: const Text('Copier lien'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getDocumentIcon() {
    switch (_document!.documentType) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.word:
        return Icons.description;
      case DocumentType.excel:
        return Icons.table_chart;
      case DocumentType.powerpoint:
        return Icons.slideshow;
      case DocumentType.text:
        return Icons.text_snippet;
      case DocumentType.image:
        return Icons.image;
      case DocumentType.video:
        return Icons.video_file;
      case DocumentType.audio:
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'download':
        _downloadDocument();
        break;
      case 'copy_link':
        _copyLink();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _openDocument() async {
    if (_signedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le lien pour ce fichier est invalide ou a expiré.')),
      );
      return;
    }
    try {
      final uri = Uri.parse(_signedUrl!);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossible d\'ouvrir le document');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _downloadDocument() {
    // La logique de téléchargement sera similaire à celle de list_file.dart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement démarré...')),
    );
  }

  Future<void> _copyLink() async {
    if (_signedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le lien pour ce fichier est invalide ou a expiré.')),
      );
      return;
    }
    try {
      await _previewService.copyDocumentLink(_signedUrl!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien temporaire copié')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      await _previewService.updateDocumentMetadata(
        widget.folderId,
        widget.fileId,
        name: _nameController.text.trim(),
        tags: _selectedTagIds,
      );

      await _loadDocument(); // Recharger les données
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document mis à jour avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer "${_document!.name}" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDocument();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument() async {
    if (_document == null) return;
    try {
      await _previewService.deleteDocument(
        widget.folderId,
        widget.fileId,
        _document!.path,
      );

      Navigator.of(context).pop(); // Retourner à la page précédente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
