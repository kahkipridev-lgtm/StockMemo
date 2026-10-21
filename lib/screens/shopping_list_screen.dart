import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock_level.dart';
import '../providers/inventory_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/item_card.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();
  final _scrollController = ScrollController();

  final _editController = TextEditingController();
  final _editFocusNode = FocusNode();
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _addFocusNode.addListener(() {
      if (_addFocusNode.hasFocus) {
        _scrollAddRowIntoView();
      } else {
        _submitAdd();
      }
    });
    _editFocusNode.addListener(() {
      if (!_editFocusNode.hasFocus) _commitEdit();
    });
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    _scrollController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _scrollAddRowIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _submitAdd({bool refocus = false}) {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    ref.read(shoppingListProvider.notifier).addItem(name);
    _addController.clear();
    if (refocus) _addFocusNode.requestFocus();
    _scrollAddRowIntoView();
  }

  void _startEdit(String id, String currentName) {
    setState(() => _editingId = id);
    _editController.text = currentName;
    _editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: currentName.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _commitEdit() {
    if (_editingId == null) return;
    final name = _editController.text.trim();
    if (name.isNotEmpty) {
      ref.read(shoppingListProvider.notifier).updateItemName(_editingId!, name);
    }
    setState(() => _editingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(shoppingListProvider);
    final emptyStockItems = (ref.watch(inventoryProvider).value ?? [])
        .where((item) => item.stockLevel == StockLevel.empty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 在庫切れアイテム
              if (emptyStockItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.remove_circle_outline_rounded,
                    label: '在庫切れ',
                    color: const Color(0xFFC0392B),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = emptyStockItems[index];
                      return ItemCard(
                        key: Key(item.id),
                        item: item,
                        onDelete: () => ref
                            .read(inventoryProvider.notifier)
                            .deleteItem(item.id),
                      );
                    },
                    childCount: emptyStockItems.length,
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(height: 24)),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.shopping_cart_outlined,
                    label: '買い物メモ',
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],

              // 既存アイテム一覧
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final isEditing = _editingId == item.id;

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => ref
                          .read(shoppingListProvider.notifier)
                          .deleteItem(item.id),
                      child: ListTile(
                        onTap: () {
                          // アイテムの余白をタップ → キーボードを閉じる
                          if (_editFocusNode.hasFocus) {
                            _commitEdit();
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        },
                        leading: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => ref
                              .read(shoppingListProvider.notifier)
                              .togglePurchased(item.id),
                          child: Icon(
                            item.isPurchased
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: item.isPurchased
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        title: isEditing
                            ? TextField(
                                controller: _editController,
                                focusNode: _editFocusNode,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _commitEdit(),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              )
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _startEdit(item.id, item.name),
                                child: Text(
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
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),

              // 新規入力行
              SliverToBoxAdapter(
                child: ListTile(
                  leading: Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  title: TextField(
                    controller: _addController,
                    focusNode: _addFocusNode,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () => _submitAdd(refocus: true),
                    decoration: const InputDecoration(
                      hintText: 'アイテムを追加...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),

              // 画面下の余白エリア：キーボード表示中のみ閉じる
              SliverFillRemaining(
                hasScrollBody: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_editFocusNode.hasFocus) {
                      _commitEdit();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
