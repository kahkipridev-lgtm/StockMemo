import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOrder { alphabetical, stockLevel }

class AppSettings {
  final ThemeMode themeMode;
  final SortOrder defaultSortOrder;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultSortOrder = SortOrder.alphabetical,
  });

  AppSettings copyWith({ThemeMode? themeMode, SortOrder? defaultSortOrder}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'defaultSortOrder': defaultSortOrder.index,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        defaultSortOrder:
            SortOrder.values[json['defaultSortOrder'] as int? ?? 0],
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

  Future<void> _save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
