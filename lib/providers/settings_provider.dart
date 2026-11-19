import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOrder { alphabetical, stockLevel, lastUpdated }

class AppSettings {
  final ThemeMode themeMode;
  final SortOrder defaultSortOrder;
  // true: 在庫あり／残りわずか／在庫切れの3段階、false: 在庫あり／在庫切れの2段階
  final bool useLowStockLevel;
  // true: 買い物リストのタブを離れたとき（アプリを閉じたときも）に、完了した項目を自動で削除する
  final bool autoClearShoppingList;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultSortOrder = SortOrder.alphabetical,
    this.useLowStockLevel = true,
    this.autoClearShoppingList = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    SortOrder? defaultSortOrder,
    bool? useLowStockLevel,
    bool? autoClearShoppingList,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
      useLowStockLevel: useLowStockLevel ?? this.useLowStockLevel,
      autoClearShoppingList:
          autoClearShoppingList ?? this.autoClearShoppingList,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'defaultSortOrder': defaultSortOrder.index,
        'useLowStockLevel': useLowStockLevel,
        'autoClearShoppingList': autoClearShoppingList,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        defaultSortOrder:
            SortOrder.values[json['defaultSortOrder'] as int? ?? 0],
        useLowStockLevel: json['useLowStockLevel'] as bool? ?? true,
        autoClearShoppingList:
            json['autoClearShoppingList'] as bool? ?? false,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _key = 'app_settings';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(themeMode: mode);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> updateDefaultSortOrder(SortOrder order) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(defaultSortOrder: order);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> updateUseLowStockLevel(bool value) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(useLowStockLevel: value);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> updateAutoClearShoppingList(bool value) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(autoClearShoppingList: value);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> _save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

// 「残りわずか」を使う3段階モードかどうか（設定読込前は3段階扱い）
final useLowStockLevelProvider = Provider<bool>((ref) =>
    ref.watch(settingsProvider).value?.useLowStockLevel ?? true);

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
