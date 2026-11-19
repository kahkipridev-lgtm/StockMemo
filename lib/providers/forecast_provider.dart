import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock_item.dart';
import '../models/stock_level.dart';
import '../services/stock_forecast.dart';
import 'inventory_provider.dart';
import 'purchase_log_provider.dart';
import 'shopping_list_provider.dart';

// 予測の基準にする「今」。アプリ復帰時やタブ表示時に更新して、日付の変わり目に追従させる
class ForecastClockNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void refresh() => state = DateTime.now();
}

final forecastClockProvider = NotifierProvider<ForecastClockNotifier, DateTime>(
  ForecastClockNotifier.new,
);

ForecastLevel _toForecastLevel(StockLevel level) => switch (level) {
  StockLevel.full => ForecastLevel.full,
  StockLevel.low => ForecastLevel.low,
  StockLevel.empty => ForecastLevel.empty,
};

/// 在庫アイテムと購入記録から、在庫予測を計算する（読み込み中は null）
final forecastProvider = Provider<ForecastResult?>((ref) {
  final items = ref.watch(inventoryProvider).value;
  final purchaseLog = ref.watch(purchaseLogProvider).value;
  if (items == null || purchaseLog == null) return null;
  final now = ref.watch(forecastClockProvider);

  // 買い物リストの購入記録を、名前（または読み）が一致する在庫アイテムに振り分ける。
  // 一致しないものは「買い物リストだけで繰り返し買っているもの」として購入間隔から予測する
  final itemsByKey = <String, List<StockItem>>{};
  for (final item in items) {
    final keys = {
      normalizeForecastName(item.name),
      if (item.yomi != null && item.yomi!.trim().isNotEmpty)
        normalizeForecastName(item.yomi!),
    };
    for (final key in keys) {
      (itemsByKey[key] ??= []).add(item);
    }
  }

  final itemIds = {for (final item in items) item.id};
  final purchasesByItem = <String, List<DateTime>>{};
  final seriesPurchases = <String, List<DateTime>>{};
  final seriesNames = <String, String>{};
  for (final entry in purchaseLog) {
    // 予測画面の「買ってきた」で記録したものは、そのアイテムだけに付ける
    final ownerId = entry.itemId;
    if (ownerId != null && itemIds.contains(ownerId)) {
      (purchasesByItem[ownerId] ??= []).add(entry.purchasedAt);
      continue;
    }
    final key = normalizeForecastName(entry.name);
    if (key.isEmpty) continue;
    final matched = itemsByKey[key];
    if (matched != null) {
      // 同じ名前（読み）のアイテムが複数あるときは、在庫切れ・残りわずかのものを優先する
      final notFull = [
        for (final item in matched)
          if (item.stockLevel != StockLevel.full) item,
      ];
      final targets = matched.length > 1 && notFull.isNotEmpty
          ? notFull
          : matched;
      for (final item in targets) {
        (purchasesByItem[item.id] ??= []).add(entry.purchasedAt);
      }
    } else {
      (seriesPurchases[key] ??= []).add(entry.purchasedAt);
      // 表示名は一番最近の書き方に合わせる（購入記録は古い順に並んでいる）
      seriesNames[key] = entry.name.trim();
    }
  }

  return const StockForecaster().run(
    items: [
      for (final item in items)
        ForecastItemInput(
          id: item.id,
          name: item.name,
          currentLevel: _toForecastLevel(item.stockLevel),
          history: [
            for (final h in item.statusHistory)
              ForecastEvent(h.timestamp, _toForecastLevel(h.level)),
          ],
          purchases: purchasesByItem[item.id] ?? const [],
        ),
    ],
    purchaseSeries: [
      for (final e in seriesPurchases.entries)
        PurchaseSeriesInput(name: seriesNames[e.key]!, purchases: e.value),
    ],
    now: now,
  );
});

/// 買い物リスト（未購入）に入っている名前の正規化済みセット
final shoppingListKeysProvider = Provider<Set<String>>((ref) {
  final items = ref.watch(shoppingListProvider).value ?? const [];
  return {
    for (final item in items)
      if (!item.isPurchased) normalizeForecastName(item.name),
  };
});

/// 「もうすぐ切れそう」と判定する残り日数
const forecastSoonDays = 3;

/// 予測日まであと何日か（カレンダーの日付単位。今日なら0、過ぎていればマイナス）
int forecastDaysUntil(StockForecast f, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final p = f.predictedAt;
  return DateTime(p.year, p.month, p.day).difference(today).inDays;
}

/// 予測が「もうすぐ切れそう」で、まだ買い物リストにも出ていないもの（タブのバッジ用）
/// 記録1回分だけの「目安」の予測は外れやすいので、バッジには数えない
/// （記録が多くてもばらつきが大きくて「目安」のものは数える）
final forecastSoonCountProvider = Provider<int>((ref) {
  final result = ref.watch(forecastProvider);
  if (result == null) return 0;
  final now = ref.watch(forecastClockProvider);
  final listKeys = ref.watch(shoppingListKeysProvider);
  final items = ref.watch(inventoryProvider).value ?? const [];
  final levelById = {for (final item in items) item.id: item.stockLevel};
  return result.forecasts
      .where(
        (f) =>
            forecastDaysUntil(f, now) <= forecastSoonDays &&
            !f.isStale(now) &&
            !(f.confidence == ForecastConfidence.low && f.sampleCount <= 1) &&
            // アプリ上の状態で判定する（購入記録から補充を推定したものでも、在庫切れ・残りわずかの
            // ままなら買い物リストに出ている）
            (f.itemId == null
                ? f.currentLevel == ForecastLevel.full
                : levelById[f.itemId] == StockLevel.full) &&
            !listKeys.contains(normalizeForecastName(f.name)),
      )
      .length;
});

/// 予測カードの在庫アイテムの、アプリ上の今の状態（購入記録だけのものは null）
StockLevel? appLevelOf(WidgetRef ref, StockForecast f) {
  final id = f.itemId;
  if (id == null) return null;
  final items = ref.watch(inventoryProvider).value ?? const [];
  return items.where((i) => i.id == id).firstOrNull?.stockLevel;
}
