import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tag.dart';
import '../../services/tag_service.dart';
import '../../widgets/tag_widgets.dart';

class TagManagementPage extends StatefulWidget {
  static const String routeName = '/tag-management';

  @override
  State<TagManagementPage> createState() => _TagManagementPageState();
}

class _TagManagementPageState extends State<TagManagementPage> {
  final TagService _tagService = TagService();
  final TextEditingController _tagNameController = TextEditingController();
  String _selectedColor = '#2196F3';

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
    '#FF5722', // Orange rouge
    '#795548', // Marron
    '#9E9E9E', // Gris
    '#607D8B', // Bleu gris
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Tags'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildCreateTagSection(),
          const Divider(),
          Expanded(
            child: _buildTagsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTagSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Créer un nouveau tag',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du tag',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Couleur du tag',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildColorSelector(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Créer le tag'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _predefinedColors.map((color) {
        final isSelected = color == _selectedColor;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hexToColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
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
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final tags = snapshot.data ?? [];

        if (tags.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.label_outline, size: 64, color: Colors.grey),
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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _hexToColor(tag.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(tag.name),
                subtitle: Text('Créé le ${_formatDate(tag.createdAt)}'),
                trailing: PopupMenuButton(
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
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editTag(tag);
                    } else if (value == 'delete') {
                      _deleteTag(tag);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _createTag() async {
    final name = _tagNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom pour le tag'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _tagService.createTag(name, _selectedColor);
      _tagNameController.clear();
      setState(() {
        _selectedColor = '#2196F3';
      });
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

  void _editTag(Tag tag) {
    final nameController = TextEditingController(text: tag.name);
    String selectedColor = tag.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du tag',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Couleur:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedColors.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _hexToColor(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await _tagService.updateTag(tag.id, name, selectedColor);
                    Navigator.pop(context);
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
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTag(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tag'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer le tag "${tag.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _tagService.deleteTag(tag.id);
                Navigator.pop(context);
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }
}
