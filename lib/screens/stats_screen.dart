import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/genre.dart';
import '../models/stock_level.dart';
import '../providers/inventory_provider.dart';
import '../providers/purchase_log_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final purchaseLog = ref.watch(purchaseLogProvider).value ?? [];
    final firstLaunch = ref.watch(firstLaunchAtProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('統計'), centerTitle: true),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラーが発生しました: $e')),
        data: (items) {
          final daysSinceStart = firstLaunch != null
              ? DateTime.now()
                      .difference(DateTime(
                          firstLaunch.year, firstLaunch.month, firstLaunch.day))
                      .inDays +
                  1
              : null;

          final purchaseDates =
              purchaseLog.map((e) => e.purchasedAt).toList();
          final weeklyPurchases = _weeklyCounts(purchaseDates);
          final monthlyPurchases = _monthlyCounts(purchaseDates);

          final emptyCount =
              items.where((i) => i.stockLevel == StockLevel.empty).length;
          final fullCount = items.length - emptyCount;

          final emptyDates = items
              .expand((i) => i.statusHistory)
              .where((h) => h.level == StockLevel.empty)
              .map((h) => h.timestamp)
              .toList();
          final monthlyEmpty = _monthlyCounts(emptyDates);

          final genreCounts = <String, int>{};
          for (final item in items) {
            genreCounts[item.genreId] = (genreCounts[item.genreId] ?? 0) + 1;
          }
          final genreLabelCounts = {
            for (final entry in genreCounts.entries)
              Genre.fromId(entry.key).label: entry.value,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: '利用開始から',
                      value: daysSinceStart != null ? '$daysSinceStart日' : '-',
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: '累計購入数',
                      value: '${purchaseLog.length}個',
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: '購入数の推移（週ごと）',
                icon: Icons.bar_chart_rounded,
                child: _VerticalBarChart(
                  data: weeklyPurchases,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '購入数の推移（月ごと）',
                icon: Icons.calendar_view_month_rounded,
                child: _VerticalBarChart(
                  data: monthlyPurchases,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '今の在庫状況',
                icon: Icons.inventory_2_rounded,
                child: Row(
                  children: [
                    Expanded(
                      child: _RatioTile(
                        label: '在庫あり',
                        count: fullCount,
                        total: items.length,
                        color: const Color(0xFF357A45),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RatioTile(
                        label: '在庫切れ',
                        count: emptyCount,
                        total: items.length,
                        color: const Color(0xFFC0392B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '在庫切れの発生回数（月ごと）',
                icon: Icons.remove_shopping_cart_rounded,
                child: _VerticalBarChart(
                  data: monthlyEmpty,
                  color: const Color(0xFFC0392B),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'ジャンル別アイテム数',
                icon: Icons.category_rounded,
                child: _HorizontalBarList(
                  data: genreLabelCounts,
                  color: const Color(0xFF7A5100),
                  labelWidth: 72,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 直近[weeks]週分の件数を、週の始まり(月曜)が古い順に集計する
Map<String, int> _weeklyCounts(List<DateTime> dates, {int weeks = 8}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final mondayThisWeek = today.subtract(Duration(days: today.weekday - 1));

  final buckets = <DateTime, int>{};
  for (var i = weeks - 1; i >= 0; i--) {
    buckets[mondayThisWeek.subtract(Duration(days: 7 * i))] = 0;
  }

  for (final d in dates) {
    final day = DateTime(d.year, d.month, d.day);
    final weekStart = day.subtract(Duration(days: day.weekday - 1));
    if (buckets.containsKey(weekStart)) {
      buckets[weekStart] = buckets[weekStart]! + 1;
    }
  }

  return buckets.map((k, v) => MapEntry('${k.month}/${k.day}', v));
}

// 直近[months]ヶ月分の件数を、古い月から順に集計する
Map<String, int> _monthlyCounts(List<DateTime> dates, {int months = 6}) {
  final now = DateTime.now();
  final buckets = <DateTime, int>{};
  for (var i = months - 1; i >= 0; i--) {
    buckets[DateTime(now.year, now.month - i, 1)] = 0;
  }

  for (final d in dates) {
    final monthStart = DateTime(d.year, d.month, 1);
    if (buckets.containsKey(monthStart)) {
      buckets[monthStart] = buckets[monthStart]! + 1;
    }
  }

  return buckets.map((k, v) => MapEntry('${k.month}月', v));
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _RatioTile extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _RatioTile({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (count / total * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '$count件',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            '$percent%',
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _VerticalBarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;
  static const double height = 150;

  const _VerticalBarChart({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'まだデータがありません',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    final maxValue =
        data.values.fold<int>(0, (max, v) => v > max ? v : max);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    entry.value > 0 ? '${entry.value}' : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio == 0 ? 0.02 : ratio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: entry.value == 0
                                ? color.withValues(alpha: 0.15)
                                : color,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HorizontalBarList extends StatelessWidget {
  final Map<String, int> data;
  final Color color;
  final double labelWidth;

  const _HorizontalBarList({
    required this.data,
    required this.color,
    this.labelWidth = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'まだデータがありません',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    final maxValue =
        data.values.fold<int>(0, (max, v) => v > max ? v : max);

    return Column(
      children: data.entries.map((entry) {
        final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 16, color: color.withValues(alpha: 0.12)),
                          Container(
                            height: 16,
                            width: constraints.maxWidth * ratio,
                            color: color,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.value}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
