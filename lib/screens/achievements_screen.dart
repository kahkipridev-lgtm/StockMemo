import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../providers/achievement_seen_provider.dart';
import '../providers/achievements_provider.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  // この画面を開いた時点でまだ未読だった実績ID（NEW表示用に、既読化の後もこの画面内では覚えておく）
  Set<String>? _newIds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndMarkSeen());
  }

  Future<void> _captureAndMarkSeen() async {
    final unlockedIds = ref
        .read(achievementCategoriesProvider)
        .expand((c) => c.achievements)
        .where((a) => a.unlocked)
        .map((a) => a.id)
        .toSet();
    final seen = await ref.read(achievementSeenProvider.future);
    final newIds = unlockedIds.difference(seen);
    if (!mounted) return;
    setState(() => _newIds = newIds);
    if (newIds.isNotEmpty) {
      await ref.read(achievementSeenProvider.notifier).markAllSeen(unlockedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(achievementCategoriesProvider);
    final all = categories.expand((c) => c.achievements).toList();
    final unlockedCount = all.where((a) => a.unlocked).length;
    final newIds = _newIds ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('実績'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Builder(builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Card(
              clipBehavior: Clip.antiAlias,
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: colorScheme.onPrimaryContainer, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      '$unlockedCount / ${all.length} 解除',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            );
          }),
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
              itemBuilder: (context, index) {
                final achievement = category.achievements[index];
                return _AchievementCard(
                  achievement: achievement,
                  isNew: newIds.contains(achievement.id),
                );
              },
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
  final bool isNew;

  const _AchievementCard({required this.achievement, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.unlocked;
    final color = achievement.color;
    final lockedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: locked
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: locked ? lockedColor.withValues(alpha: 0.3) : color,
              width: locked ? 1 : (isNew ? 2.5 : 2),
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
        ),
        if (!locked && isNew)
          Positioned(
            top: -8,
            right: -6,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1546B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
