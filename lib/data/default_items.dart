import '../models/genre.dart';
import '../models/stock_item.dart';
import '../models/stock_level.dart';

List<StockItem> buildDefaultItems() {
  final kitchenItems = [
    '醤油', '味噌', '砂糖', '塩', '酢', 'みりん', '料理酒',
    'サラダ油', 'ごま油', 'だしの素', 'コンソメ',
    'キッチンペーパー', 'ラップ', 'アルミホイル', 'ゴミ袋',
    '食器洗い洗剤', 'スポンジ',
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

  List<StockItem> makeItems(List<String> names, Genre genre) {
    return names.map((name) {
      final id = 'default_${counter++}';
      return StockItem(
        id: id,
        name: name,
        genre: genre,
        stockLevel: StockLevel.full,
        isDefault: true,
      );
    }).toList();
  }

  return [
    ...makeItems(kitchenItems, Genre.kitchen),
    ...makeItems(bathItems, Genre.bath),
    ...makeItems(toiletItems, Genre.toilet),
    ...makeItems(washroomItems, Genre.washroom),
    ...makeItems(laundryItems, Genre.laundry),
    ...makeItems(otherItems, Genre.other),
  ];
}
