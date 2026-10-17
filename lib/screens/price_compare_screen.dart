import 'dart:math' as math;

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

    // 正なら商品Aが安い（左が上がる）、負なら商品Bが安い（右が上がる）
    var tilt = 0.0;
    if (unitA != null && unitB != null && unitA != unitB) {
      final cheap = unitA < unitB ? unitA : unitB;
      final expensive = unitA < unitB ? unitB : unitA;
      final ratio = (expensive - cheap) / expensive;
      final angle = (0.1 + ratio * 0.4).clamp(0.0, 0.3);
      tilt = unitA < unitB ? angle : -angle;
    }

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            _BalanceLayout(
              tilt: tilt,
              left: _ProductCard(
                label: '商品A',
                price: _priceA,
                amount: _amountA,
                unitPrice: unitA,
                isCheaper: unitA != null && unitB != null && unitA < unitB,
                fmt: _fmt,
                onChanged: () => setState(() {}),
              ),
              right: _ProductCard(
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

/// 天秤のように2枚のカードを吊るすレイアウト。tiltが正なら左が上がる。
class _BalanceLayout extends StatelessWidget {
  final double tilt;
  final Widget left;
  final Widget right;

  const _BalanceLayout({
    required this.tilt,
    required this.left,
    required this.right,
  });

  static const _gap = 12.0;
  static const _topHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = (width - _gap) / 2;
        // 支点から各カード中心までの水平距離
        final arm = width / 2 - cardWidth / 2;

        return TweenAnimationBuilder<double>(
          tween: Tween(end: tilt),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, t, _) {
            final lift = arm * math.sin(t);
            final base = arm * math.sin(t).abs();
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BalancePainter(
                      tilt: t,
                      arm: arm,
                      pivotY: 40,
                      stringLength: _topHeight - 40 + base,
                      color: color,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: _topHeight),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, base - lift),
                          child: left,
                        ),
                      ),
                      const SizedBox(width: _gap),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, base + lift),
                          child: right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BalancePainter extends CustomPainter {
  final double tilt;
  final double arm;
  final double pivotY;
  final double stringLength;
  final Color color;

  _BalancePainter({
    required this.tilt,
    required this.arm,
    required this.pivotY,
    required this.stringLength,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final dy = arm * math.sin(tilt);
    final dx = arm * math.cos(tilt);
    final leftEnd = Offset(cx - dx, pivotY - dy);
    final rightEnd = Offset(cx + dx, pivotY + dy);

    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final beam = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // 支柱と支点
    canvas.drawLine(Offset(cx, pivotY), Offset(cx, 4), line);
    canvas.drawCircle(Offset(cx, 4), 4, Paint()..color = color);

    // ひも（左右同じ長さで下のカードを吊る）
    canvas.drawLine(leftEnd, leftEnd + Offset(0, stringLength), line);
    canvas.drawLine(rightEnd, rightEnd + Offset(0, stringLength), line);

    // 横棒と支点の丸
    canvas.drawLine(leftEnd, rightEnd, beam);
    canvas.drawCircle(leftEnd, 4, Paint()..color = color);
    canvas.drawCircle(rightEnd, 4, Paint()..color = color);
    canvas.drawCircle(Offset(cx, pivotY), 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BalancePainter old) =>
      old.tilt != tilt || old.arm != arm || old.color != color;
}
