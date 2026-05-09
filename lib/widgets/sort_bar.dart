import 'package:flutter/material.dart';

import '../providers/settings_provider.dart';

class SortBar extends StatelessWidget {
  final SortOrder currentSort;
  final ValueChanged<SortOrder> onSortChanged;

  const SortBar({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Text('並び替え：', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          _SortChip(
            label: '50音順',
            icon: Icons.sort_by_alpha_rounded,
            selected: currentSort == SortOrder.alphabetical,
            onTap: () => onSortChanged(SortOrder.alphabetical),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: '残量順',
            icon: Icons.bar_chart_rounded,
            selected: currentSort == SortOrder.stockLevel,
            onTap: () => onSortChanged(SortOrder.stockLevel),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: '更新日順',
            icon: Icons.history_rounded,
            selected: currentSort == SortOrder.lastUpdated,
            onTap: () => onSortChanged(SortOrder.lastUpdated),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
