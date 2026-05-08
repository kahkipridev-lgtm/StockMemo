import 'package:flutter/material.dart';

enum StockLevel {
  full,
  low,
  empty;

  StockLevel get next {
    switch (this) {
      case StockLevel.full:
        return StockLevel.low;
      case StockLevel.low:
        return StockLevel.empty;
      case StockLevel.empty:
        return StockLevel.full;
    }
  }

  String get label {
    switch (this) {
      case StockLevel.full:
        return '買ったばっかり';
      case StockLevel.low:
        return '残量少';
      case StockLevel.empty:
        return '残量なし';
    }
  }

  Color get color {
    switch (this) {
      case StockLevel.full:
        return const Color(0xFF4CAF50);
      case StockLevel.low:
        return const Color(0xFFFF9800);
      case StockLevel.empty:
        return const Color(0xFFF44336);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StockLevel.full:
        return const Color(0xFFE8F5E9);
      case StockLevel.low:
        return const Color(0xFFFFF3E0);
      case StockLevel.empty:
        return const Color(0xFFFFEBEE);
    }
  }

  IconData get icon {
    switch (this) {
      case StockLevel.full:
        return Icons.check_circle_rounded;
      case StockLevel.low:
        return Icons.warning_amber_rounded;
      case StockLevel.empty:
        return Icons.remove_circle_rounded;
    }
  }

  int get sortOrder {
    switch (this) {
      case StockLevel.empty:
        return 0;
      case StockLevel.low:
        return 1;
      case StockLevel.full:
        return 2;
    }
  }

  String toJson() => name;

  static StockLevel fromJson(String value) {
    return StockLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockLevel.full,
    );
  }
}
