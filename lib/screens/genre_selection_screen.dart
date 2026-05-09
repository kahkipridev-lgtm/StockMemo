import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/genre_provider.dart';
import '../widgets/add_genre_dialog.dart';
import '../widgets/genre_card.dart';
import 'inventory_screen.dart';

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
                      if (index == allGenres.length) {
                        return _AddGenreCard(primaryColor: primaryColor);
                      }
                      final genre = allGenres[index];
                      return GenreCard(
                        genre: genre,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/inventory',
                            arguments: InventoryFilter(genre: genre),
                          );
                        },
                      );
                    },
                    childCount: allGenres.length + 1,
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

class _AddGenreCard extends StatelessWidget {
  final Color primaryColor;

  const _AddGenreCard({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const AddGenreDialog(),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Icon(Icons.add_rounded, size: 32, color: primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                'ジャンルを追加',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
