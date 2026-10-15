import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/genre.dart';

class CustomGenreNotifier extends AsyncNotifier<List<Genre>> {
  static const _key = 'custom_genres';

  @override
  Future<List<Genre>> build() async => _load();

  Future<List<Genre>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Genre.fromFullJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<Genre> genres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(genres.map((g) => g.toFullJson()).toList()),
    );
  }

  Future<void> addGenre(Genre genre) async {
    final current = state.value ?? [];
    final updated = [...current, genre];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> updateGenre(Genre genre) async {
    final current = state.value ?? [];
    final updated = current.map((g) => g.id == genre.id ? genre : g).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> deleteGenre(String id) async {
    final current = state.value ?? [];
    final updated = current.where((g) => g.id != id).toList();
    state = AsyncData(updated);
    await _save(updated);
  }
}

final customGenreProvider =
    AsyncNotifierProvider<CustomGenreNotifier, List<Genre>>(
        CustomGenreNotifier.new);

class GenreOrderNotifier extends AsyncNotifier<List<String>> {
  static const _key = 'genre_order';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> setOrder(List<String> order) async {
    state = AsyncData(order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, order);
  }
}

final genreOrderProvider =
    AsyncNotifierProvider<GenreOrderNotifier, List<String>>(
        GenreOrderNotifier.new);

final allGenresProvider = Provider<List<Genre>>((ref) {
  final custom = ref.watch(customGenreProvider).value ?? [];
  final all = [...Genre.builtIns, ...custom];
  final order = ref.watch(genreOrderProvider).value ?? [];
  if (order.isEmpty) return all;

  final byId = {for (final g in all) g.id: g};
  final ordered = <Genre>[];
  for (final id in order) {
    final g = byId.remove(id);
    if (g != null) ordered.add(g);
  }
  ordered.addAll(byId.values);
  return ordered;
});
