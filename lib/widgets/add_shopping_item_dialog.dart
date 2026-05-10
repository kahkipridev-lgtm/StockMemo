import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shopping_list_provider.dart';

class AddShoppingItemDialog extends ConsumerStatefulWidget {
  const AddShoppingItemDialog({super.key});

  @override
  ConsumerState<AddShoppingItemDialog> createState() =>
      _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState
    extends ConsumerState<AddShoppingItemDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'アイテム名',
            border: OutlineInputBorder(),
            hintText: '例：牛乳',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'アイテム名を入力してください';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
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
    ref.read(shoppingListProvider.notifier).addItem(_controller.text.trim());
    Navigator.of(context).pop();
  }
}
