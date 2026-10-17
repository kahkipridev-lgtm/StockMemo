import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_level.dart';

class PriceCompareScreen extends StatefulWidget {
  const PriceCompareScreen({super.key});

  @override
  State<PriceCompareScreen> createState() => _PriceCompareScreenState();
}

class _PriceCompareScreenState extends State<PriceCompareScreen> {
  final _priceA = TextEditingController();
  final _amountA = TextEditingController();
  final _priceB = TextEditingController();
  final _amountB = TextEditingController();

  @override
  void dispose() {
    _priceA.dispose();
    _amountA.dispose();
    _priceB.dispose();
    _amountB.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _clear() {
    for (final c in [_priceA, _amountA, _priceB, _amountB]) {
      c.clear();
    }
    setState(() {});
  }

  String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final priceA = _parse(_priceA);
    final amountA = _parse(_amountA);
    final priceB = _parse(_priceB);
    final amountB = _parse(_amountB);

    final unitA = (priceA != null && amountA != null) ? priceA / amountA : null;
    final unitB = (priceB != null && amountB != null) ? priceB / amountB : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('容量・価格を比較'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'クリア',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clear,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ProductCard(
                    label: '商品A',
                    price: _priceA,
                    amount: _amountA,
                    unitPrice: unitA,
                    isCheaper: unitA != null && unitB != null && unitA < unitB,
                    fmt: _fmt,
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProductCard(
                    label: '商品B',
                    price: _priceB,
                    amount: _amountB,
                    unitPrice: unitB,
                    isCheaper: unitA != null && unitB != null && unitB < unitA,
                    fmt: _fmt,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String label;
  final TextEditingController price;
  final TextEditingController amount;
  final double? unitPrice;
  final bool isCheaper;
  final String Function(double) fmt;
  final VoidCallback onChanged;

  const _ProductCard({
    required this.label,
    required this.price,
    required this.amount,
    required this.unitPrice,
    required this.isCheaper,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const green = Color(0xFF2E7D32);
    const per = '1あたり';

    return Card(
      color: isCheaper ? StockLevel.full.backgroundColor : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCheaper ? green : colorScheme.outlineVariant,
          width: isCheaper ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(label, style: textTheme.titleMedium),
                if (isCheaper) ...[
                  const Spacer(),
                  const Icon(Icons.emoji_events_rounded, color: green, size: 20),
                  const Text('お得',
                      style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(
                labelText: '価格',
                suffixText: '円',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: '容量・数量',
                                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            Text(per, style: textTheme.bodySmall),
            Text(
              unitPrice == null ? '-' : '${fmt(unitPrice!)} 円',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCheaper ? green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
