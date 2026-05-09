import 'genre.dart';
import 'stock_level.dart';

class StockItem {
  final String id;
  final String name;
  final Genre genre;
  final StockLevel stockLevel;
  final bool isDefault;
  final DateTime? statusUpdatedAt;

  const StockItem({
    required this.id,
    required this.name,
    required this.genre,
    this.stockLevel = StockLevel.full,
    this.isDefault = false,
    this.statusUpdatedAt,
  });

  StockItem copyWith({
    String? id,
    String? name,
    Genre? genre,
    StockLevel? stockLevel,
    bool? isDefault,
    DateTime? statusUpdatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      stockLevel: stockLevel ?? this.stockLevel,
      isDefault: isDefault ?? this.isDefault,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genre': genre.toJson(),
      'stockLevel': stockLevel.toJson(),
      'isDefault': isDefault,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      genre: Genre.fromJson(json['genre'] as String),
      stockLevel: StockLevel.fromJson(json['stockLevel'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.tryParse(json['statusUpdatedAt'] as String)
          : null,
    );
  }
}
