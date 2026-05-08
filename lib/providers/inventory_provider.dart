import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/default_items.dart';
import '../models/genre.dart';
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

  Future<List<StockItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;

    if (!initialized) {
      final defaults = buildDefaultItems();
      await _save(defaults);
      await prefs.setBool(_initializedKey, true);
      return defaults;
    }

    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<StockItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> updateStockLevel(String id, StockLevel level) async {
    final items = state.value ?? [];
    final updated = items
        .map((item) => item.id == id ? item.copyWith(stockLevel: level) : item)
        .toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> addItem(String name, Genre genre) async {
    final items = state.value ?? [];
    final newItem = StockItem(
      id: _uuid.v4(),
      name: name,
      genre: genre,
      stockLevel: StockLevel.full,
      isDefault: false,
    );
    final updated = [...items, newItem];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> deleteItem(String id) async {
    final items = state.value ?? [];
    final updated = items.where((item) => item.id != id).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> resetAllToFull() async {
    final items = state.value ?? [];
    final updated =
        items.map((item) => item.copyWith(stockLevel: StockLevel.full)).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> restoreDefaults() async {
    final items = state.value ?? [];
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
