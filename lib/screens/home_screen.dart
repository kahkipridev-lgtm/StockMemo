import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../models/stock_level.dart';
import '../providers/achievement_seen_provider.dart';
import '../providers/achievement_unlock_provider.dart';
import '../providers/achievements_provider.dart';
import '../providers/developer_messages_provider.dart';
import '../providers/forecast_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../utils/native_tab_bar.dart';
import '../widgets/achievement_badge_toast.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/kangaroo_icon.dart';
import 'forecast_screen.dart';
import 'genre_selection_screen.dart';
import 'settings_screen.dart';
import 'shopping_list_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _nativeTabBarChannel = MethodChannel('com.stockmemo.app/native_tab_bar');

  // iOS 26のLiquid Glassタブバーを使うため、ネイティブ実装(RootFlutterViewController)側で
  // 下部タブを描画する。Flutter側のNavigationBarはiOS以外でのみ使う。
  final bool _useNativeTabBar = Platform.isIOS;

  int _currentIndex = 0;

  // タブの順番: 在庫を確認 / 買い物リスト / 在庫予測 / ツール / 設定
  // （iOSのネイティブタブバー RootFlutterViewController.swift の tabs と同期させること）
  static const _shoppingListTabIndex = 1;
  static const _forecastTabIndex = 2;
  static const _kangarooColor = Color(0xFFA0522D);

  static const _tabColors = [
    Color(0xFF7A5100),
    Color(0xFF2E7D32),
    _kangarooColor,
    Color(0xFF1565C0),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_useNativeTabBar) {
      _nativeTabBarChannel.setMethodCallHandler(_handleNativeTabBarCall);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_useNativeTabBar) {
      _nativeTabBarChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  Future<void> _handleNativeTabBarCall(MethodCall call) async {
    if (call.method != 'tabSelected') return;
    final index = (call.arguments as Map)['index'] as int;
    // ジャンル選択などでプッシュされた画面がホーム画面の上に残っていると
    // タブ切替後もその画面が表示されたままになるため、ホームまで戻す
    Navigator.of(context).popUntil((route) => route.isFirst);
    _selectTab(index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 買い物リストを開いたままアプリを閉じた（バックグラウンドに回した）ときも「離れた」とみなす
    if (state == AppLifecycleState.paused &&
        _currentIndex == _shoppingListTabIndex) {
      _autoClearShoppingList();
    }
  }

  // 設定がオンなら、買い物リストの完了した項目（チェック済みのメモ・取消線付きの在庫切れ）を削除する
  // （買い物リスト画面右上の「完了した項目をまとめて削除」と同じ処理）
  void _autoClearShoppingList() {
    final enabled =
        ref.read(settingsProvider).value?.autoClearShoppingList ?? false;
    if (!enabled) return;
    final items = ref.read(inventoryProvider).value ?? const [];
    if (items.any((item) => item.justRestocked)) {
      ref.read(inventoryProvider.notifier).clearRestocked();
    }
    final shopping = ref.read(shoppingListProvider).value ?? const [];
    if (shopping.any((item) => item.isPurchased)) {
      ref.read(shoppingListProvider.notifier).clearPurchased();
    }
  }

  void _selectTab(int index) {
    if (_currentIndex == _shoppingListTabIndex &&
        index != _shoppingListTabIndex) {
      _autoClearShoppingList();
    }
    // 在庫予測タブを開いたときは「今日」を基準に予測し直す
    if (index == _forecastTabIndex) {
      ref.read(forecastClockProvider.notifier).refresh();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<AchievementCategory>>(achievementCategoriesProvider,
        (previous, next) {
      final achievements = next.expand((c) => c.achievements).toList();
      ref
          .read(achievementUnlockProvider.notifier)
          .checkForNewUnlocks(achievements)
          .then((newlyUnlocked) {
        if (!mounted) return;
        for (final achievement in newlyUnlocked) {
          // ignore: use_build_context_synchronously
          showAchievementBadge(context, achievement);
        }
      });
    });

    final colorScheme = Theme.of(context).colorScheme;
    final indicatorColor = _currentIndex < _tabColors.length
        ? _tabColors[_currentIndex]
        : colorScheme.secondary;

    final items = ref.watch(inventoryProvider).value ?? [];
    final emptyCount =
        items.where((item) => item.stockLevel == StockLevel.empty).length;
    final hasUnreadMessage = ref.watch(hasUnreadDeveloperMessageProvider);
    final newAchievementCount = ref.watch(unseenAchievementCountProvider);
    final forecastSoonCount = ref.watch(forecastSoonCountProvider);

    if (_useNativeTabBar) {
      unawaited(
        _nativeTabBarChannel.invokeMethod('updateBadges', {
          'empty': emptyCount,
          'forecastSoon': forecastSoonCount,
          'hasUnread': hasUnreadMessage,
          'newAchievements': newAchievementCount,
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
                const ShoppingListScreen(),
                const ForecastScreen(),
                const ToolsScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
          const BannerAdWidget(),
          if (_useNativeTabBar)
            SizedBox(
              height: nativeTabBarHeight + MediaQuery.of(context).padding.bottom,
            ),
        ],
      ),
      bottomNavigationBar: _useNativeTabBar ? null : NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: indicatorColor.withValues(alpha: 0.2),
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.category_outlined, color: Color(0xFF7A5100)),
            selectedIcon: const Icon(Icons.category_rounded, color: Color(0xFF7A5100)),
            label: '在庫を確認',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$emptyCount'),
              isLabelVisible: emptyCount > 0,
              child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2E7D32)),
            ),
            selectedIcon: Badge(
              label: Text('$emptyCount'),
              isLabelVisible: emptyCount > 0,
              child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF2E7D32)),
            ),
            label: '買い物リスト',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$forecastSoonCount'),
              isLabelVisible: forecastSoonCount > 0,
              child: const KangarooIcon(color: _kangarooColor, outlined: true),
            ),
            selectedIcon: Badge(
              label: Text('$forecastSoonCount'),
              isLabelVisible: forecastSoonCount > 0,
              child: const KangarooIcon(color: _kangarooColor),
            ),
            label: '在庫予測',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$newAchievementCount'),
              isLabelVisible: newAchievementCount > 0,
              child: const Icon(Icons.handyman_outlined, color: Color(0xFF1565C0)),
            ),
            selectedIcon: Badge(
              label: Text('$newAchievementCount'),
              isLabelVisible: newAchievementCount > 0,
              child: const Icon(Icons.handyman_rounded, color: Color(0xFF1565C0)),
            ),
            label: 'ツール',
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
