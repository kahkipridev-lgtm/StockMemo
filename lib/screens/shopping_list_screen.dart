import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/shopping_item.dart';
import '../models/stock_item.dart';
import '../models/stock_level.dart';
import '../providers/inventory_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../utils/native_tab_bar.dart';
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
  final _addRowKey = GlobalKey();

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
      final ctx = _addRowKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
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

  // まだ買っていないもの（チェック済みのメモ・取消線付きの在庫切れは除く）から
  // 送るものを選んでもらい、LINEの共有画面（送り先を選ぶ画面）に渡す
  Future<void> _shareToLine({
    required List<ShoppingItem> memoItems,
    required List<StockItem> emptyItems,
    required List<StockItem> lowItems,
  }) async {
    final sections = <_ShareSection>[
      _ShareSection('買い物メモ', [
        for (final item in memoItems)
          if (!item.isPurchased) item.name,
      ]),
      _ShareSection('在庫切れ', [
        for (final item in emptyItems)
          if (!item.justRestocked) item.name,
      ]),
      _ShareSection('残りわずか', [for (final item in lowItems) item.name]),
    ].where((section) => section.names.isNotEmpty).toList();

    final messenger = ScaffoldMessenger.of(context);
    if (sections.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('共有できる項目がありません')));
      return;
    }

    final selected = await showModalBottomSheet<List<_ShareSection>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ShareSelectSheet(sections: sections),
    );
    if (selected == null) return;

    final text = buildShoppingListShareText(
      memoNames: _namesOf(selected, '買い物メモ'),
      emptyNames: _namesOf(selected, '在庫切れ'),
      lowNames: _namesOf(selected, '残りわずか'),
      now: DateTime.now(),
    );
    if (text == null) return;
    final uri = Uri.parse(
      'https://line.me/R/share?text=${Uri.encodeComponent(text)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('LINEを開けませんでした')));
    }
  }

  static List<String> _namesOf(List<_ShareSection> sections, String title) =>
      sections.where((s) => s.title == title).expand((s) => s.names).toList();

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(shoppingListProvider);
    final inventoryItems = ref.watch(inventoryProvider).value ?? [];
    final lowStockItems = inventoryItems
        .where((item) => item.stockLevel == StockLevel.low)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final emptyStockItems = inventoryItems
        .where((item) =>
            item.stockLevel == StockLevel.empty || item.justRestocked)
        .toList()
      // 「買ったばっかり」に戻した（取消線付きの）アイテムも下に移動させず、名前順のまま並べる
      ..sort((a, b) => a.name.compareTo(b.name));
    final hasRestocked = emptyStockItems.any((item) => item.justRestocked);

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
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'LINEで共有',
                onPressed: () => _shareToLine(
                  memoItems: items,
                  emptyItems: emptyStockItems,
                  lowItems: lowStockItems,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: '完了した項目をまとめて削除',
                onPressed: (hasRestocked || hasPurchased)
                    ? () {
                        if (hasRestocked) {
                          ref.read(inventoryProvider.notifier).clearRestocked();
                        }
                        if (hasPurchased) {
                          ref
                              .read(shoppingListProvider.notifier)
                              .clearPurchased();
                        }
                      }
                    : null,
              ),
            ],
          ),
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (emptyStockItems.isNotEmpty || lowStockItems.isNotEmpty) ...[
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
                  key: _addRowKey,
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

              // 在庫切れ・残りわずか（買い物メモの下に表示）
              if (emptyStockItems.isNotEmpty || lowStockItems.isNotEmpty)
                const SliverToBoxAdapter(child: Divider(height: 24)),

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
                        strikeThrough: item.justRestocked,
                        onDelete: () => ref
                            .read(inventoryProvider.notifier)
                            .deleteItem(item.id),
                      );
                    },
                    childCount: emptyStockItems.length,
                  ),
                ),
              ],

              // 残りわずかアイテム
              if (lowStockItems.isNotEmpty) ...[
                if (emptyStockItems.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.warning_amber_rounded,
                    label: '残りわずか',
                    color: const Color(0xFF9B6000),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = lowStockItems[index];
                      return ItemCard(
                        key: Key(item.id),
                        item: item,
                        onDelete: () => ref
                            .read(inventoryProvider.notifier)
                            .deleteItem(item.id),
                      );
                    },
                    childCount: lowStockItems.length,
                  ),
                ),
              ],

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

/// 共有の文章の最後に添える、受け取った人が嫌な気持ちにならないための一言（毎回ランダム）
const shareFriendlyMessages = [
  'よろしくお願いします🦘',
  'いつも助かってます！よろしくね🌷',
  '気をつけて行ってきてね。よろしくお願いします☺️',
  'いつもありがとう💐',
  'カンガルーが代わりに行けたらいいんですが...🦘',
  'この買い物リストはカンガルーが責任を持ってお届けしました📮🦘',
];

/// LINEなどに送る買い物リストの文章（送る項目が無ければ null）
String? buildShoppingListShareText({
  required List<String> memoNames,
  required List<String> emptyNames,
  required List<String> lowNames,
  required DateTime now,
  Random? random,
}) {
  if (memoNames.isEmpty && emptyNames.isEmpty && lowNames.isEmpty) {
    return null;
  }
  final buf = StringBuffer('🛒 買い物リスト（${now.month}/${now.day}）');
  void section(String title, List<String> names) {
    if (names.isEmpty) return;
    buf.write('\n\n【$title】');
    for (final name in names) {
      buf.write('\n・$name');
    }
  }

  section('買い物メモ', memoNames);
  section('在庫切れ', emptyNames);
  section('残りわずか', lowNames);
  final messages = shareFriendlyMessages;
  buf.write(
    '\n\n${messages[(random ?? Random()).nextInt(messages.length)]}',
  );
  return buf.toString();
}

class _ShareSection {
  final String title;
  final List<String> names;
  const _ShareSection(this.title, this.names);
}

/// LINEで共有する項目を選ぶシート（最初は全部選択済み）。
/// 「LINEで送る」で、選んだ項目だけを見出しごとに返す
class _ShareSelectSheet extends StatefulWidget {
  final List<_ShareSection> sections;

  const _ShareSelectSheet({required this.sections});

  @override
  State<_ShareSelectSheet> createState() => _ShareSelectSheetState();
}

class _ShareSelectSheetState extends State<_ShareSelectSheet> {
  // 「見出し/名前」のキーで選択状態を持つ（メモと在庫で同じ名前があっても区別する）
  late final Set<String> _checked = {
    for (final section in widget.sections)
      for (final name in section.names) _key(section, name),
  };

  static String _key(_ShareSection section, String name) =>
      '${section.title}/$name';

  int get _total =>
      widget.sections.fold(0, (sum, section) => sum + section.names.length);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allChecked = _checked.length == _total;

    // iOSのネイティブタブバーに隠れないよう、その高さ分の余白を空ける
    return Padding(
      padding: EdgeInsets.only(bottom: nativeTabBarInset),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 12, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '共有するアイテムを選択',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        if (allChecked) {
                          _checked.clear();
                        } else {
                          for (final section in widget.sections) {
                            for (final name in section.names) {
                              _checked.add(_key(section, name));
                            }
                          }
                        }
                      }),
                      child: Text(allChecked ? 'すべて解除' : 'すべて選択'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final section in widget.sections) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Text(
                          section.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      for (final name in section.names)
                        CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 15),
                          ),
                          value: _checked.contains(_key(section, name)),
                          onChanged: (value) => setState(() {
                            final key = _key(section, name);
                            if (value == true) {
                              _checked.add(key);
                            } else {
                              _checked.remove(key);
                            }
                          }),
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: Text('LINEで送る（${_checked.length}件）'),
                    // LINEのブランドカラー
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _checked.isEmpty
                        ? null
                        : () => Navigator.of(context).pop([
                            for (final section in widget.sections)
                              _ShareSection(section.title, [
                                for (final name in section.names)
                                  if (_checked.contains(_key(section, name)))
                                    name,
                              ]),
                          ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
