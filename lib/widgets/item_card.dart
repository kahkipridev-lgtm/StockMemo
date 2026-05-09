import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock_item.dart';
import '../providers/inventory_provider.dart';

class ItemCard extends ConsumerWidget {
  final StockItem item;
  final VoidCallback onDelete;

  const ItemCard({super.key, required this.item, required this.onDelete});

  String? _updatedAtLabel(DateTime? updatedAt) {
    if (updatedAt == null) return null;
    final days = DateTime.now().difference(updatedAt).inDays;
    return days == 0 ? '今日更新' : '$days日前に更新';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _updatedAtLabel(item.statusUpdatedAt);
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('削除確認'),
            content: Text('「${item.name}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          subtitle: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                )
              : null,
          trailing: _StockLevelChip(item: item),
        ),
      ),
    );
  }
}

class _StockLevelChip extends ConsumerWidget {
  final StockItem item;

  const _StockLevelChip({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = item.stockLevel;

    return GestureDetector(
      onTap: () {
        ref
            .read(inventoryProvider.notifier)
            .updateStockLevel(item.id, level.next);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: level.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: level.color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 16, color: level.color),
            const SizedBox(width: 4),
            Text(
              level.label,
              style: TextStyle(
                color: level.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
