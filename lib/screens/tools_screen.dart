import 'package:flutter/material.dart';

import 'price_compare_screen.dart';
import 'price_tag_search_screen.dart';
import 'stats_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ツール'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.balance_rounded, color: colorScheme.primary),
              title: const Text('容量・価格を比較'),
              subtitle: const Text('2つの商品のどちらがお得か計算します'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PriceCompareScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.document_scanner_rounded,
                  color: colorScheme.primary),
              title: const Text('値札で最安検索'),
              subtitle: const Text('値札を撮影して、Amazonで安い商品を探します'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PriceTagSearchScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.insights_rounded, color: colorScheme.primary),
              title: const Text('統計'),
              subtitle: const Text('利用日数や購入・在庫切れの推移を確認します'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
