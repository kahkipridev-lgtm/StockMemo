import 'package:flutter/material.dart';

enum Genre {
  kitchen,
  bath,
  toilet,
  washroom,
  laundry,
  other;

  String get label {
    switch (this) {
      case Genre.kitchen:
        return '台所';
      case Genre.bath:
        return '風呂';
      case Genre.toilet:
        return 'トイレ';
      case Genre.washroom:
        return '洗面所';
      case Genre.laundry:
        return '洗濯';
      case Genre.other:
        return 'その他';
    }
  }

  IconData get icon {
    switch (this) {
      case Genre.kitchen:
        return Icons.kitchen_rounded;
      case Genre.bath:
        return Icons.bathtub_rounded;
      case Genre.toilet:
        return Icons.wc_rounded;
      case Genre.washroom:
        return Icons.face_retouching_natural_rounded;
      case Genre.laundry:
        return Icons.local_laundry_service_rounded;
      case Genre.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case Genre.kitchen:
        return const Color(0xFFE57373);
      case Genre.bath:
        return const Color(0xFF64B5F6);
      case Genre.toilet:
        return const Color(0xFF81C784);
      case Genre.washroom:
        return const Color(0xFFFFB74D);
      case Genre.laundry:
        return const Color(0xFF9575CD);
      case Genre.other:
        return const Color(0xFF4DB6AC);
    }
  }

  String toJson() => name;

  static Genre fromJson(String value) {
    return Genre.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Genre.other,
    );
  }
}
