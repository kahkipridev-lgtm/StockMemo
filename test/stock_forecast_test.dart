import 'package:flutter_test/flutter_test.dart';
import 'package:stock_memo/services/stock_forecast.dart';

const full = ForecastLevel.full;
const low = ForecastLevel.low;
const empty = ForecastLevel.empty;

final t0 = DateTime(2026, 9, 1, 9);

DateTime day(double d) => t0.add(Duration(minutes: (d * 1440).round()));

ForecastEvent ev(double d, ForecastLevel level) => ForecastEvent(day(d), level);

/// 「補充 → (残りわずか) → 在庫切れ → 翌日補充」を [cycles] 回くり返した履歴
List<ForecastEvent> regularHistory({
  int cycles = 5,
  double days = 10,
  bool useLow = true,
}) {
  final h = <ForecastEvent>[ev(0, full)];
  var start = 0.0;
  for (var i = 0; i < cycles; i++) {
    if (useLow) h.add(ev(start + days * 0.7, low));
    h.add(ev(start + days, empty));
    start = start + days + 1;
    h.add(ev(start, full));
  }
  return h;
}

StockForecast? forecastOf(
  List<ForecastEvent> history, {
  required DateTime now,
  ForecastLevel? current,
  List<DateTime> purchases = const [],
  List<ForecastItemInput> others = const [],
}) {
  final result = const StockForecaster().run(
    items: [
      ForecastItemInput(
        id: 'x',
        name: 'テスト',
        currentLevel: current ?? history.last.level,
        history: history,
        purchases: purchases,
      ),
      ...others,
    ],
    now: now,
  );
  return result.forecasts.where((f) => f.itemId == 'x').firstOrNull;
}

void main() {
  test('規則的な記録なら、その日数で予測する', () {
    final h = regularHistory();
    final f = forecastOf(h, now: day(58))!;
    expect(f.typicalDays, closeTo(10, 0.1));
    expect(f.predictedAt.difference(h.last.at).inHours, closeTo(240, 2));
    expect(f.confidence, ForecastConfidence.high);
  });

  test('2段階モード（残りわずか無し）でも予測できる', () {
    final f = forecastOf(regularHistory(useLow: false), now: day(58))!;
    expect(f.typicalDays, closeTo(10, 0.1));
  });

  test('連打（数秒のうちに一周）しても予測は変わらない', () {
    final h = regularHistory();
    final last = h.last.at;
    final mashed = [
      ...h,
      ForecastEvent(last.add(const Duration(days: 2)), low),
      ForecastEvent(last.add(const Duration(days: 2, seconds: 1)), empty),
      ForecastEvent(last.add(const Duration(days: 2, seconds: 2)), full),
    ];
    final base = forecastOf(h, now: day(58))!;
    final f = forecastOf(mashed, now: day(58))!;
    expect(f.cycleStart, base.cycleStart);
    expect(f.typicalDays, closeTo(base.typicalDays, 0.01));
  });

  test('補充直後の誤タップを数時間後に直しても、補充日はリセットされない', () {
    final h = regularHistory();
    final last = h.last.at;
    final fixed = [
      ...h,
      ForecastEvent(last.add(const Duration(days: 1)), low),
      ForecastEvent(last.add(const Duration(days: 1, hours: 3)), empty),
      ForecastEvent(
        last.add(const Duration(days: 1, hours: 3, seconds: 1)),
        full,
      ),
    ];
    final f = forecastOf(fixed, now: day(58))!;
    expect(f.cycleStart, last);
  });

  test('在庫切れにし忘れた極端に長いサイクルは外れ値として除外される', () {
    final h = <ForecastEvent>[ev(0, full)];
    var start = 0.0;
    for (final d in [10.0, 10, 45, 10, 10, 10]) {
      h.add(ev(start + d, empty));
      start += d + 1;
      h.add(ev(start, full));
    }
    final f = forecastOf(h, now: day(start + 2))!;
    expect(f.typicalDays, closeTo(10, 0.5));
  });

  test('在庫切れ中に購入記録があれば、その時刻を補充日とする（戻し忘れの補正）', () {
    final h = regularHistory();
    final lastEmpty = h[h.length - 2].at;
    // 実際は在庫切れの翌日に買ったが、「買ったばっかり」に戻したのは6日後
    final late = [
      ...h.sublist(0, h.length - 1),
      ForecastEvent(lastEmpty.add(const Duration(days: 6)), full),
    ];
    final bought = lastEmpty.add(const Duration(days: 1));
    final f = forecastOf(late, now: day(60), purchases: [bought])!;
    expect(f.cycleStart, bought);
  });

  test('在庫切れのまま購入記録だけある場合は、補充済みと推定して予測する', () {
    final h = regularHistory();
    final stillEmpty = [...h, ev(65, empty)];
    final bought = day(66);
    final f = forecastOf(
      stillEmpty,
      now: day(67),
      current: empty,
      purchases: [bought],
    )!;
    expect(f.restockInferredFromPurchase, isTrue);
    expect(f.cycleStart, bought);
  });

  test('在庫切れ中のもの（購入記録なし）は予測の対象外', () {
    final h = [...regularHistory(), ev(65, empty)];
    expect(forecastOf(h, now: day(66)), isNull);
  });

  test('「残りわずか」にした後は、その時点からの日数で予測する', () {
    final h = [...regularHistory(), ev(62, low)];
    final f = forecastOf(h, now: day(62.5))!;
    expect(f.basedOnLowMark, isTrue);
    expect(f.predictedAt.difference(day(62)).inHours, closeTo(72, 3));
  });

  test('全データリセットによる一斉の「買ったばっかり」は補充として扱わない', () {
    final reset = day(64);
    List<ForecastEvent> withReset(List<ForecastEvent> h) => [
      ...h,
      ev(62, low),
      ForecastEvent(reset, full),
    ];
    final others = [
      for (var i = 0; i < 3; i++)
        ForecastItemInput(
          id: 'o$i',
          name: 'other$i',
          currentLevel: full,
          history: [ev(0, full), ev(30, empty), ForecastEvent(reset, full)],
        ),
    ];
    final f = forecastOf(
      withReset(regularHistory()),
      now: day(65),
      others: others,
    )!;
    expect(f.confidence, ForecastConfidence.low);
  });

  test('記録が足りないアイテムは「データ収集中」になる', () {
    final result = const StockForecaster().run(
      items: [
        ForecastItemInput(
          id: 'new',
          name: '新しいもの',
          currentLevel: full,
          history: [ev(0, full)],
        ),
      ],
      now: day(3),
    );
    expect(result.forecasts, isEmpty);
    expect(result.collectingItemIds, ['new']);
  });

  test('買い物メモだけで繰り返し買っているものは購入間隔から予測する', () {
    final purchases = [
      for (var i = 0; i < 5; i++) day(i * 7.0),
      // チェックの付け外しによる重複記録
      day(28).add(const Duration(seconds: 5)),
    ];
    final result = const StockForecaster().run(
      items: const [],
      purchaseSeries: [PurchaseSeriesInput(name: '牛乳', purchases: purchases)],
      now: day(30),
    );
    final f = result.forecasts.single;
    expect(f.source, ForecastSource.purchaseLog);
    expect(f.typicalDays, closeTo(7, 0.1));
  });

  // ---- 以下はサブエージェントのシミュレーション評価で見つかった失敗パターン ----

  test('在庫切れ中の行き過ぎ連打（一瞬だけ買ったばっかり）で「数時間で切れる」予測にならない', () {
    final h = [
      ...regularHistory(),
      ev(62, low),
      ev(65, empty),
      ev(65.00001, full), // 在庫切れにするつもりが行き過ぎた
      ev(65.25, low), // 6時間後に直そうとして一周
      ev(65.25001, empty),
      ev(66, full), // 翌日に本当の補充
    ];
    final f = forecastOf(h, now: day(67))!;
    expect(f.typicalDays, greaterThan(8));
    expect(f.cycleStart, day(66));
  });

  test('在庫切れ→残りわずか（在庫切れの取り消し）で予測が消えない', () {
    final h = [
      ...regularHistory(),
      ev(62, empty),
      ev(62.2, full),
      ev(62.20002, low),
    ];
    final f = forecastOf(h, now: day(62.5), current: low);
    expect(f, isNotNull);
  });

  test('初期データの一斉登録を起点にした記録だけでは予測しない（短く出るため）', () {
    final install = day(0);
    final defaults = [
      for (var i = 0; i < 5; i++)
        ForecastItemInput(
          id: 'd$i',
          name: 'default$i',
          currentLevel: full,
          history: [ForecastEvent(install, full)],
        ),
    ];
    final result = const StockForecaster().run(
      items: [
        ...defaults,
        ForecastItemInput(
          id: 'x',
          name: '使いかけで登録',
          currentLevel: full,
          history: [ForecastEvent(install, full), ev(2, empty), ev(3, full)],
        ),
      ],
      now: day(6),
    );
    expect(result.forecasts, isEmpty);
    expect(result.collectingItemIds, contains('x'));
  });

  test('個別に追加したアイテムは、初回の記録から「目安」として予測する', () {
    final f = forecastOf([
      ev(0, full),
      ev(10, empty),
      ev(11, full),
    ], now: day(13))!;
    expect(f.typicalDays, closeTo(10, 0.1));
    expect(f.confidence, ForecastConfidence.low);
  });

  test('買ったばっかりのまま、予測の終盤に購入記録があれば補充とみなす（在庫切れにし忘れ）', () {
    final h = regularHistory(useLow: false);
    final bought = h.last.at.add(const Duration(days: 9));
    final f = forecastOf(
      h,
      now: bought.add(const Duration(days: 2)),
      purchases: [bought],
    )!;
    expect(f.cycleStart, bought);
    expect(f.restockInferredFromPurchase, isTrue);
  });

  test('予測の準備度: 初期データ→在庫切れ→補充と進むと上がり、50%を超える', () {
    final install = day(0);
    ForecastResult run(List<ForecastEvent> extra) =>
        const StockForecaster().run(
          items: [
            for (var i = 0; i < 4; i++)
              ForecastItemInput(
                id: 'd$i',
                name: 'default$i',
                currentLevel: i == 0 && extra.isNotEmpty
                    ? extra.last.level
                    : full,
                history: [ForecastEvent(install, full), if (i == 0) ...extra],
              ),
          ],
          now: day(20),
        );
    expect(run([]).readiness, 0);
    expect(run([ev(5, low)]).readiness, closeTo(0.15, 1e-9));
    expect(run([ev(5, low), ev(8, empty)]).readiness, closeTo(0.3, 1e-9));
    final restocked = run([ev(5, low), ev(8, empty), ev(9, full)]);
    expect(restocked.forecasts, isEmpty);
    expect(restocked.readiness, greaterThanOrEqualTo(0.5));
    expect(
      run([ev(5, low), ev(8, empty), ev(9, full), ev(15, empty)]).readiness,
      closeTo(0.8, 1e-9),
    );
    expect(
      run([
        ev(5, low),
        ev(8, empty),
        ev(9, full),
        ev(15, empty),
        ev(16, full),
      ]).readiness,
      1,
    );
  });

  test('名前の正規化（全角・カタカナ・空白）', () {
    expect(
      normalizeForecastName('トイレットペーパー'),
      normalizeForecastName('といれっとぺーぱー'),
    );
    expect(normalizeForecastName('ＡＢＣ　洗剤'), normalizeForecastName('abc洗剤'));
  });
}
