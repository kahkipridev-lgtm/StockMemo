import 'package:flutter/material.dart';

/// 在庫予測タブのカンガルーアイコン（Material Icons / SF Symbols にカンガルーが無いため自作）
///
/// iOSのネイティブタブバー用アセット
/// (ios/Runner/Assets.xcassets/Kangaroo*.imageset) と同じパスデータを使っている。
/// [outlined] が true のときは線画（タブ非選択時）、false のときは塗り。
/// [baby] が true のときは子供のカンガルー（在庫予測のデータがまだ溜まっていないとき用）。
class KangarooIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool outlined;
  final bool baby;

  const KangarooIcon({
    super.key,
    this.size = 24,
    this.color,
    this.outlined = false,
    this.baby = false,
  });

  // viewBox 0 0 100 100、絶対座標の M / L / Q / Z のみで書いている
  static const pathData =
      'M92 26 Q89 30 83 30 Q77 30 74 32 Q70 36 70 42 Q70 46 73 48 L82 52 '
      'Q87 55 83 58 L72 55 Q69 58 70 63 Q77 69 75 77 Q74 82 70 86 L86 89 '
      'Q93 91 88 95 L55 95 Q50 95 47 92 Q35 96 20 97 Q8 98 3 96 Q2 93 10 91 '
      'Q24 87 32 82 Q36 79 38 75 Q31 64 35 52 Q40 39 53 31 Q57 28 59 24 '
      'Q55 14 54 3 Q61 8 64 14 Q66 7 68 2 Q72 9 72 16 Q78 17 84 20 '
      'Q90 22 92 26 Z';

  // 子供のカンガルー（頭と目を大きく、体を丸く）。後半の M〜Z は目（くり抜き）
  static const babyPathData =
      'M93 39 Q93 44 86 45 Q78 46 73 49 Q70 53 72 57 L80 60 Q84 63 80 65 '
      'L71 63 Q69 71 72 77 Q74 83 69 87 L86 90 Q92 92 87 95 L52 95 '
      'Q46 95 44 92 Q30 96 14 97 Q5 97 4 95 Q5 92 14 90 Q26 87 33 81 '
      'Q27 70 31 61 Q36 50 47 45 Q51 43 52 39 Q48 33 50 26 Q42 20 40 9 '
      'Q50 12 55 20 Q55 12 53 5 Q63 11 64 20 Q74 21 81 28 Q93 33 93 39 Z '
      'M71 30 Q71 27 74 27 Q77 27 77 30 Q77 33 74 33 Q71 33 71 30 Z';

  static final Path _path = _parse(pathData);
  static final Path _babyPath = _parse(babyPathData)
    ..fillType = PathFillType.evenOdd;

  static Path _parse(String d) {
    final tokens = RegExp(
      r'[MLQZ]|-?\d+(?:\.\d+)?',
    ).allMatches(d).map((m) => m.group(0)!).toList();
    final path = Path();
    var i = 0;
    double next() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      switch (tokens[i++]) {
        case 'M':
          path.moveTo(next(), next());
        case 'L':
          path.lineTo(next(), next());
        case 'Q':
          path.quadraticBezierTo(next(), next(), next(), next());
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _KangarooPainter(
          color: iconColor,
          outlined: outlined,
          baby: baby,
        ),
      ),
    );
  }
}

class _KangarooPainter extends CustomPainter {
  final Color color;
  final bool outlined;
  final bool baby;

  _KangarooPainter({
    required this.color,
    required this.outlined,
    required this.baby,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 線の太さぶん余白を取って 108x108 の枠に収める（iOSアセットの viewBox と同じ）
    final scale = size.shortestSide / 108;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(4, 4);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (outlined) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
    }
    canvas.drawPath(baby ? KangarooIcon._babyPath : KangarooIcon._path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KangarooPainter old) =>
      old.color != color || old.outlined != outlined || old.baby != baby;
}
