class Tag {
  final String id;
  final String name;
  final String color;
  final DateTime createdAt;
  final String createdBy;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.createdBy,
  });

  factory Tag.fromFirestore(Map<String, dynamic> data, String id) {
    return Tag(
      id: id,
      name: data['name'] ?? '',
      color: data['color'] ?? '#2196F3',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
