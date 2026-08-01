import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/genre.dart';
import '../models/inventory_filter.dart';
import '../models/stock_item.dart';
import '../providers/genre_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/add_genre_dialog.dart';
import '../widgets/genre_card.dart';
import '../widgets/item_card.dart';

class GenreSelectionScreen extends ConsumerStatefulWidget {
  const GenreSelectionScreen({super.key});

  @override
  ConsumerState<GenreSelectionScreen> createState() =>
      _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends ConsumerState<GenreSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final allGenres = ref.watch(allGenresProvider);
    final itemsAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンルを選択'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddGenreDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'アイテムを検索...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildGenreGrid(context, primaryColor, allGenres)
                : _buildSearchResults(context, itemsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid(
      BuildContext context, Color primaryColor, List<Genre> allGenres) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const edge = 12.0;
        const gap = 12.0;
        final itemWidth = (constraints.maxWidth - edge * 2 - gap) / 2;
        final itemHeight = itemWidth / 1.1;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: itemHeight,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/inventory',
                          arguments: const InventoryFilter(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.apps_rounded,
                                size: 32, color: primaryColor),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '全て表示',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final genre = allGenres[index];
                    final isBuiltIn =
                        Genre.builtIns.any((b) => b.id == genre.id);
                    return GenreCard(
                      genre: genre,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/inventory',
                          arguments: InventoryFilter(genre: genre),
                        );
                      },
                      onLongPress: isBuiltIn
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    AddGenreDialog(initialGenre: genre),
                              );
                            },
                    );
                  },
                  childCount: allGenres.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // カタカナをひらがなに変換して検索文字列を正規化する
  String _normalize(String text) {
    return text.toLowerCase().replaceAllMapped(
          RegExp(r'[ァ-ヶ]'),
          (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0x60),
        );
  }

  Widget _buildSearchResults(
      BuildContext context, AsyncValue<List<StockItem>> itemsAsync) {
    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (items) {
        final query = _normalize(_searchQuery);
        final filtered = items
            .where((item) =>
                _normalize(item.name).contains(query) ||
                (item.yomi != null && _normalize(item.yomi!).contains(query)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              '「$_searchQuery」に一致するアイテムはありません',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return ItemCard(
              key: Key(item.id),
              item: item,
              onDelete: () =>
                  ref.read(inventoryProvider.notifier).deleteItem(item.id),
            );
          },
        );
      },
    );
  }
}
