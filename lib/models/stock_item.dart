import 'genre.dart';
import 'stock_level.dart';

class StockItem {
  final String id;
  final String name;
  final Genre genre;
  final StockLevel stockLevel;
  final bool isDefault;

  const StockItem({
    required this.id,
    required this.name,
    required this.genre,
    this.stockLevel = StockLevel.full,
    this.isDefault = false,
  });

  StockItem copyWith({
    String? id,
    String? name,
    Genre? genre,
    StockLevel? stockLevel,
    bool? isDefault,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      stockLevel: stockLevel ?? this.stockLevel,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genre': genre.toJson(),
      'stockLevel': stockLevel.toJson(),
      'isDefault': isDefault,
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      genre: Genre.fromJson(json['genre'] as String),
      stockLevel: StockLevel.fromJson(json['stockLevel'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
