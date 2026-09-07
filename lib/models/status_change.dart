import 'stock_level.dart';

// 在庫ステータスが変化した瞬間の記録（在庫切れ予測などの分析に使う）
class StatusChange {
  final DateTime timestamp;
  final StockLevel level;

  const StatusChange({required this.timestamp, required this.level});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.toJson(),
      };

  static StatusChange? fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
    final level = json['level'] as String?;
    if (timestamp == null || level == null) return null;
    return StatusChange(timestamp: timestamp, level: StockLevel.fromJson(level));
  }
}
