import '../models/genre.dart';
import '../models/stock_item.dart';
import '../models/stock_level.dart';

List<StockItem> buildDefaultItems({DateTime? installedAt}) {
  final kitchenItems = [
    'キッチンペーパー', 'ラップ', 'アルミホイル', 'ゴミ袋',
    '食器洗い洗剤', 'スポンジ',
  ];

  final condimentItems = [
    '醤油', '味噌', '砂糖', '塩', '酢', 'みりん', '料理酒',
    'サラダ油', 'ごま油', 'だしの素', 'コンソメ',
  ];

  final bathItems = [
    'シャンプー', 'コンディショナー', 'ボディソープ', '入浴剤',
  ];

  final toiletItems = [
    'トイレットペーパー', 'トイレ洗剤', 'トイレブラシ', '消臭スプレー',
  ];

  final washroomItems = [
    '歯磨き粉', '歯ブラシ', '洗顔料', 'ハンドソープ',
  ];

  final laundryItems = [
    '洗濯洗剤', '柔軟剤', '漂白剤',
  ];

  final otherItems = [
    'ティッシュ', 'マスク', '除菌スプレー', '電池',
  ];

  int counter = 0;

  List<StockItem> makeItems(List<String> names, String genreId) {
    return names.map((name) {
      final id = 'default_${counter++}';
      return StockItem(
        id: id,
        name: name,
        genreId: genreId,
        stockLevel: StockLevel.full,
        isDefault: true,
        statusUpdatedAt: installedAt,
      );
    }).toList();
  }

  return [
    ...makeItems(kitchenItems, Genre.kitchen.id),
    ...makeItems(bathItems, Genre.bath.id),
    ...makeItems(toiletItems, Genre.toilet.id),
    ...makeItems(washroomItems, Genre.washroom.id),
    ...makeItems(laundryItems, Genre.laundry.id),
    ...makeItems(condimentItems, Genre.condiment.id),
    ...makeItems(otherItems, Genre.other.id),
  ];
}
