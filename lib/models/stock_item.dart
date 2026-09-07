import 'stock_level.dart';

class StockItem {
  final String id;
  final String name;
  final String? yomi;
  final String genreId;
  final StockLevel stockLevel;
  final bool isDefault;
  final DateTime? statusUpdatedAt;
  // 「買ったばっかり」にした日時の履歴（在庫切れ予測に使う、古い順）
  final List<DateTime> restockHistory;

  const StockItem({
    required this.id,
    required this.name,
    this.yomi,
    required this.genreId,
    this.stockLevel = StockLevel.full,
    this.isDefault = false,
    this.statusUpdatedAt,
    this.restockHistory = const [],
  });

  StockItem copyWith({
    String? id,
    String? name,
    String? yomi,
    String? genreId,
    StockLevel? stockLevel,
    bool? isDefault,
    DateTime? statusUpdatedAt,
    List<DateTime>? restockHistory,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      yomi: yomi ?? this.yomi,
      genreId: genreId ?? this.genreId,
      stockLevel: stockLevel ?? this.stockLevel,
      isDefault: isDefault ?? this.isDefault,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      restockHistory: restockHistory ?? this.restockHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (yomi != null) 'yomi': yomi,
      'genre': genreId,
      'stockLevel': stockLevel.toJson(),
      'isDefault': isDefault,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'restockHistory':
          restockHistory.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['restockHistory'] as List<dynamic>?;
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      yomi: json['yomi'] as String?,
      genreId: json['genre'] as String,
      stockLevel: StockLevel.fromJson(json['stockLevel'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.tryParse(json['statusUpdatedAt'] as String)
          : null,
      restockHistory: rawHistory == null
          ? const []
          : rawHistory
              .map((e) => DateTime.tryParse(e as String))
              .whereType<DateTime>()
              .toList(),
    );
  }
}
