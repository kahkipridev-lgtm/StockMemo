import '../models/genre.dart';
import '../models/stock_item.dart';
import '../models/stock_level.dart';

List<StockItem> buildDefaultItems({DateTime? installedAt}) {
  // (name, yomi) — yomiはnullでもOK（カタカナ・ひらがなのみの場合は検索時に正規化で対応）
  final kitchenItems = <(String, String?)>[
    ('キッチンペーパー', null),
    ('ラップ', null),
    ('アルミホイル', null),
    ('ゴミ袋', 'ごみぶくろ'),
    ('食器洗い洗剤', 'しょっきあらいせんざい'),
    ('スポンジ', null),
  ];

  final condimentItems = <(String, String?)>[
    ('醤油', 'しょうゆ'),
    ('味噌', 'みそ'),
    ('砂糖', 'さとう'),
    ('塩', 'しお'),
    ('酢', 'す'),
    ('みりん', null),
    ('料理酒', 'りょうりしゅ'),
    ('サラダ油', 'さらだゆ'),
    ('ごま油', 'ごまあぶら'),
    ('だしの素', 'だしのもと'),
    ('コンソメ', null),
  ];

  final bathItems = <(String, String?)>[
    ('シャンプー', null),
    ('コンディショナー', null),
    ('ボディソープ', null),
    ('入浴剤', 'にゅうよくざい'),
  ];

  final toiletItems = <(String, String?)>[
    ('トイレットペーパー', null),
    ('トイレ洗剤', 'とわいれせんざい'),
    ('トイレブラシ', null),
    ('消臭スプレー', 'しょうしゅうすぷれー'),
  ];

  final washroomItems = <(String, String?)>[
    ('歯磨き粉', 'はみがきこ'),
    ('歯ブラシ', 'はぶらし'),
    ('洗顔料', 'せんがんりょう'),
    ('ハンドソープ', null),
  ];

  final laundryItems = <(String, String?)>[
    ('洗濯洗剤', 'せんたくせんざい'),
    ('柔軟剤', 'じゅうなんざい'),
    ('漂白剤', 'ひょうはくざい'),
  ];

  final otherItems = <(String, String?)>[
    ('ティッシュ', null),
    ('マスク', null),
    ('除菌スプレー', 'じょきんすぷれー'),
    ('電池', 'でんち'),
  ];

  int counter = 0;

  List<StockItem> makeItems(List<(String, String?)> items, String genreId) {
    return items.map((item) {
      final id = 'default_${counter++}';
      return StockItem(
        id: id,
        name: item.$1,
        yomi: item.$2,
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
