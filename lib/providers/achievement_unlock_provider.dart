import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import 'achievements_provider.dart';

// どの実績がすでにバッジ通知済みかを記録し、新規解除分だけを教える
class AchievementUnlockNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'unlocked_achievement_ids';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null) return saved.toSet();

    // この機能より前からすでに解除条件を満たしていたものは、
    // バッジを出さずに「解除済み」として静かに取り込む（アプリ更新後の既存データ対応）
    final alreadyUnlocked = ref
        .read(achievementCategoriesProvider)
        .expand((c) => c.achievements)
        .where((a) => a.unlocked)
        .map((a) => a.id)
        .toSet();
    await prefs.setStringList(_key, alreadyUnlocked.toList());
    return alreadyUnlocked;
  }

  // 現在の実績一覧と見比べて、新しく解除されたものだけを返しつつ記録する
  Future<List<Achievement>> checkForNewUnlocks(
      List<Achievement> allAchievements) async {
    final known = await future;
    final newlyUnlocked =
        allAchievements.where((a) => a.unlocked && !known.contains(a.id)).toList();
    if (newlyUnlocked.isEmpty) return const [];

    final updated = {...known, ...newlyUnlocked.map((a) => a.id)};
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
    return newlyUnlocked;
  }
}

final achievementUnlockProvider =
    AsyncNotifierProvider<AchievementUnlockNotifier, Set<String>>(
        AchievementUnlockNotifier.new);
