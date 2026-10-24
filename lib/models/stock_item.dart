import 'status_change.dart';
import 'stock_level.dart';

class StockItem {
  final String id;
  final String name;
  final String? yomi;
  final String genreId;
  final StockLevel stockLevel;
  final bool isDefault;
  final String? memo;
  final DateTime? statusUpdatedAt;
  // アイテムがインベントリに追加された日時（在庫切れ予測などの分析に使う）
  final DateTime? createdAt;
  // ステータスが変化するたびの記録（在庫切れ予測などの分析に使う、古い順）
  final List<StatusChange> statusHistory;
  // 在庫切れから在庫ありに戻した直後かどうか（買い物リストの在庫切れ欄に取消線付きで残す用）
  final bool justRestocked;

  const StockItem({
    required this.id,
    required this.name,
    this.yomi,
    required this.genreId,
    this.stockLevel = StockLevel.full,
    this.isDefault = false,
    this.memo,
    this.statusUpdatedAt,
    this.createdAt,
    this.statusHistory = const [],
    this.justRestocked = false,
  });

  StockItem copyWith({
    String? id,
    String? name,
    String? yomi,
    String? genreId,
    StockLevel? stockLevel,
    bool? isDefault,
    String? memo,
    bool clearMemo = false,
    DateTime? statusUpdatedAt,
    DateTime? createdAt,
    List<StatusChange>? statusHistory,
    bool? justRestocked,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      yomi: yomi ?? this.yomi,
      genreId: genreId ?? this.genreId,
      stockLevel: stockLevel ?? this.stockLevel,
      isDefault: isDefault ?? this.isDefault,
      memo: clearMemo ? null : (memo ?? this.memo),
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      statusHistory: statusHistory ?? this.statusHistory,
      justRestocked: justRestocked ?? this.justRestocked,
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
      if (memo != null) 'memo': memo,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
      'justRestocked': justRestocked,
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['statusHistory'] as List<dynamic>?;
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      yomi: json['yomi'] as String?,
      genreId: json['genre'] as String,
      stockLevel: StockLevel.fromJson(json['stockLevel'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      memo: json['memo'] as String?,
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.tryParse(json['statusUpdatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      statusHistory: rawHistory == null
          ? const []
          : rawHistory
              .map((e) => StatusChange.fromJson(e as Map<String, dynamic>))
              .whereType<StatusChange>()
              .toList(),
      justRestocked: json['justRestocked'] as bool? ?? false,
    );
  }
}
