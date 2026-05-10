import 'package:flutter/material.dart';

import '../models/inventory_filter.dart';
import '../models/stock_level.dart';
import 'genre_selection_screen.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabColors = [
    Color(0xFF7A5100),
    Color(0xFFA86400),
    Color(0xFFC0392B),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicatorColor = _currentIndex < _tabColors.length
        ? _tabColors[_currentIndex]
        : colorScheme.secondary;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          GenreSelectionScreen(),
          InventoryScreen(
            key: ValueKey('low'),
            filter: InventoryFilter(levels: [StockLevel.low, StockLevel.empty]),
          ),
          InventoryScreen(
            key: ValueKey('empty'),
            filter: InventoryFilter(levels: [StockLevel.empty]),
          ),
          ShoppingListScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: indicatorColor.withValues(alpha: 0.2),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.category_outlined, color: Color(0xFF7A5100)),
            selectedIcon: const Icon(Icons.category_rounded, color: Color(0xFF7A5100)),
            label: '在庫を確認',
          ),
          NavigationDestination(
            icon: const Icon(Icons.warning_amber_outlined, color: Color(0xFFA86400)),
            selectedIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFA86400)),
            label: '残量少を確認',
          ),
          NavigationDestination(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFC0392B)),
            selectedIcon: const Icon(Icons.remove_circle_rounded, color: Color(0xFFC0392B)),
            label: '残量なしを確認',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF2E7D32)),
            selectedIcon:
                Icon(Icons.shopping_cart_rounded, color: Color(0xFF2E7D32)),
            label: '買い物リスト',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: colorScheme.secondary),
            selectedIcon: Icon(Icons.settings_rounded, color: colorScheme.secondary),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
