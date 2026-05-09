import 'package:flutter/material.dart';

enum StockLevel {
  full,
  low,
  empty;

  static const _metadata = {
    StockLevel.full: _Meta(
      label: '買ったばっかり',
      color: Color(0xFF4CAF50),
      backgroundColor: Color(0xFFE8F5E9),
      icon: Icons.check_circle_rounded,
      sortOrder: 2,
      next: StockLevel.low,
    ),
    StockLevel.low: _Meta(
      label: '残量少',
      color: Color(0xFFFF9800),
      backgroundColor: Color(0xFFFFF3E0),
      icon: Icons.warning_amber_rounded,
      sortOrder: 1,
      next: StockLevel.empty,
    ),
    StockLevel.empty: _Meta(
      label: '残量なし',
      color: Color(0xFFF44336),
      backgroundColor: Color(0xFFFFEBEE),
      icon: Icons.remove_circle_rounded,
      sortOrder: 0,
      next: StockLevel.full,
    ),
  };

  StockLevel get next => _metadata[this]!.next;
  String get label => _metadata[this]!.label;
  Color get color => _metadata[this]!.color;
  Color get backgroundColor => _metadata[this]!.backgroundColor;
  IconData get icon => _metadata[this]!.icon;
  int get sortOrder => _metadata[this]!.sortOrder;

  String toJson() => name;

  static StockLevel fromJson(String value) {
    return StockLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockLevel.full,
    );
  }
}

class _Meta {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final int sortOrder;
  final StockLevel next;

  const _Meta({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.sortOrder,
    required this.next,
  });
}
