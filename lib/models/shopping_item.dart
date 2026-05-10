class ShoppingItem {
  final String id;
  final String name;
  final bool isPurchased;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.isPurchased = false,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isPurchased,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPurchased': isPurchased,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isPurchased: json['isPurchased'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
