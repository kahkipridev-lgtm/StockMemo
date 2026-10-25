import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../models/stock_level.dart';
import 'genre_provider.dart';
import 'inventory_provider.dart';
import 'purchase_log_provider.dart';

final achievementCategoriesProvider =
    Provider<List<AchievementCategory>>((ref) {
  final purchaseLog = ref.watch(purchaseLogProvider).value ?? [];
  final items = ref.watch(inventoryProvider).value ?? [];
  final firstLaunch = ref.watch(firstLaunchAtProvider).value;

  final totalPurchases = purchaseLog.length;

  final dailyCounts = <DateTime, int>{};
  for (final e in purchaseLog) {
    final day =
        DateTime(e.purchasedAt.year, e.purchasedAt.month, e.purchasedAt.day);
    dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
  }
  final maxDaily = dailyCounts.values.fold<int>(0, (m, v) => v > m ? v : m);

  final daysSinceStart = firstLaunch != null
      ? DateTime.now()
              .difference(
                  DateTime(firstLaunch.year, firstLaunch.month, firstLaunch.day))
              .inDays +
          1
      : 0;

  final itemCounts = <String, int>{};
  for (final e in purchaseLog) {
    itemCounts[e.name] = (itemCounts[e.name] ?? 0) + 1;
  }
  String? topItemName;
  var topItemCount = 0;
  itemCounts.forEach((name, count) {
    if (count > topItemCount) {
      topItemCount = count;
      topItemName = name;
    }
  });

  // 「在庫切れ→在庫あり」に変更した実績があるジャンルを集計する
  final restockedGenreIds = <String>{};
  for (final item in items) {
    final history = item.statusHistory;
    for (var i = 1; i < history.length; i++) {
      if (history[i - 1].level == StockLevel.empty &&
          history[i].level == StockLevel.full) {
        restockedGenreIds.add(item.genreId);
        break;
      }
    }
  }
  final allGenres = ref.watch(allGenresProvider);
  final allGenresCovered = allGenres.isNotEmpty &&
      allGenres.every((g) => restockedGenreIds.contains(g.id));

  final emptyEventCount = items
      .expand((i) => i.statusHistory)
      .where((h) => h.level == StockLevel.empty)
      .length;

  final maxPurchasedNameLength = purchaseLog.fold<int>(
      0, (max, e) => e.name.length > max ? e.name.length : max);

  return [
    AchievementCategory(
      title: '累計購入数',
      achievements: [
        _tier('total_1', totalPurchases >= 1, 'お買い物デビュー',
            'はじめて買い物を購入済みにした', Icons.celebration_rounded, const Color(0xFFE1AF64)),
        _tier('total_10', totalPurchases >= 10, 'ショッピング見習い',
            '累計10個購入した', Icons.shopping_basket_rounded, const Color(0xFF2E7D32)),
        _tier('total_50', totalPurchases >= 50, 'ストック番長',
            '累計50個購入した', Icons.store_rounded, const Color(0xFF1565C0)),
        _tier('total_150', totalPurchases >= 150, '買い物マスター',
            '累計150個購入した', Icons.workspace_premium_rounded, const Color(0xFF9B7EC8)),
        _tier('total_500', totalPurchases >= 500, '在庫の帝王',
            '累計500個購入した', Icons.emoji_events_rounded, const Color(0xFFC0392B)),
        _tier('total_1000', totalPurchases >= 1000, '買い物の神',
            '累計1000個購入した', Icons.auto_awesome_rounded, const Color(0xFF9B7EC8)),
      ],
    ),
    AchievementCategory(
      title: '1日の購入数',
      achievements: [
        _tier('daily_3', maxDaily >= 3, 'ちょっとした大量購入',
            '1日で3個購入した', Icons.shopping_cart_rounded, const Color(0xFF2E7D32)),
        _tier('daily_5', maxDaily >= 5, 'カートがパンパン',
            '1日で5個購入した', Icons.shopping_cart_checkout_rounded, const Color(0xFF1565C0)),
        _tier('daily_10', maxDaily >= 10, '爆買い伝説',
            '1日で10個購入した', Icons.local_fire_department_rounded, const Color(0xFFC0392B)),
        _tier('daily_20', maxDaily >= 20, '買い物の鬼',
            '1日で20個購入した', Icons.whatshot_rounded, const Color(0xFF7A5100)),
      ],
    ),
    AchievementCategory(
      title: '継続日数',
      achievements: [
        _tier('days_7', daysSinceStart >= 7, '1週間続いた',
            '利用開始から7日経過した', Icons.looks_one_rounded, const Color(0xFF2E7D32)),
        _tier('days_30', daysSinceStart >= 30, 'ひと月選手',
            '利用開始から30日経過した', Icons.calendar_month_rounded, const Color(0xFF1565C0)),
        _tier('days_100', daysSinceStart >= 100, '百日の縁',
            '利用開始から100日経過した', Icons.auto_awesome_rounded, const Color(0xFF9B7EC8)),
        _tier('days_365', daysSinceStart >= 365, '一年生活インフラ',
            '利用開始から365日経過した', Icons.emoji_events_rounded, const Color(0xFFC0392B)),
      ],
    ),
    AchievementCategory(
      title: 'いちばんの相棒',
      achievements: [
        _loveTier('love_5', topItemCount >= 5, topItemName, 5),
        _loveTier('love_15', topItemCount >= 15, topItemName, 15),
        _loveTier('love_30', topItemCount >= 30, topItemName, 30),
        _loveTier('love_50', topItemCount >= 50, topItemName, 50),
        _loveTier('love_100', topItemCount >= 100, topItemName, 100),
      ],
    ),
    AchievementCategory(
      title: '長い名前チャレンジ',
      achievements: [
        _tier('name_10', maxPurchasedNameLength >= 10, '長い名前も恐れない',
            '10文字以上のアイテムを購入した', Icons.text_fields_rounded, const Color(0xFF2E7D32)),
        _tier('name_15', maxPurchasedNameLength >= 15, '呪文級ネーミング',
            '15文字以上のアイテムを購入した', Icons.auto_stories_rounded, const Color(0xFF1565C0)),
        _tier('name_20', maxPurchasedNameLength >= 20, 'もはや呪文',
            '20文字以上のアイテムを購入した', Icons.menu_book_rounded, const Color(0xFF9B7EC8)),
      ],
    ),
    AchievementCategory(
      title: 'コレクション',
      achievements: [
        _tier('all_genres', allGenresCovered, '全ジャンル制覇',
            'すべてのジャンルで在庫切れから在庫ありに変更した', Icons.diversity_1_rounded, const Color(0xFFB8860B)),
      ],
    ),
    AchievementCategory(
      title: '在庫切れ経験',
      achievements: [
        _tier('empty_1', emptyEventCount >= 1, 'はじめての在庫切れ',
            '在庫切れを1回経験した', Icons.sentiment_dissatisfied_rounded, const Color(0xFFC0392B)),
        _tier('empty_20', emptyEventCount >= 20, '在庫切れ常連',
            '在庫切れを20回経験した', Icons.replay_rounded, const Color(0xFFB8860B)),
        _tier('empty_50', emptyEventCount >= 50, '在庫切れマニア',
            '在庫切れを50回経験した', Icons.warning_amber_rounded, const Color(0xFF7A5100)),
        _tier('empty_100', emptyEventCount >= 100, '在庫切れの主',
            '在庫切れを100回経験した', Icons.local_fire_department_rounded, const Color(0xFFC0392B)),
        _tier('empty_500', emptyEventCount >= 500, '在庫切れとは腐れ縁',
            '在庫切れを500回経験した', Icons.auto_awesome_rounded, const Color(0xFF9B7EC8)),
      ],
    ),
  ];
});

Achievement _tier(String id, bool unlocked, String title, String description,
    IconData icon, Color color) {
  return Achievement(
    id: id,
    title: title,
    description: description,
    icon: icon,
    color: color,
    unlocked: unlocked,
  );
}

Achievement _loveTier(
    String id, bool unlocked, String? itemName, int threshold) {
  final name = itemName ?? 'それ';
  final titles = {
    5: '$name好き',
    15: '親友は$name',
    30: '体が$nameで出来ている',
    50: '$nameと結婚した',
    100: '$nameの化身',
  };
  final descriptions = {
    5: '同じアイテムを5回購入した',
    15: '同じアイテムを15回購入した',
    30: '同じアイテムを30回購入した',
    50: '同じアイテムを50回購入した',
    100: '同じアイテムを100回購入した',
  };
  return Achievement(
    id: id,
    title: titles[threshold]!,
    description: descriptions[threshold]!,
    icon: Icons.favorite_rounded,
    color: const Color(0xFFE1546B),
    unlocked: unlocked,
  );
}
