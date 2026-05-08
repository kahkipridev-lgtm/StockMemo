import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/genre.dart';
import '../providers/inventory_provider.dart';

class AddItemDialog extends ConsumerStatefulWidget {
  final Genre? initialGenre;

  const AddItemDialog({super.key, this.initialGenre});

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _controller = TextEditingController();
  late Genre _selectedGenre;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.initialGenre ?? Genre.kitchen;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('アイテムを追加'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'アイテム名',
                border: OutlineInputBorder(),
                hintText: '例：醤油',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'アイテム名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('ジャンル', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButton<Genre>(
                value: _selectedGenre,
                isExpanded: true,
                underline: const SizedBox(),
                items: Genre.values
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Row(
                            children: [
                              Icon(g.icon, size: 20, color: g.color),
                              const SizedBox(width: 8),
                              Text(g.label),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedGenre = value);
                },
              ),
            ),
          ],
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
    ref
        .read(inventoryProvider.notifier)
        .addItem(_controller.text.trim(), _selectedGenre);
    Navigator.of(context).pop();
  }
}
