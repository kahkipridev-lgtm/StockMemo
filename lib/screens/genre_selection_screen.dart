import 'package:flutter/material.dart';

import '../models/genre.dart';
import '../widgets/genre_card.dart';
import 'inventory_screen.dart';

class GenreSelectionScreen extends StatelessWidget {
  const GenreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンルを選択'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: Genre.values.length,
          itemBuilder: (context, index) {
            final genre = Genre.values[index];
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
        ),
      ),
    );
  }
}
