import 'package:flutter/material.dart';

import 'price_compare_screen.dart';

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
        ],
      ),
    );
  }
}
