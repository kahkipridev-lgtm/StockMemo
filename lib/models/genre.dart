import 'package:flutter/material.dart';

class Genre {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const Genre({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const condiment = Genre(
    id: 'condiment',
    label: '調味料',
    icon: Icons.set_meal_rounded,
    color: Color(0xFFA1887F),
  );
  static const kitchen = Genre(
    id: 'kitchen',
    label: '台所',
    icon: Icons.kitchen_rounded,
    color: Color(0xFFE57373),
  );
  static const bath = Genre(
    id: 'bath',
    label: '風呂',
    icon: Icons.bathtub_rounded,
    color: Color(0xFF64B5F6),
  );
  static const toilet = Genre(
    id: 'toilet',
    label: 'トイレ',
    icon: Icons.wc_rounded,
    color: Color(0xFF81C784),
  );
  static const washroom = Genre(
    id: 'washroom',
    label: '洗面所',
    icon: Icons.face_retouching_natural_rounded,
    color: Color(0xFFFFB74D),
  );
  static const laundry = Genre(
    id: 'laundry',
    label: '洗濯',
    icon: Icons.local_laundry_service_rounded,
    color: Color(0xFF9575CD),
  );
  static const other = Genre(
    id: 'other',
    label: 'その他',
    icon: Icons.category_rounded,
    color: Color(0xFF4DB6AC),
  );

  static List<Genre> get builtIns =>
      [condiment, kitchen, bath, toilet, washroom, laundry, other];

  Map<String, dynamic> toFullJson() => {
        'id': id,
        'label': label,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
        'colorValue': color.toARGB32(),
      };

  static Genre fromFullJson(Map<String, dynamic> json) => Genre(
        id: json['id'] as String,
        label: json['label'] as String,
        icon: IconData(
          json['iconCodePoint'] as int,
          fontFamily: json['iconFontFamily'] as String,
        ),
        color: Color(json['colorValue'] as int),
      );

  static Genre fromId(String id, {List<Genre> custom = const []}) =>
      [...builtIns, ...custom]
          .firstWhere((g) => g.id == id, orElse: () => other);

  @override
  bool operator ==(Object other) => other is Genre && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
