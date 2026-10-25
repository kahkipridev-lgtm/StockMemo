import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievements_provider.dart';

// 実績ページで実際に見た（NEW表示・タブのバッジを消してよい）実績IDを記録する
class AchievementSeenNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'seen_achievement_ids';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null) return saved.toSet();

    // この機能より前からの解除分は、既読として静かに取り込む（アプリ更新後の既存データ対応）
    final alreadyUnlocked = ref
        .read(achievementCategoriesProvider)
        .expand((c) => c.achievements)
        .where((a) => a.unlocked)
        .map((a) => a.id)
        .toSet();
    await prefs.setStringList(_key, alreadyUnlocked.toList());
    return alreadyUnlocked;
  }

  // 実績ページを開いたタイミングで、現在解除済みのものをすべて既読にする
  Future<void> markAllSeen(Iterable<String> unlockedIds) async {
    final current = await future;
    final updated = {...current, ...unlockedIds};
    if (updated.length == current.length) return;
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
  }
}

final achievementSeenProvider =
    AsyncNotifierProvider<AchievementSeenNotifier, Set<String>>(
        AchievementSeenNotifier.new);

// 解除済みだが、まだ実績ページで見ていないものの数（ツールタブのバッジに使う）
final unseenAchievementCountProvider = Provider<int>((ref) {
  final unlockedIds = ref
      .watch(achievementCategoriesProvider)
      .expand((c) => c.achievements)
      .where((a) => a.unlocked)
      .map((a) => a.id);
  final seen = ref.watch(achievementSeenProvider).value ?? {};
  return unlockedIds.where((id) => !seen.contains(id)).length;
});
