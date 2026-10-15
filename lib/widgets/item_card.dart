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
          onLongPress: () => _showMemoDialog(context, ref),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              if (item.memo != null && item.memo!.isNotEmpty)
                Text(
                  item.memo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                ),
            ],
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

  void _showMemoDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _MemoEditDialog(item: item),
    );
  }
}

class _MemoEditDialog extends ConsumerStatefulWidget {
  final StockItem item;

  const _MemoEditDialog({required this.item});

  @override
  ConsumerState<_MemoEditDialog> createState() => _MemoEditDialogState();
}

class _MemoEditDialogState extends ConsumerState<_MemoEditDialog> {
  late final TextEditingController _controller;

  static const _maxLength = 30;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.memo ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.item.name}のメモ'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: _maxLength,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '例：賞味期限が近い',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    ref
        .read(inventoryProvider.notifier)
        .updateMemo(widget.item.id, _controller.text);
    Navigator.of(context).pop();
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
