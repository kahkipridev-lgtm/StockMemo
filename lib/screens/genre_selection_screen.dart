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
  static const _allGenreId = '__all__';

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isReordering = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final allGenres = ref.watch(allGenresProvider);
    final order = ref.watch(genreOrderProvider).value ?? [];
    final displayGenres = _withAllGenre(allGenres, primaryColor, order);
    final itemsAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンルを選択'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isReordering ? Icons.check_rounded : Icons.sort_rounded),
            tooltip: _isReordering ? '完了' : '並び替え',
            onPressed: () => setState(() => _isReordering = !_isReordering),
          ),
          if (!_isReordering)
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
          if (_isReordering)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                'カードをドラッグすると並び順を変更できます',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildGenreGrid(context, displayGenres)
                : _buildSearchResults(context, itemsAsync),
          ),
        ],
      ),
    );
  }

  List<Genre> _withAllGenre(
      List<Genre> genres, Color primaryColor, List<String> order) {
    final allGenre = Genre(
      id: _allGenreId,
      label: '全て表示',
      icon: Icons.apps_rounded,
      color: primaryColor,
    );
    final combined = [allGenre, ...genres];
    if (order.isEmpty) return combined;

    final byId = {for (final g in combined) g.id: g};
    final ordered = <Genre>[];
    for (final id in order) {
      final g = byId.remove(id);
      if (g != null) ordered.add(g);
    }
    // 並び順未設定（移動したことがない）の場合、全て表示は左上をデフォルト位置とする
    final leftoverAll = byId.remove(_allGenreId);
    if (leftoverAll != null) ordered.insert(0, leftoverAll);
    ordered.addAll(byId.values);
    return ordered;
  }

  Widget _buildGenreGrid(BuildContext context, List<Genre> genres) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const edge = 12.0;
        const gap = 12.0;
        final itemWidth = (constraints.maxWidth - edge * 2 - gap) / 2;
        final itemHeight = itemWidth / 1.1;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];

            if (_isReordering) {
              return _buildReorderableCard(
                  context, genres, index, itemWidth, itemHeight);
            }

            final isAll = genre.id == _allGenreId;
            return GenreCard(
              genre: genre,
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/inventory',
                  arguments: isAll
                      ? const InventoryFilter()
                      : InventoryFilter(genre: genre),
                );
              },
              onLongPress: () => setState(() => _isReordering = true),
            );
          },
        );
      },
    );
  }

  Widget _buildReorderableCard(BuildContext context, List<Genre> genres,
      int index, double width, double height) {
    final genre = genres[index];
    final isCustom = genre.id != _allGenreId &&
        !Genre.builtIns.any((b) => b.id == genre.id);

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => _reorder(genres, details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isTarget = candidateData.isNotEmpty;
        return AnimatedScale(
          scale: isTarget ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Draggable<int>(
            data: index,
            feedback: SizedBox(
              width: width,
              height: height,
              child: Opacity(
                opacity: 0.85,
                child: GenreCard(genre: genre, onTap: () {}),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: GenreCard(genre: genre, onTap: () {}),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GenreCard(genre: genre, onTap: () {}),
                if (isCustom)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddGenreDialog(initialGenre: genre),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit_rounded, size: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _reorder(List<Genre> genres, int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    final ids = genres.map((g) => g.id).toList();
    final id = ids.removeAt(fromIndex);
    ids.insert(toIndex, id);
    ref.read(genreOrderProvider.notifier).setOrder(ids);
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
