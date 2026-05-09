import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/genre.dart';
import '../providers/genre_provider.dart';

class AddGenreDialog extends ConsumerStatefulWidget {
  const AddGenreDialog({super.key});

  @override
  ConsumerState<AddGenreDialog> createState() => _AddGenreDialogState();
}

class _AddGenreDialogState extends ConsumerState<AddGenreDialog> {
  static const _colors = [
    Color(0xFFEF5350),
    Color(0xFFFF7043),
    Color(0xFFFFA726),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    Color(0xFF26A69A),
    Color(0xFF26C6DA),
    Color(0xFF42A5F5),
    Color(0xFF7E57C2),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.kitchen_rounded,
    Icons.set_meal_rounded,
    Icons.bathtub_rounded,
    Icons.wc_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.local_laundry_service_rounded,
    Icons.category_rounded,
    Icons.local_grocery_store_rounded,
    Icons.cleaning_services_rounded,
    Icons.outdoor_grill_rounded,
    Icons.local_cafe_rounded,
    Icons.liquor_rounded,
    Icons.medication_rounded,
    Icons.medical_services_rounded,
    Icons.child_friendly_rounded,
    Icons.pets_rounded,
    Icons.spa_rounded,
    Icons.fitness_center_rounded,
    Icons.eco_rounded,
    Icons.bolt_rounded,
    Icons.build_rounded,
    Icons.favorite_rounded,
    Icons.school_rounded,
  ];

  static const _uuid = Uuid();

  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Color _selectedColor = _colors[7];
  IconData _selectedIcon = Icons.category_rounded;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ジャンルを追加'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GenrePreview(color: _selectedColor, icon: _selectedIcon),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'ジャンル名',
                    border: OutlineInputBorder(),
                    hintText: '例：薬・医療品',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ジャンル名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'カラー',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  width: 2.5,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'アイコン',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 168,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: _icons.length,
                    itemBuilder: (context, index) {
                      final icon = _icons[index];
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _selectedColor.withValues(alpha: 0.15)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: _selectedColor, width: 2)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            size: 22,
                            color: isSelected
                                ? _selectedColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('追加'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final genre = Genre(
      id: _uuid.v4(),
      label: _controller.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
    );
    ref.read(customGenreProvider.notifier).addGenre(genre);
    Navigator.of(context).pop();
  }
}

class _GenrePreview extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _GenrePreview({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 34, color: color),
      ),
    );
  }
}
