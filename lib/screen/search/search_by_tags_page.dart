import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_file_iai/models/tag.dart';
import 'package:share_file_iai/services/tag_service.dart';
import 'package:share_file_iai/widgets/tag_widgets.dart';
import 'package:share_file_iai/screen/liste_fichier/list_file.dart';

class SearchByTagsPage extends StatefulWidget {
  @override
  _SearchByTagsPageState createState() => _SearchByTagsPageState();
}

class _SearchByTagsPageState extends State<SearchByTagsPage> {
  final TagService _tagService = TagService();
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTagIds = [];
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche par Tags'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Section de recherche
          _buildSearchSection(),
          const Divider(),
          // Résultats
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherche par nom
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher par nom de document',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => _performSearch(),
          ),
          const SizedBox(height: 16),

          // Sélection des tags
          const Text(
            'Filtrer par tags',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Tag>>(
            stream: _tagService.getUserTags(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
                  _performSearch();
                },
              );
            },
          ),

          // Tags sélectionnés
          if (_selectedTagIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Tags sélectionnés:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Tag>>(
              stream: _tagService.getUserTags(),
              builder: (context, snapshot) {
                final allTags = snapshot.data ?? [];
                final selectedTags = allTags
                    .where((tag) => _selectedTagIds.contains(tag.id))
                    .toList();

                return SelectedTagsDisplay(
                  selectedTags: selectedTags,
                  onTagRemoved: (tagId) {
                    setState(() {
                      _selectedTagIds.remove(tagId);
                    });
                    _performSearch();
                  },
                );
              },
            ),
          ],

          // Bouton de recherche
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _performSearch,
              icon: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty &&
        (_selectedTagIds.isNotEmpty || _searchController.text.isNotEmpty)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun document trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres critères de recherche',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Recherchez vos documents',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Utilisez les tags ou le nom pour filtrer vos documents',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final document = _searchResults[index];
        final data = document.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.folder,
              color: Colors.yellow[700],
              size: 40,
            ),
            title: Text(
              data['name'] ?? 'Nom indisponible',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catégorie: ${data['category'] ?? 'Non définie'}'),
                if (data['tags'] != null && (data['tags'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: StreamBuilder<List<Tag>>(
                      stream: _tagService.getUserTags(),
                      builder: (context, tagSnapshot) {
                        if (!tagSnapshot.hasData)
                          return const SizedBox.shrink();

                        final allTags = tagSnapshot.data!;
                        final documentTagIds =
                            List<String>.from(data['tags'] ?? []);
                        final documentTags = allTags
                            .where((tag) => documentTagIds.contains(tag.id))
                            .toList();

                        return Wrap(
                          spacing: 4,
                          children: documentTags
                              .map((tag) => TagChip(tag: tag))
                              .toList(),
                        );
                      },
                    ),
                  ),
                if (data['createdAt'] != null)
                  Text(
                    'Créé le: ${_formatDate(data['createdAt'].toDate())}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Naviguer vers le contenu du dossier
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileListPage(
                    name: data['name'] ?? 'Document',
                    id: document.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _performSearch() async {
    setState(() {
      _isSearching = true;
    });

    try {
      List<QueryDocumentSnapshot> results = [];

      if (_selectedTagIds.isNotEmpty) {
        // Recherche par tags
        final tagResults =
            await _tagService.getDocumentsByTags(_selectedTagIds).first;
        results = tagResults;
      } else {
        // Si aucun tag sélectionné, récupérer tous les documents de l'utilisateur
        final currentUser = _tagService.currentUser;
        if (currentUser != null) {
          final allDocs = await FirebaseFirestore.instance
              .collection('folder')
              .where('createdBy', isEqualTo: currentUser.uid)
              .get();
          results = allDocs.docs;
        }
      }

      // Filtrer par nom si spécifié
      if (_searchController.text.isNotEmpty) {
        final searchQuery = _searchController.text.toLowerCase();
        results = results.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
