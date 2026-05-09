import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/genre.dart';
import '../models/inventory_filter.dart';
import '../providers/genre_provider.dart';
import '../widgets/add_genre_dialog.dart';
import '../widgets/genre_card.dart';

class GenreSelectionScreen extends ConsumerWidget {
  const GenreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final allGenres = ref.watch(allGenresProvider);

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
      body: LayoutBuilder(
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
      ),
    );
  }
}
