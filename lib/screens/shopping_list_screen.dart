import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shopping_list_provider.dart';
import '../widgets/add_shopping_item_dialog.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(shoppingListProvider);

    return asyncItems.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $e')),
      ),
      data: (items) {
        final hasPurchased = items.any((e) => e.isPurchased);
        return Scaffold(
          appBar: AppBar(
            title: const Text('買い物リスト'),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_remove_rounded),
                tooltip: '購入済みを削除',
                onPressed: hasPurchased
                    ? () => ref
                        .read(shoppingListProvider.notifier)
                        .clearPurchased()
                    : null,
              ),
            ],
          ),
          body: items.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) => ref
                          .read(shoppingListProvider.notifier)
                          .deleteItem(item.id),
                      child: ListTile(
                        onTap: () => ref
                            .read(shoppingListProvider.notifier)
                            .togglePurchased(item.id),
                        leading: Icon(
                          item.isPurchased
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: item.isPurchased
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.isPurchased
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isPurchased
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: null,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddShoppingItemDialog(),
            ),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '買い物リストは空です',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
