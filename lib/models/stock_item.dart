import 'stock_level.dart';

class StockItem {
  final String id;
  final String name;
  final String genreId;
  final StockLevel stockLevel;
  final bool isDefault;
  final DateTime? statusUpdatedAt;

  const StockItem({
    required this.id,
    required this.name,
    required this.genreId,
    this.stockLevel = StockLevel.full,
    this.isDefault = false,
    this.statusUpdatedAt,
  });

  StockItem copyWith({
    String? id,
    String? name,
    String? genreId,
    StockLevel? stockLevel,
    bool? isDefault,
    DateTime? statusUpdatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      genreId: genreId ?? this.genreId,
      stockLevel: stockLevel ?? this.stockLevel,
      isDefault: isDefault ?? this.isDefault,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genre': genreId,
      'stockLevel': stockLevel.toJson(),
      'isDefault': isDefault,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      genreId: json['genre'] as String,
      stockLevel: StockLevel.fromJson(json['stockLevel'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.tryParse(json['statusUpdatedAt'] as String)
          : null,
    );
  }
}
