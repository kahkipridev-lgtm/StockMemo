import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_filter.dart';
import '../models/stock_level.dart';
import '../providers/developer_messages_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/banner_ad_widget.dart';
import 'genre_selection_screen.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _nativeTabBarChannel = MethodChannel('com.stockmemo.app/native_tab_bar');

  // iOS 26のLiquid Glassタブバーを使うため、ネイティブ実装(RootFlutterViewController)側で
  // 下部タブを描画する。Flutter側のNavigationBarはiOS以外でのみ使う。
  final bool _useNativeTabBar = Platform.isIOS;

  int _currentIndex = 0;

  static const _tabColors = [
    Color(0xFF7A5100),
    Color(0xFFA86400),
    Color(0xFFC0392B),
    Color(0xFF2E7D32),
  ];

  @override
  void initState() {
    super.initState();
    if (_useNativeTabBar) {
      _nativeTabBarChannel.setMethodCallHandler(_handleNativeTabBarCall);
    }
  }

  @override
  void dispose() {
    if (_useNativeTabBar) {
      _nativeTabBarChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  Future<void> _handleNativeTabBarCall(MethodCall call) async {
    if (call.method != 'tabSelected') return;
    final index = (call.arguments as Map)['index'] as int;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicatorColor = _currentIndex < _tabColors.length
        ? _tabColors[_currentIndex]
        : colorScheme.secondary;

    final items = ref.watch(inventoryProvider).value ?? [];
    final lowCount =
        items.where((item) => item.stockLevel == StockLevel.low).length;
    final emptyCount =
        items.where((item) => item.stockLevel == StockLevel.empty).length;
    final hasUnreadMessage = ref.watch(hasUnreadDeveloperMessageProvider);

    if (_useNativeTabBar) {
      unawaited(
        _nativeTabBarChannel.invokeMethod('updateBadges', {
          'low': lowCount,
          'empty': emptyCount,
          'hasUnread': hasUnreadMessage,
        }),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const GenreSelectionScreen(),
                InventoryScreen(
                  key: const ValueKey('low'),
                  filter: const InventoryFilter(levels: [StockLevel.low]),
                  isActive: _currentIndex == 1,
                ),
                InventoryScreen(
                  key: const ValueKey('empty'),
                  filter: const InventoryFilter(levels: [StockLevel.empty]),
                  isActive: _currentIndex == 2,
                ),
                const ShoppingListScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
          const BannerAdWidget(),
          if (_useNativeTabBar)
            SizedBox(height: 49 + MediaQuery.of(context).padding.bottom),
        ],
      ),
      bottomNavigationBar: _useNativeTabBar ? null : NavigationBar(
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
            icon: Badge(
              label: Text('$lowCount'),
              isLabelVisible: lowCount > 0,
              child: const Icon(Icons.warning_amber_outlined, color: Color(0xFFA86400)),
            ),
            selectedIcon: Badge(
              label: Text('$lowCount'),
              isLabelVisible: lowCount > 0,
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFA86400)),
            ),
            label: '残りわずか',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$emptyCount'),
              isLabelVisible: emptyCount > 0,
              child: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFC0392B)),
            ),
            selectedIcon: Badge(
              label: Text('$emptyCount'),
              isLabelVisible: emptyCount > 0,
              child: const Icon(Icons.remove_circle_rounded, color: Color(0xFFC0392B)),
            ),
            label: '在庫切れ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF2E7D32)),
            selectedIcon:
                Icon(Icons.shopping_cart_rounded, color: Color(0xFF2E7D32)),
            label: '買い物リスト',
          ),
          NavigationDestination(
            icon: Badge(
              label: const Text('!'),
              isLabelVisible: hasUnreadMessage,
              child: Icon(Icons.settings_outlined, color: colorScheme.secondary),
            ),
            selectedIcon: Badge(
              label: const Text('!'),
              isLabelVisible: hasUnreadMessage,
              child: Icon(Icons.settings_rounded, color: colorScheme.secondary),
            ),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
