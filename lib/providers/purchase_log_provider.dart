import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/purchase_log_entry.dart';

// 買い物リストで「購入済み」にした履歴を、アイテム削除後も残しておくための記録
// (統計ページの購入数推移の集計に使う)
class PurchaseLogNotifier extends AsyncNotifier<List<PurchaseLogEntry>> {
  static const _key = 'purchase_log';
  static const _uuid = Uuid();
  // 際限なく増え続けないよう、古いものから捨てる上限
  static const _maxEntries = 2000;

  @override
  Future<List<PurchaseLogEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PurchaseLogEntry.fromJson(e as Map<String, dynamic>))
          .whereType<PurchaseLogEntry>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<PurchaseLogEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> logPurchase(String name) async {
    final current = state.value ?? [];
    var updated = [
      ...current,
      PurchaseLogEntry(id: _uuid.v4(), name: name, purchasedAt: DateTime.now()),
    ];
    if (updated.length > _maxEntries) {
      updated = updated.sublist(updated.length - _maxEntries);
    }
    state = AsyncData(updated);
    await _save(updated);
  }
}

final purchaseLogProvider =
    AsyncNotifierProvider<PurchaseLogNotifier, List<PurchaseLogEntry>>(
        PurchaseLogNotifier.new);
