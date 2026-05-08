import 'package:flutter/material.dart';

import '../models/stock_level.dart';
import 'inventory_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'StockMemo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '在庫の確認・管理',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: Column(
                  children: [
                    _MenuButton(
                      icon: Icons.category_rounded,
                      label: '在庫を確認',
                      subtitle: 'ジャンルから在庫を確認する',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/genres'),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.warning_amber_rounded,
                      label: '残量少・残量なしを確認',
                      subtitle: '補充が必要なものを確認する',
                      color: const Color(0xFFFF9800),
                      onTap: () => Navigator.of(context).pushNamed(
                        '/inventory',
                        arguments: InventoryFilter(
                          levels: [StockLevel.low, StockLevel.empty],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.remove_circle_rounded,
                      label: '残量なしを確認',
                      subtitle: '今すぐ買うべきものを確認する',
                      color: const Color(0xFFF44336),
                      onTap: () => Navigator.of(context).pushNamed(
                        '/inventory',
                        arguments: InventoryFilter(
                          levels: [StockLevel.empty],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.settings_rounded,
                      label: '設定',
                      subtitle: 'テーマやデータの管理',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
