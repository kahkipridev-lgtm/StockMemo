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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MenuButton(
                      icon: Icons.category_rounded,
                      label: '在庫を確認',
                      subtitle: 'ジャンルから在庫を確認する',
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/genres'),
                      flex: 2,
                      labelFontSize: 20,
                      subtitleFontSize: 15,
                      iconSize: 32,
                      iconContainerSize: 60,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MenuButton(
                            icon: Icons.warning_amber_rounded,
                            label: '残量少を確認',
                            subtitle: '補充が必要なもの',
                            color: const Color(0xFFFF9800),
                            onTap: () => Navigator.of(context).pushNamed(
                              '/inventory',
                              arguments: InventoryFilter(
                                levels: [StockLevel.low],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _MenuButton(
                            icon: Icons.remove_circle_rounded,
                            label: '残量なしを確認',
                            subtitle: '今すぐ買うべきもの',
                            color: const Color(0xFFF44336),
                            onTap: () => Navigator.of(context).pushNamed(
                              '/inventory',
                              arguments: InventoryFilter(
                                levels: [StockLevel.empty],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.settings_rounded,
                      label: '設定',
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
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final int flex;
  final double labelFontSize;
  final double subtitleFontSize;
  final double iconSize;
  final double iconContainerSize;

  const _MenuButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.flex = 1,
    this.labelFontSize = 16,
    this.subtitleFontSize = 12,
    this.iconSize = 26,
    this.iconContainerSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
