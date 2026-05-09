import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/genre.dart';
import '../models/stock_item.dart';
import '../models/stock_level.dart';
import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/item_card.dart';
import '../widgets/sort_bar.dart';

class InventoryFilter {
  final Genre? genre;
  final List<StockLevel>? levels;

  const InventoryFilter({this.genre, this.levels});

  String get title {
    if (genre != null) return genre!.label;
    if (levels != null) {
      if (levels!.length == 1 && levels!.first == StockLevel.empty) {
        return '残量なし';
      }
      if (levels!.contains(StockLevel.low) &&
          levels!.contains(StockLevel.empty)) {
        return '残量少';
      }
    }
    return '全ての在庫';
  }
}

class InventoryScreen extends ConsumerStatefulWidget {
  final InventoryFilter? filter;

  const InventoryScreen({super.key, this.filter});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late SortOrder _sortOrder;
  bool _sortInitialized = false;

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter ??
        (ModalRoute.of(context)?.settings.arguments as InventoryFilter?) ??
        const InventoryFilter();
    final itemsAsync = ref.watch(inventoryProvider);
    final settingsAsync = ref.watch(settingsProvider);

    if (!_sortInitialized) {
      _sortOrder = settingsAsync.value?.defaultSortOrder ?? SortOrder.alphabetical;
      if (settingsAsync.hasValue) _sortInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(filter.title),
        centerTitle: true,
        actions: [
          if (filter.genre != null)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddDialog(context, filter.genre),
            ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (items) {
          final filtered = _filterItems(items, filter);
          final sorted = _sortItems(filtered, _sortOrder);

          return Column(
            children: [
              SortBar(
                currentSort: _sortOrder,
                onSortChanged: (order) => setState(() => _sortOrder = order),
              ),
              const Divider(height: 1),
              Expanded(
                child: sorted.isEmpty
                    ? _EmptyState(filter: filter)
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final item = sorted[index];
                          return ItemCard(
                            key: Key(item.id),
                            item: item,
                            onDelete: () => ref
                                .read(inventoryProvider.notifier)
                                .deleteItem(item.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddDialog(context, filter.genre),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<StockItem> _filterItems(List<StockItem> items, InventoryFilter filter) {
    return items.where((item) {
      if (filter.genre != null && item.genre != filter.genre) return false;
      if (filter.levels != null && !filter.levels!.contains(item.stockLevel)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<StockItem> _sortItems(List<StockItem> items, SortOrder order) {
    final sorted = List<StockItem>.from(items);
    if (order == SortOrder.alphabetical) {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    } else if (order == SortOrder.stockLevel) {
      sorted.sort((a, b) {
        final levelCmp =
            a.stockLevel.sortOrder.compareTo(b.stockLevel.sortOrder);
        if (levelCmp != 0) return levelCmp;
        return a.name.compareTo(b.name);
      });
    } else {
      sorted.sort((a, b) {
        if (a.statusUpdatedAt == null && b.statusUpdatedAt == null) {
          return a.name.compareTo(b.name);
        }
        if (a.statusUpdatedAt == null) return -1;
        if (b.statusUpdatedAt == null) return 1;
        return a.statusUpdatedAt!.compareTo(b.statusUpdatedAt!);
      });
    }
    return sorted;
  }

  void _showAddDialog(BuildContext context, Genre? genre) {
    showDialog(
      context: context,
      builder: (_) => AddItemDialog(initialGenre: genre),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final InventoryFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            filter.levels != null ? '該当する在庫はありません' : 'アイテムがありません',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
