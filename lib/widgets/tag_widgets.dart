import 'package:flutter/material.dart';
import '../models/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final bool showDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TagChip({
    Key? key,
    required this.tag,
    this.isSelected = false,
    this.showDelete = false,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _hexToColor(tag.color).withOpacity(0.8)
              : _hexToColor(tag.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hexToColor(tag.color),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.name,
              style: TextStyle(
                color: isSelected ? Colors.white : _hexToColor(tag.color),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (showDelete && onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isSelected ? Colors.white : _hexToColor(tag.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }
}

class TagSelector extends StatefulWidget {
  final List<Tag> availableTags;
  final List<String> selectedTagIds;
  final Function(List<String>) onTagsChanged;
  final bool allowMultipleSelection;

  const TagSelector({
    Key? key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.allowMultipleSelection = true,
  }) : super(key: key);

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  late List<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: widget.availableTags.map((tag) {
        final isSelected = _selectedTagIds.contains(tag.id);
        return TagChip(
          tag: tag,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (widget.allowMultipleSelection) {
                if (isSelected) {
                  _selectedTagIds.remove(tag.id);
                } else {
                  _selectedTagIds.add(tag.id);
                }
              } else {
                _selectedTagIds.clear();
                if (!isSelected) {
                  _selectedTagIds.add(tag.id);
                }
              }
            });
            widget.onTagsChanged(_selectedTagIds);
          },
        );
      }).toList(),
    );
  }
}

class SelectedTagsDisplay extends StatelessWidget {
  final List<Tag> selectedTags;
  final Function(String)? onTagRemoved;

  const SelectedTagsDisplay({
    Key? key,
    required this.selectedTags,
    this.onTagRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      children: selectedTags.map((tag) {
        return TagChip(
          tag: tag,
          isSelected: true,
          showDelete: onTagRemoved != null,
          onDelete: onTagRemoved != null ? () => onTagRemoved!(tag.id) : null,
        );
      }).toList(),
    );
  }
}

class TagFilterWidget extends StatefulWidget {
  final List<Tag> availableTags;
  final List<String> selectedTagIds;
  final Function(List<String>) onTagsChanged;
  final String? title;
  final bool showClearAll;

  const TagFilterWidget({
    Key? key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.title,
    this.showClearAll = true,
  }) : super(key: key);

  @override
  State<TagFilterWidget> createState() => _TagFilterWidgetState();
}

class _TagFilterWidgetState extends State<TagFilterWidget> {
  late List<String> _selectedTagIds;
  final TextEditingController _searchController = TextEditingController();
  List<Tag> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.selectedTagIds);
    _filteredTags = widget.availableTags;
  }

  @override
  void didUpdateWidget(TagFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableTags != widget.availableTags) {
      _filterTags();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTags() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTags = widget.availableTags.where((tag) {
        return tag.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],

        // Barre de recherche
        if (widget.availableTags.length > 5) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un tag...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: (_) => _filterTags(),
          ),
          const SizedBox(height: 12),
        ],

        // Boutons d'action
        if (widget.showClearAll && _selectedTagIds.isNotEmpty) ...[
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTagIds.clear();
                  });
                  widget.onTagsChanged(_selectedTagIds);
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Tout désélectionner'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedTagIds.length} sélectionné(s)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Liste des tags
        if (_filteredTags.isEmpty && _searchController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aucun tag trouvé',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filteredTags.map((tag) {
              final isSelected = _selectedTagIds.contains(tag.id);
              return TagChip(
                tag: tag,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTagIds.remove(tag.id);
                    } else {
                      _selectedTagIds.add(tag.id);
                    }
                  });
                  widget.onTagsChanged(_selectedTagIds);
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}

class TagStatisticsWidget extends StatelessWidget {
  final List<Tag> tags;
  final Map<String, int> tagUsageCount;

  const TagStatisticsWidget({
    Key? key,
    required this.tags,
    required this.tagUsageCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedTags = List<Tag>.from(tags);
    sortedTags.sort((a, b) {
      final countA = tagUsageCount[a.id] ?? 0;
      final countB = tagUsageCount[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques des tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sortedTags.take(10).map((tag) {
          final count = tagUsageCount[tag.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                TagChip(tag: tag),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
