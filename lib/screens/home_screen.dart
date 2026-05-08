import 'package:flutter/material.dart';

import '../models/stock_level.dart';
import 'genre_selection_screen.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: '在庫を確認',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber_rounded),
            label: '残量少を確認',
          ),
          NavigationDestination(
            icon: Icon(Icons.remove_circle_outline_rounded),
            selectedIcon: Icon(Icons.remove_circle_rounded),
            label: '残量なしを確認',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
