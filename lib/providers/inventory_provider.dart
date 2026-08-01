import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/default_items.dart';
import '../models/stock_item.dart';
import '../models/stock_level.dart';

class InventoryNotifier extends AsyncNotifier<List<StockItem>> {
  static const _key = 'inventory_items';
  static const _initializedKey = 'inventory_initialized';
  static const _uuid = Uuid();

  @override
  Future<List<StockItem>> build() async {
    return _load();
  }

  List<StockItem> get _items => state.value ?? [];

  Future<List<StockItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;

    if (!initialized) {
      final defaults = buildDefaultItems(installedAt: DateTime.now());
      await _save(defaults);
      await prefs.setBool(_initializedKey, true);
      return defaults;
    }

    final raw = prefs.getString(_key);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return _applyDefaultYomi(items);
    } catch (_) {
      return [];
    }
  }

  // yomiが未設定のアイテムにデフォルトの読みを付与する（アプリ更新後の既存データ対応）
  List<StockItem> _applyDefaultYomi(List<StockItem> items) {
    final yomiMap = {
      for (final d in buildDefaultItems())
        if (d.yomi != null) d.name: d.yomi!
    };
    final patched = items.map((item) {
      if (item.yomi == null && yomiMap.containsKey(item.name)) {
        return item.copyWith(yomi: yomiMap[item.name]);
      }
      return item;
    }).toList();

    // 変更があった場合は保存する
    final hasChanges = patched.any((item) =>
        item.yomi != null &&
        items.firstWhere((i) => i.id == item.id).yomi == null);
    if (hasChanges) {
      _save(patched);
    }
    return patched;
  }

  Future<void> _save(List<StockItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> updateStockLevel(String id, StockLevel level) async {
    final items = _items;
    final now = DateTime.now();
    final updated = items
        .map((item) => item.id == id
            ? item.copyWith(stockLevel: level, statusUpdatedAt: now)
            : item)
        .toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> addItem(String name, String genreId, {String? yomi}) async {
    final items = _items;
    final newItem = StockItem(
      id: _uuid.v4(),
      name: name,
      yomi: yomi?.isEmpty == true ? null : yomi,
      genreId: genreId,
      stockLevel: StockLevel.full,
      isDefault: false,
      statusUpdatedAt: DateTime.now(),
    );
    final updated = [...items, newItem];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> deleteItem(String id) async {
    final items = _items;
    final updated = items.where((item) => item.id != id).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> resetAllToFull() async {
    final items = _items;
    final now = DateTime.now();
    final updated = items
        .map((item) =>
            item.copyWith(stockLevel: StockLevel.full, statusUpdatedAt: now))
        .toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> restoreDefaults() async {
    final items = _items;
    final existingNames = items.map((e) => e.name).toSet();
    final defaults = buildDefaultItems()
        .where((d) => !existingNames.contains(d.name))
        .toList();
    final updated = [...items, ...defaults];
    state = AsyncData(updated);
    await _save(updated);
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<StockItem>>(
        InventoryNotifier.new);
