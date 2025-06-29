import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_file_iai/models/tag.dart';
import 'package:share_file_iai/services/tag_service.dart';

class TagStatisticsPage extends StatefulWidget {
  @override
  _TagStatisticsPageState createState() => _TagStatisticsPageState();
}

class _TagStatisticsPageState extends State<TagStatisticsPage> {
  final TagService _tagService = TagService();
  Map<String, int> _tagUsageCount = {};
  Map<String, List<String>> _tagDocuments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Récupérer tous les documents de l'utilisateur
      final docsSnapshot = await FirebaseFirestore.instance
          .collection('folder')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final tagCount = <String, int>{};
      final tagDocs = <String, List<String>>{};

      for (var doc in docsSnapshot.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] ?? []);
        final docName = data['name'] ?? 'Document sans nom';

        for (String tagId in tags) {
          tagCount[tagId] = (tagCount[tagId] ?? 0) + 1;
          tagDocs[tagId] = tagDocs[tagId] ?? [];
          tagDocs[tagId]!.add(docName);
        }
      }

      setState(() {
        _tagUsageCount = tagCount;
        _tagDocuments = tagDocs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des statistiques: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques des Tags'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadStatistics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
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
                  'Aucun tag disponible',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Trier les tags par utilisation
        final sortedTags = List<Tag>.from(tags);
        sortedTags.sort((a, b) {
          final countA = _tagUsageCount[a.id] ?? 0;
          final countB = _tagUsageCount[b.id] ?? 0;
          return countB.compareTo(countA);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(tags),
              const SizedBox(height: 24),
              _buildDetailedStats(sortedTags),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<Tag> tags) {
    final totalTags = tags.length;
    final usedTags =
        tags.where((tag) => (_tagUsageCount[tag.id] ?? 0) > 0).length;
    final totalUsages =
        _tagUsageCount.values.fold(0, (sum, count) => sum + count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Tags',
                value: totalTags.toString(),
                icon: Icons.label,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Tags Utilisés',
                value: usedTags.toString(),
                icon: Icons.label_important,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Utilisations',
                value: totalUsages.toString(),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(List<Tag> sortedTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails par tag',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sortedTags.map((tag) => _buildTagStatCard(tag)).toList(),
      ],
    );
  }

  Widget _buildTagStatCard(Tag tag) {
    final count = _tagUsageCount[tag.id] ?? 0;
    final documents = _tagDocuments[tag.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _hexToColor(tag.color),
            shape: BoxShape.circle,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tag.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count utilisation${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text('Créé le ${_formatDate(tag.createdAt)}'),
        children: [
          if (documents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documents utilisant ce tag:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ...documents.map((docName) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.folder,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(docName)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ce tag n\'est utilisé par aucun document',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
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
}
