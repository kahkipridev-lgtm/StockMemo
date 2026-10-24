// 買い物リストで購入済みにした瞬間の記録（統計ページの集計用）
// 買い物リスト本体はアイテム削除で消えるが、こちらは別に保持し続ける
class PurchaseLogEntry {
  final String id;
  final String name;
  final DateTime purchasedAt;

  const PurchaseLogEntry({
    required this.id,
    required this.name,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  static PurchaseLogEntry? fromJson(Map<String, dynamic> json) {
    final purchasedAt =
        DateTime.tryParse(json['purchasedAt'] as String? ?? '');
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (purchasedAt == null || id == null || name == null) return null;
    return PurchaseLogEntry(id: id, name: name, purchasedAt: purchasedAt);
  }
}
