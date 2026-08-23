import 'genre.dart';
import 'stock_level.dart';

class InventoryFilter {
  final Genre? genre;
  final List<StockLevel>? levels;

  const InventoryFilter({this.genre, this.levels});

  String get title {
    if (genre != null) return genre!.label;
    if (levels != null) {
      if (levels!.length == 1 && levels!.first == StockLevel.empty) {
        return '在庫切れ';
      }
    }
    return '全ての在庫';
  }
}
