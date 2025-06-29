import 'package:flutter/material.dart';
import 'package:share_file_iai/models/tag.dart';
import 'package:share_file_iai/services/tag_service.dart';
import 'package:share_file_iai/widgets/tag_widgets.dart';
import 'package:share_file_iai/widget/bouton_continuer_2.dart';
import 'package:share_file_iai/screen/tags_statistics/tag_statistics_page.dart';

class TagsManagementPage extends StatefulWidget {
  @override
  _TagsManagementPageState createState() => _TagsManagementPageState();
}

class _TagsManagementPageState extends State<TagsManagementPage> {
  final TagService _tagService = TagService();
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = '#2196F3';
  String? _editingTagId;

  final List<String> _predefinedColors = [
    '#F44336', // Rouge
    '#E91E63', // Rose
    '#9C27B0', // Violet
    '#673AB7', // Violet foncé
    '#3F51B5', // Indigo
    '#2196F3', // Bleu
    '#03A9F4', // Bleu clair
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Vert
    '#8BC34A', // Vert clair
    '#CDDC39', // Lime
    '#FFEB3B', // Jaune
    '#FFC107', // Ambre
    '#FF9800', // Orange
    '#FF5722', // Orange foncé
    '#795548', // Brun
    '#607D8B', // Bleu gris
    '#9E9E9E', // Gris
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Tags'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Statistiques des tags',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TagStatisticsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulaire de création/modification
          _buildTagForm(),
          const Divider(),
          // Liste des tags
          Expanded(
            child: _buildTagsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingTagId == null ? 'Créer un nouveau tag' : 'Modifier le tag',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du tag',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
            maxLength: 20,
          ),
          const SizedBox(height: 16),
          const Text(
            'Couleur du tag',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildColorPicker(),
          const SizedBox(height: 16),
          // Aperçu du tag
          if (_nameController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aperçu:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TagChip(
                    tag: Tag(
                      id: 'preview',
                      name: _nameController.text,
                      color: _selectedColor,
                      createdAt: DateTime.now(),
                      createdBy: 'current_user',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BottonContinuer2(
                  size: MediaQuery.of(context).size,
                  press: _editingTagId == null ? _createTag : _updateTag,
                  name: _editingTagId == null ? 'Créer' : 'Modifier',
                ),
              ),
              if (_editingTagId != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: BottonContinuer2(
                    size: MediaQuery.of(context).size,
                    press: _cancelEdit,
                    name: 'Annuler',
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      height: 60,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _predefinedColors.length,
        itemBuilder: (context, index) {
          final color = _predefinedColors[index];
          final isSelected = color == _selectedColor;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: _hexToColor(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagsList() {
    return StreamBuilder<List<Tag>>(
      stream: _tagService.getUserTags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final tags = snapshot.data ?? [];

        if (tags.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.label_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun tag créé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Créez votre premier tag ci-dessus',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _hexToColor(tag.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(tag.name),
                subtitle: Text('Créé le ${_formatDate(tag.createdAt)}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _startEdit(tag);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(tag);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
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

  void _createTag() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom pour le tag'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _tagService.createTag(_nameController.text.trim(), _selectedColor);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag créé avec succès'),
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
  }

  void _updateTag() async {
    if (_nameController.text.trim().isEmpty || _editingTagId == null) {
      return;
    }

    try {
      await _tagService.updateTag(
          _editingTagId!, _nameController.text.trim(), _selectedColor);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag modifié avec succès'),
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
  }

  void _startEdit(Tag tag) {
    setState(() {
      _editingTagId = tag.id;
      _nameController.text = tag.name;
      _selectedColor = tag.color;
    });

    // Faire défiler vers le haut pour voir le formulaire
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _cancelEdit() {
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _editingTagId = null;
      _nameController.clear();
      _selectedColor = '#2196F3';
    });
  }

  void _showDeleteConfirmation(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tag'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer le tag "${tag.name}" ?\n\nCe tag sera supprimé de tous les documents qui l\'utilisent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTag(tag);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteTag(Tag tag) async {
    try {
      await _tagService.deleteTag(tag.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag supprimé avec succès'),
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
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
