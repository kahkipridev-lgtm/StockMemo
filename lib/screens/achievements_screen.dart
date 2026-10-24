import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../providers/achievements_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(achievementCategoriesProvider);
    final all = categories.expand((c) => c.achievements).toList();
    final unlockedCount = all.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('実績'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            color: const Color(0xFFE1AF64).withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFE1AF64), size: 32),
                  const SizedBox(width: 12),
                  Text(
                    '$unlockedCount / ${all.length} 解除',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A5100)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                category.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemCount: category.achievements.length,
              itemBuilder: (context, index) =>
                  _AchievementCard(achievement: category.achievements[index]),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.unlocked;
    final color = achievement.color;
    final lockedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: locked
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: locked ? lockedColor.withValues(alpha: 0.3) : color,
          width: locked ? 1 : 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: locked ? lockedColor.withValues(alpha: 0.15) : color.withValues(alpha: 0.2),
            child: Icon(
              locked ? Icons.question_mark_rounded : achievement.icon,
              color: locked ? lockedColor : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            locked ? '？？？' : achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: locked ? lockedColor : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            locked ? '？？？' : achievement.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: locked
                  ? lockedColor.withValues(alpha: 0.8)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
