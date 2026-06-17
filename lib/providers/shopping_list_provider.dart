import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/shopping_item.dart';

class ShoppingListNotifier extends AsyncNotifier<List<ShoppingItem>> {
  static const _key = 'shopping_list_items';
  static const _uuid = Uuid();

  @override
  Future<List<ShoppingItem>> build() async => _load();

  List<ShoppingItem> get _items => state.value ?? [];

  Future<List<ShoppingItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return _sorted(
        list.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  List<ShoppingItem> _sorted(List<ShoppingItem> items) {
    final unpurchased = items.where((e) => !e.isPurchased).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final purchased = items.where((e) => e.isPurchased).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return [...unpurchased, ...purchased];
  }

  Future<void> addItem(String name) async {
    final newItem = ShoppingItem(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    final updated = _sorted([..._items, newItem]);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> togglePurchased(String id) async {
    final updated = _items
        .map((item) => item.id == id
            ? item.copyWith(isPurchased: !item.isPurchased)
            : item)
        .toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> deleteItem(String id) async {
    final updated = _items.where((item) => item.id != id).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> updateItemName(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final updated = _sorted(
      _items.map((item) => item.id == id ? item.copyWith(name: trimmed) : item).toList(),
    );
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> clearPurchased() async {
    final updated = _items.where((item) => !item.isPurchased).toList();
    state = AsyncData(updated);
    await _save(updated);
  }
}

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingItem>>(
        ShoppingListNotifier.new);
