import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class PriceTagSearchScreen extends StatefulWidget {
  const PriceTagSearchScreen({super.key});

  @override
  State<PriceTagSearchScreen> createState() => _PriceTagSearchScreenState();
}

class _PriceTagSearchScreenState extends State<PriceTagSearchScreen> {
  /// AmazonアソシエイトのトラッキングID。
  static const _amazonTrackingId = 'kahkipridev-22';

  static const _ocrChannel = MethodChannel('com.stockmemo.app/ocr');

  final _picker = ImagePicker();
  final _keyword = TextEditingController();

  File? _image;
  bool _busy = false;
  List<String> _lines = [];
  List<int> _prices = [];

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  static final _priceRe = RegExp(r'[¥￥]\s*([0-9][0-9,]*)|([0-9][0-9,]*)\s*円');

  Future<void> _pick(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 90);
    } catch (_) {
      _toast('カメラ/写真を開けませんでした。設定で許可を確認してください');
      return;
    }
    if (picked == null) return;

    setState(() {
      _image = File(picked!.path);
      _busy = true;
      _lines = [];
      _prices = [];
    });

    try {
      final raw = await _ocrChannel
          .invokeListMethod<String>('recognizeText', picked.path);
      final lines =
          (raw ?? []).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final prices = <int>{};
      for (final l in lines) {
        for (final m in _priceRe.allMatches(l)) {
          final v = int.tryParse((m.group(1) ?? m.group(2))!.replaceAll(',', ''));
          if (v != null && v > 0) prices.add(v);
        }
      }
      if (!mounted) return;
      setState(() {
        _lines = lines;
        _prices = prices.toList()..sort();
      });
      if (lines.isEmpty) _toast('文字を読み取れませんでした');
    } catch (_) {
      _toast('文字の読み取りに失敗しました');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addToKeyword(String text) {
    // 価格表記は検索語に混ぜない
    final cleaned = text.replaceAll(_priceRe, '').trim();
    if (cleaned.isEmpty) return;
    final cur = _keyword.text.trim();
    _keyword.text = cur.isEmpty ? cleaned : '$cur $cleaned';
    setState(() {});
  }

  Future<void> _search() async {
    final kw = _keyword.text.trim();
    if (kw.isEmpty) return;
    // s=2: 価格の安い順
    final uri = Uri.https('www.amazon.co.jp', '/s', {
      'k': kw,
      's': 'price-asc-rank', // 価格の安い順
      'tag': _amazonTrackingId,
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast('ブラウザを開けませんでした');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('値札で最安検索'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 100 + MediaQuery.of(context).padding.bottom),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('撮影する'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('写真から選ぶ'),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_image!, height: 180, fit: BoxFit.cover),
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_lines.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('読み取った文字（タップで検索語に追加）',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final l in _lines)
                  ActionChip(label: Text(l), onPressed: () => _addToKeyword(l)),
              ],
            ),
            if (_prices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '値札の価格: ${_prices.map((p) => '¥$p').join(' / ')}',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _keyword,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: '検索キーワード',
              border: const OutlineInputBorder(),
              suffixIcon: _keyword.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _keyword.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _keyword.text.trim().isEmpty ? null : _search,
            icon: const Icon(Icons.open_in_browser_rounded),
            label: const Text('Amazonで安い順に検索'),
          ),
          const SizedBox(height: 8),
          Text(
            'Amazonのアソシエイトとして、Stock Memoは適格販売により収入を得ています。',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}
