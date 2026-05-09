import '../models/inventory_filter.dart';
import '../models/stock_item.dart';
import '../providers/settings_provider.dart';

List<StockItem> filterItems(List<StockItem> items, InventoryFilter filter) {
  return items.where((item) {
    if (filter.genre != null && item.genreId != filter.genre!.id) return false;
    if (filter.levels != null && !filter.levels!.contains(item.stockLevel)) {
      return false;
    }
    return true;
  }).toList();
}

List<StockItem> sortItems(List<StockItem> items, SortOrder order) {
  final sorted = List<StockItem>.from(items);
  switch (order) {
    case SortOrder.alphabetical:
      sorted.sort((a, b) => a.name.compareTo(b.name));
    case SortOrder.stockLevel:
      sorted.sort((a, b) {
        final levelCmp =
            a.stockLevel.sortOrder.compareTo(b.stockLevel.sortOrder);
        if (levelCmp != 0) return levelCmp;
        return a.name.compareTo(b.name);
      });
    case SortOrder.lastUpdated:
      sorted.sort((a, b) {
        if (a.statusUpdatedAt == null && b.statusUpdatedAt == null) {
          return a.name.compareTo(b.name);
        }
        if (a.statusUpdatedAt == null) return -1;
        if (b.statusUpdatedAt == null) return 1;
        return a.statusUpdatedAt!.compareTo(b.statusUpdatedAt!);
      });
  }
  return sorted;
}
