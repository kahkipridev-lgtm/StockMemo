// 在庫予測エンジン
//
// 在庫ステータスの変更履歴（買ったばっかり／残りわずか／在庫切れ）と買い物リストの購入記録から、
// 「次にいつ切れそうか」を予測する。
//
// Flutterに依存しない純粋なDartコードにしてある（シミュレーションによる精度評価スクリプトから
// 直接読み込めるようにするため）。アプリのモデルとの変換は providers/forecast_provider.dart で行う。
//
// 単純平均だと、次のような「記録のゆらぎ」に引きずられるため、以下の対策を入れている。
// - 連打（短時間に何度もタップ）           → 短時間の連続操作を1回の操作にまとめる
// - 誤タップをしばらく後に直した           → サイクル序盤のごく短い寄り道を無かったことにする
// - 買ったのに「買ったばっかり」に戻し忘れ → 購入記録があればその時刻を補充日とみなす／
//                                           長く放置された補充は信頼度を下げる
// - 切れたのに「在庫切れ」にし忘れ等の外れ値 → 対数スケールの中央値＋MADで外れ値を除外
// - 設定の「全データをリセット」や初回登録 → 補充日として信頼しない
// - 使うペースの変化                       → 新しい記録ほど重く扱う
import 'dart:math' as math;

/// 在庫レベル（予測用。アプリ側の StockLevel と同じ3段階）
enum ForecastLevel { full, low, empty }

/// ステータス変更の記録1件
class ForecastEvent {
  final DateTime at;
  final ForecastLevel level;
  const ForecastEvent(this.at, this.level);
}

/// 在庫アイテム1つ分の入力
class ForecastItemInput {
  final String id;
  final String name;
  final ForecastLevel currentLevel;

  /// ステータス変更履歴（順不同で可。内部で時刻順に並べ替える）
  final List<ForecastEvent> history;

  /// このアイテムと名前が一致した買い物リストの購入記録
  final List<DateTime> purchases;

  const ForecastItemInput({
    required this.id,
    required this.name,
    required this.currentLevel,
    required this.history,
    this.purchases = const [],
  });
}

/// 在庫アイテムに無い、買い物リストだけで繰り返し買っているものの購入記録
class PurchaseSeriesInput {
  final String name;
  final List<DateTime> purchases;
  const PurchaseSeriesInput({required this.name, required this.purchases});
}

enum ForecastSource {
  /// 在庫ステータスの履歴から予測
  stockHistory,

  /// 買い物リストの購入間隔から予測
  purchaseLog,
}

enum ForecastConfidence { low, medium, high }

/// 1アイテム分の予測結果
class StockForecast {
  /// 在庫アイテムならそのID、購入記録だけのものは null
  final String? itemId;
  final String name;
  final ForecastSource source;
  final ForecastLevel currentLevel;

  /// 今の在庫を補充した（とみなした）日時
  final DateTime cycleStart;

  /// 切れると予測される日時
  final DateTime predictedAt;

  /// 予測の幅（早い側／遅い側）
  final DateTime earliestAt;
  final DateTime latestAt;

  /// 補充してから使い切るまでの日数の推定値（購入記録の場合は購入間隔）
  final double typicalDays;

  /// 予測に使った記録の数（外れ値として除外したものは含まない）
  final int sampleCount;

  final ForecastConfidence confidence;

  /// 「残りわずか」にした時刻を起点に予測したか
  final bool basedOnLowMark;

  /// アプリ上は在庫切れ／残りわずかのままだが、購入記録から補充済みと推定したか
  final bool restockInferredFromPurchase;

  /// この時刻以降に購入記録（「買ってきた」・買い物リストのチェック）を付けると、
  /// 補充として予測し直される（null なら購入記録では予測し直せない）。
  /// 画面の「買ってきた」ボタンはこの時刻以降だけ出すと、押しても変わらないことが無い
  final DateTime? purchaseRestartFrom;

  const StockForecast({
    required this.itemId,
    required this.name,
    required this.source,
    required this.currentLevel,
    required this.cycleStart,
    required this.predictedAt,
    required this.earliestAt,
    required this.latestAt,
    required this.typicalDays,
    required this.sampleCount,
    required this.confidence,
    this.basedOnLowMark = false,
    this.restockInferredFromPurchase = false,
    this.purchaseRestartFrom,
  });

  /// 予測日までの残り日数（過ぎていればマイナス）
  double daysLeft(DateTime now) => _days(predictedAt.difference(now));

  /// 補充から予測日までのうち、どれだけ経過したか（0〜1以上）
  double progress(DateTime now) {
    final total = _days(predictedAt.difference(cycleStart));
    if (total <= 0) return 1;
    return _days(now.difference(cycleStart)) / total;
  }

  /// 予測の幅を大きく過ぎても記録が無い（在庫切れにし忘れ・買ったのに戻し忘れ・使わなくなった等の可能性）
  bool isStale(DateTime now) {
    final grace = math.max(3.0, 0.5 * typicalDays);
    return _days(now.difference(latestAt)) > grace;
  }
}

class ForecastResult {
  /// 予測できたアイテム（予測日が近い順）
  final List<StockForecast> forecasts;

  /// 記録が足りずまだ予測できない在庫アイテムのID
  final List<String> collectingItemIds;

  /// 最初の予測が表示されるまでの準備度（0〜1）。一番予測に近いアイテムの段階
  /// （予測が1つでもあれば1）。データ収集中の画面の表示に使う
  final double readiness;

  const ForecastResult({
    required this.forecasts,
    required this.collectingItemIds,
    this.readiness = 0,
  });
}

class ForecastConfig {
  /// この間隔以内の連続操作は連打として1回の操作にまとめる
  final Duration burstWindow;

  /// 補充直後（推定日数のこの割合まで）に、この時間以内で元に戻された変更は誤タップとみなす
  final Duration glitchWindow;
  final double glitchCyclePosition;

  /// 新しい記録ほど重く扱う半減期（記録の件数単位）
  final double recencyHalfLife;

  /// 「残りわずか」にするのが補充から使い切りまでのどのあたりか（データが無いときの既定値）
  final double defaultLowFraction;

  /// 同じ時刻に「買ったばっかり」になったアイテムがこの数以上あれば一括リセットとみなす
  final int bulkResetMinItems;

  /// この間隔以内の購入記録は1回の買い物とみなす
  final Duration purchaseMergeWindow;

  /// 在庫切れ中の購入記録から、この期間内に「買ったばっかり」にしていれば購入時刻を補充日とする
  final Duration purchaseRestockLookahead;

  /// 購入記録だけのものを予測するのに必要な購入回数
  final int minPurchasesForSeries;

  /// 補充日として信頼できない記録の重み
  final double uncertainStartWeight;

  /// 在庫切れ→補充までに長くかかった（戻し忘れの疑い）記録の重み
  final double longWaitWeight;

  /// 「残りわずか」から換算した記録の重み
  final double viaLowWeight;

  /// 在庫切れ中に一瞬だけ「買ったばっかり」になった記録を補充とみなさない条件
  /// （この時間以内、かつ推定日数のこの割合未満で在庫切れ等に戻された）
  final Duration fakeRestockWindow;
  final double fakeRestockCyclePosition;

  /// 「買ったばっかり」のままでも、推定日数のこの割合を過ぎてからの購入記録は補充とみなす
  final double purchaseInFullCyclePosition;

  /// これより短い「補充→使い切り」の記録は操作ミスとして使わない
  final double minObservationDays;

  /// 「買ったばっかり」のままの購入記録を、後に記録が続いても補充の区切りとして残す条件
  /// （次の「残りわずか／在庫切れ」が購入から推定日数のこの割合以上あと）
  final double purchaseRestockMinRemaining;

  const ForecastConfig({
    this.burstWindow = const Duration(minutes: 15),
    this.glitchWindow = const Duration(hours: 6),
    this.glitchCyclePosition = 0.35,
    this.recencyHalfLife = 4,
    this.defaultLowFraction = 0.7,
    this.bulkResetMinItems = 3,
    this.purchaseMergeWindow = const Duration(hours: 24),
    this.purchaseRestockLookahead = const Duration(days: 21),
    this.minPurchasesForSeries = 3,
    this.uncertainStartWeight = 0.3,
    this.longWaitWeight = 0.6,
    this.viaLowWeight = 0.6,
    this.fakeRestockWindow = const Duration(hours: 24),
    this.fakeRestockCyclePosition = 0.2,
    this.purchaseInFullCyclePosition = 0.6,
    this.minObservationDays = 0.5,
    this.purchaseRestockMinRemaining = 0.5,
  });
}

/// 購入記録と在庫アイテムの名前を突き合わせるための正規化
/// （前後の空白除去・全角英数→半角・カタカナ→ひらがな・小文字化・空白除去）
String normalizeForecastName(String s) {
  final buf = StringBuffer();
  for (final rune in s.trim().runes) {
    var c = rune;
    if (c == 0x20 || c == 0x3000) continue;
    if (c >= 0xFF01 && c <= 0xFF5E) c -= 0xFEE0;
    if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60;
    buf.writeCharCode(c);
  }
  return buf.toString().toLowerCase();
}

class StockForecaster {
  final ForecastConfig config;
  const StockForecaster([this.config = const ForecastConfig()]);

  ForecastResult run({
    required List<ForecastItemInput> items,
    List<PurchaseSeriesInput> purchaseSeries = const [],
    required DateTime now,
  }) {
    final resetTimes = _detectBulkResets(items);

    // 1回目: 誤タップ判定などに使う「おおよその日数」と、全アイテム共通の
    // 「残りわずか」にするタイミングの傾向を求める
    final prelim = <String, _Estimate?>{};
    final lowFractionSamples = <double>[];
    final itemLowFractions = <String, List<double>>{};
    for (final item in items) {
      final evs = _clean(item, resetTimes);
      final cycles = _segment(evs);
      final fractions = _lowFractions(cycles);
      itemLowFractions[item.id] = fractions;
      lowFractionSamples.addAll(fractions);
      prelim[item.id] = _estimate(
        _trusted(_observations(cycles, null, config.defaultLowFraction)),
      );
    }
    final globalLowFraction = lowFractionSamples.isEmpty
        ? config.defaultLowFraction
        : _median(lowFractionSamples);

    // 2回目: 誤タップ除去・購入記録の反映・戻し忘れの重み付けをして本推定
    final forecasts = <StockForecast>[];
    final collecting = <String>[];
    var readiness = 0.0;
    for (final item in items) {
      final itemFractions = itemLowFractions[item.id]!;
      // アイテム固有の傾向を、全体の傾向で少しならす
      final lowFraction =
          (itemFractions.fold<double>(0, (a, b) => a + b) +
              2 * globalLowFraction) /
          (itemFractions.length + 2);
      final f = _forecastItem(
        item,
        resetTimes,
        prelim[item.id]?.days,
        lowFraction,
        now,
      );
      if (f != null) {
        forecasts.add(f);
      } else {
        if (item.currentLevel != ForecastLevel.empty) collecting.add(item.id);
        readiness = math.max(readiness, _readiness(item, resetTimes));
      }
    }

    for (final series in purchaseSeries) {
      final f = _forecastSeries(series, now);
      if (f != null) forecasts.add(f);
    }

    forecasts.sort((a, b) => a.predictedAt.compareTo(b.predictedAt));
    return ForecastResult(
      forecasts: forecasts,
      collectingItemIds: collecting,
      readiness: forecasts.isNotEmpty ? 1 : readiness,
    );
  }

  // まだ予測できないアイテムが、最初の予測までどこまで進んでいるか（0〜0.8）。
  // 予測には「確かな補充（または個別に追加）→ 在庫切れ」の1サイクルと、
  // そのあと在庫ありに戻っていることが必要なので、
  //   初期データのまま 0 → 残りわずか 0.15 → 在庫切れ 0.3
  //   → 補充した／個別に追加した 0.5 → 残りわずか 0.65 → 在庫切れ 0.8
  //   → 補充して予測表示
  double _readiness(ForecastItemInput item, Set<int> resetTimes) {
    var best = 0.0;
    for (final c in _segment(_clean(item, resetTimes))) {
      final double stage;
      if (c.startBulk) {
        stage = c.empty != null ? 0.3 : (c.low != null ? 0.15 : 0);
      } else {
        stage = c.empty != null ? 0.8 : (c.low != null ? 0.65 : 0.5);
      }
      best = math.max(best, stage);
    }
    return best;
  }

  // 「全データをリセット」や初期アイテム登録のように、複数アイテムがまったく同じ時刻に
  // 「買ったばっかり」になった記録を見つける（実際の補充ではないため）
  Set<int> _detectBulkResets(List<ForecastItemInput> items) {
    final counts = <int, int>{};
    for (final item in items) {
      final times = item.history
          .where((e) => e.level == ForecastLevel.full)
          .map((e) => e.at.microsecondsSinceEpoch)
          .toSet();
      for (final t in times) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return {
      for (final e in counts.entries)
        if (e.value >= config.bulkResetMinItems) e.key,
    };
  }

  // 履歴を時刻順に並べ、連打をまとめ、変化の無い記録を取り除く
  List<_Ev> _clean(ForecastItemInput item, Set<int> resetTimes) {
    final sorted = [...item.history]..sort((a, b) => a.at.compareTo(b.at));
    final groups = <List<ForecastEvent>>[];
    for (final e in sorted) {
      if (groups.isNotEmpty &&
          e.at.difference(groups.last.last.at) <= config.burstWindow) {
        groups.last.add(e);
      } else {
        groups.add([e]);
      }
    }

    final purchases = _mergeClose(item.purchases);
    final evs = <_Ev>[];
    for (var gi = 0; gi < groups.length; gi++) {
      final g = groups[gi];
      final level = g.last.level;
      final isReset =
          level == ForecastLevel.full &&
          g.any(
            (e) =>
                e.level == ForecastLevel.full &&
                resetTimes.contains(e.at.microsecondsSinceEpoch),
          );

      // 先に買っておいた（購入記録がある）状態で、使い切った瞬間に
      // 「在庫切れ→買ったばっかり」と続けて押した場合は、連打ではなく本物の使い切り＋補充
      if (level == ForecastLevel.full &&
          evs.isNotEmpty &&
          evs.last.level == ForecastLevel.full &&
          g.any((e) => e.level == ForecastLevel.empty)) {
        final cycleStart = evs.last.at;
        final boughtAhead = purchases.any(
          (p) => p.isAfter(cycleStart) && !p.isAfter(g.first.at),
        );
        if (boughtAhead) {
          evs.add(_Ev(g.first.at, ForecastLevel.empty));
          evs.add(
            _Ev(g.last.at.add(const Duration(seconds: 1)), ForecastLevel.full),
          );
          continue;
        }
      }

      if (evs.isNotEmpty && evs.last.level == level) {
        // 購入記録のあとにもう一度「在庫切れ」にした（買ったものも使い切った・「もう切れた」）は
        // 購入による補充推定より優先するので残す
        final prevAt = evs.last.at;
        final reconfirmedEmpty =
            level == ForecastLevel.empty &&
            purchases.any((p) => p.isAfter(prevAt) && !p.isAfter(g.first.at));
        if (!reconfirmedEmpty) continue;
      }
      evs.add(
        _Ev(g.first.at, level, uncertain: gi == 0 || isReset, bulk: isReset),
      );
    }
    return evs;
  }

  // 補充直後に付けられ、すぐ「買ったばっかり」に戻された寄り道（誤タップの修正）を取り除く
  List<_Ev> _removeGlitches(
    List<_Ev> evs,
    double? typicalDays,
    List<DateTime> purchases,
  ) {
    if (typicalDays == null) return evs;
    final out = <_Ev>[];
    DateTime? cycleStart;
    var startUncertain = false;
    var i = 0;
    while (i < evs.length) {
      final e = evs[i];
      if (e.level == ForecastLevel.full &&
          _isFakeRestock(evs, i, out, typicalDays, purchases)) {
        i++;
        continue;
      }
      if (e.level == ForecastLevel.full) {
        cycleStart = e.at;
        startUncertain = e.uncertain;
        out.add(e);
        i++;
        continue;
      }
      // 初回登録・一括リセットの時点では既に使いかけのことがあるので、
      // そこからの経過割合では誤タップか判断できない（直後の操作だけを対象にする）
      if (cycleStart != null &&
          !(startUncertain &&
              e.at.difference(cycleStart) > const Duration(days: 1))) {
        final j = evs.indexWhere((x) => x.level == ForecastLevel.full, i + 1);
        if (j != -1) {
          final excursion = evs[j].at.difference(e.at);
          final position = _days(e.at.difference(cycleStart)) / typicalDays;
          if (excursion <= config.glitchWindow &&
              position < config.glitchCyclePosition) {
            i = j + 1;
            continue;
          }
        }
      }
      out.add(e);
      i++;
    }
    return out;
  }

  // 在庫切れ中（残りわずか中）に一瞬だけ「買ったばっかり」になり、すぐ在庫切れに戻された記録
  // （在庫切れにするつもりの連打で行き過ぎ、後から直した等）は補充ではない
  bool _isFakeRestock(
    List<_Ev> evs,
    int i,
    List<_Ev> out,
    double typicalDays,
    List<DateTime> purchases,
  ) {
    if (out.isEmpty || out.last.level == ForecastLevel.full) return false;
    if (i + 1 >= evs.length || evs[i + 1].level != ForecastLevel.empty) {
      return false;
    }
    final dur = evs[i + 1].at.difference(evs[i].at);
    if (dur > config.fakeRestockWindow ||
        _days(dur) >= config.fakeRestockCyclePosition * typicalDays) {
      return false;
    }
    // 補充直後の誤タップをすぐ直したケースは _removeGlitches 本体で扱う
    if (i + 2 < evs.length &&
        evs[i + 2].level == ForecastLevel.full &&
        evs[i + 2].at.difference(evs[i + 1].at) <= config.glitchWindow) {
      return false;
    }
    final from = evs[i].at.subtract(const Duration(hours: 1));
    return !purchases.any(
      (p) => !p.isBefore(from) && !p.isAfter(evs[i + 1].at),
    );
  }

  // 在庫切れ／残りわずかの間に購入記録があれば、その時刻を補充日とする。
  // 「買ったばっかり」のままでも、推定日数の一定割合を過ぎてからの購入記録は補充とみなす
  // （在庫切れにし忘れたまま買ってきたケース）
  List<_Ev> _applyPurchases(
    List<_Ev> evs,
    List<DateTime> rawPurchases,
    double? typicalDays,
  ) {
    if (rawPurchases.isEmpty || evs.isEmpty) return evs;
    final out = [...evs];
    // 近すぎる購入記録は1回の買い物とみなすが、基準は「実際に反映した」購入記録にする
    // （前日に先買いの記録があっても、今日の「買ってきた」が無視されないように）
    DateTime? lastApplied;
    for (final p in [...rawPurchases]..sort()) {
      if (lastApplied != null &&
          p.difference(lastApplied) <= config.purchaseMergeWindow) {
        continue;
      }
      final k = out.lastIndexWhere((e) => !e.at.isAfter(p));
      if (k >= 0 &&
          out[k].level == ForecastLevel.full &&
          typicalDays != null &&
          _days(p.difference(out[k].at)) >=
              config.purchaseInFullCyclePosition * typicalDays) {
        if (k == out.length - 1) {
          out.add(
            _Ev(p, ForecastLevel.full, fromPurchase: true, inferred: true),
          );
          lastApplied = p;
        } else if (out[k + 1].level != ForecastLevel.full &&
            _days(out[k + 1].at.difference(p)) >=
                config.purchaseRestockMinRemaining * typicalDays) {
          // その後に記録が続いていても、購入から十分たってからの「残りわずか／在庫切れ」なら、
          // 購入時点で補充していた（先買いではない）とみなして区切りを残す
          out.insert(k + 1, _Ev(p, ForecastLevel.full, fromPurchase: true));
          lastApplied = p;
        }
        continue;
      }
      if (k < 0 || out[k].level == ForecastLevel.full) continue;
      if (k + 1 < out.length) {
        final next = out[k + 1];
        if (next.level == ForecastLevel.full &&
            next.at.difference(p) <= config.purchaseRestockLookahead) {
          out[k + 1] = _Ev(p, ForecastLevel.full, fromPurchase: true);
          lastApplied = p;
        }
      } else {
        // アプリ上はまだ在庫切れのままだが、買ってきているので補充済みとみなす
        out.add(_Ev(p, ForecastLevel.full, fromPurchase: true, inferred: true));
        lastApplied = p;
      }
    }
    return out;
  }

  // 「買ったばっかり」になった時点を区切りとして、補充〜次の補充を1サイクルにまとめる
  List<_Cycle> _segment(List<_Ev> evs) {
    final cycles = <_Cycle>[];
    _Cycle? cur;
    for (final e in evs) {
      if (e.level == ForecastLevel.full) {
        Duration? waitBefore;
        if (cur != null) {
          cur.end = e.at;
          final depletedAt = cur.empty ?? cur.low;
          if (depletedAt != null) waitBefore = e.at.difference(depletedAt);
        }
        cur = _Cycle(
          start: e.at,
          startUncertain: e.uncertain,
          startBulk: e.bulk,
          fromPurchase: e.fromPurchase,
          inferred: e.inferred,
          waitBefore: waitBefore,
        );
        cycles.add(cur);
      } else if (cur != null) {
        if (e.level == ForecastLevel.low) {
          // 在庫切れ→残りわずか（在庫切れが間違いだったので戻した）なら在庫切れを取り消す
          cur.empty = null;
          cur.low ??= e.at;
        } else if (e.level == ForecastLevel.empty) {
          cur.empty ??= e.at;
        }
      }
    }
    return cycles;
  }

  List<double> _lowFractions(List<_Cycle> cycles) {
    final out = <double>[];
    for (final c in cycles) {
      if (c.startUncertain || c.low == null || c.empty == null) continue;
      final total = _days(c.empty!.difference(c.start));
      if (total <= 0) continue;
      final f = _days(c.low!.difference(c.start)) / total;
      out.add(f.clamp(0.05, 0.98).toDouble());
    }
    return out;
  }

  // 各サイクルから「補充してから使い切るまでの日数」の観測値を取り出す
  List<_Obs> _observations(
    List<_Cycle> cycles,
    double? typicalDays,
    double lowFraction,
  ) {
    final obs = <_Obs>[];
    for (final c in cycles) {
      var weight = c.startUncertain ? config.uncertainStartWeight : 1.0;
      final wait = c.waitBefore;
      if (!c.startUncertain &&
          !c.fromPurchase &&
          wait != null &&
          typicalDays != null &&
          _days(wait) > math.max(4.0, 0.5 * typicalDays)) {
        // 在庫切れのまま長く放置された後の補充は、実際の購入より遅れて記録された疑いがある
        weight *= config.longWaitWeight;
      }
      if (c.empty != null) {
        obs.add(
          _Obs(
            _days(c.empty!.difference(c.start)),
            weight,
            uncertain: c.startUncertain,
            bulk: c.startBulk,
          ),
        );
      } else if (c.end != null && c.low != null) {
        // 使い切る前に買い足したサイクルは「残りわずか」までの日数から換算する
        obs.add(
          _Obs(
            _days(c.low!.difference(c.start)) / lowFraction,
            weight * config.viaLowWeight,
            uncertain: c.startUncertain,
            bulk: c.startBulk,
          ),
        );
      }
    }
    return obs;
  }

  // 初回登録・一括リセットを起点にした記録は、登録前から使っていた分が抜けていて
  // 短く出やすいので、起点が確かな記録が1つでもあればそちらだけを使う。
  // まだ無いうちは、個別に追加したアイテムの初回記録だけを「目安」として使う
  // （初期データの一斉登録・全データリセットを起点にしたものは使わず、データ収集中にする）。
  // また半日未満の記録は操作ミスとみなして除く。
  List<_Obs> _trusted(List<_Obs> obs) {
    final usable = [
      for (final o in obs)
        if (o.days >= config.minObservationDays) o,
    ];
    if (usable.any((o) => !o.uncertain)) {
      return [
        for (final o in usable)
          if (!o.uncertain) o,
      ];
    }
    return [
      for (final o in usable)
        if (!o.bulk) o,
    ];
  }

  StockForecast? _forecastItem(
    ForecastItemInput item,
    Set<int> resetTimes,
    double? prelimDays,
    double lowFraction,
    DateTime now,
  ) {
    var evs = _clean(item, resetTimes);
    evs = _removeGlitches(evs, prelimDays, item.purchases);
    // 「買ったばっかり」のままの購入記録を補充とみなすかの基準日数は、画面に出す推定日数にそろえる。
    // 購入記録で過去の補充日が補正されると推定日数も変わるので、いったん反映して推定し直す
    // （そろえないと「買ってきた」を押しても予測し直されないことがある）
    final firstPass = _estimate(
      _trusted(
        _observations(
          _segment(_applyPurchases(evs, item.purchases, prelimDays)),
          prelimDays,
          lowFraction,
        ),
      ),
    );
    final restartDays = firstPass?.days ?? prelimDays;
    evs = _applyPurchases(evs, item.purchases, restartDays);
    final cycles = _segment(evs);
    if (cycles.isEmpty) return null;

    final est = _estimate(
      _trusted(_observations(cycles, prelimDays, lowFraction)),
    );
    if (est == null) return null;

    final current = cycles.last;
    // いま在庫切れのもの（購入記録からの補充推定も無いもの）は予測の対象外
    if (current.empty != null) return null;
    if (item.currentLevel == ForecastLevel.empty && !current.inferred) {
      return null;
    }

    final typical = est.days;
    var predicted = current.start.add(_duration(typical));
    var earliest = current.start.add(_duration(typical * math.exp(-est.sigma)));
    var latest = current.start.add(_duration(typical * math.exp(est.sigma)));
    var basedOnLow = false;

    final lowAt = current.low;
    if (lowAt != null) {
      // 「残りわずか」にしてから使い切るまでの日数（このアイテムの実績があれば優先）
      final gaps = <_Obs>[
        for (final c in cycles)
          if (c.low != null && c.empty != null)
            _Obs(_days(c.empty!.difference(c.low!)), 1),
      ];
      final gapEst = _estimate(gaps);
      final ratioGap = typical * (1 - lowFraction);
      final double gap;
      if (gapEst == null) {
        gap = ratioGap;
      } else if (gapEst.count == 1) {
        gap = math.sqrt(gapEst.days * ratioGap);
      } else {
        gap = gapEst.days;
      }
      final sigma = gapEst != null && gapEst.count >= 2
          ? gapEst.sigma
          : math.max(est.sigma, 0.4);
      predicted = lowAt.add(_duration(gap));
      earliest = lowAt.add(_duration(gap * math.exp(-sigma)));
      latest = lowAt.add(_duration(gap * math.exp(sigma)));
      basedOnLow = true;
    }

    var confidence = _confidence(est);
    if (current.startUncertain && !basedOnLow) {
      confidence = ForecastConfidence.low;
    }

    // この時刻以降の購入記録（買い物リストのチェック・「買ってきた」）は補充として反映される
    DateTime? restartFrom;
    if (current.low != null || current.empty != null) {
      restartFrom = current.start;
    } else if (restartDays != null) {
      restartFrom = current.start.add(
        _duration(config.purchaseInFullCyclePosition * restartDays),
      );
    }
    if (restartFrom != null && current.fromPurchase) {
      final merged = current.start.add(
        config.purchaseMergeWindow + const Duration(seconds: 1),
      );
      if (merged.isAfter(restartFrom)) restartFrom = merged;
    }

    return StockForecast(
      purchaseRestartFrom: restartFrom,
      itemId: item.id,
      name: item.name,
      source: ForecastSource.stockHistory,
      currentLevel: current.inferred ? ForecastLevel.full : item.currentLevel,
      cycleStart: current.start,
      predictedAt: predicted,
      earliestAt: earliest,
      latestAt: latest,
      typicalDays: typical,
      sampleCount: est.count,
      confidence: confidence,
      basedOnLowMark: basedOnLow,
      restockInferredFromPurchase: current.inferred,
    );
  }

  StockForecast? _forecastSeries(PurchaseSeriesInput series, DateTime now) {
    final ps = _mergeClose(series.purchases);
    if (ps.length < config.minPurchasesForSeries) return null;
    final obs = <_Obs>[
      for (var i = 1; i < ps.length; i++)
        _Obs(_days(ps[i].difference(ps[i - 1])), 1),
    ];
    final est = _estimate(obs);
    if (est == null) return null;
    final last = ps.last;
    final predicted = last.add(_duration(est.days));
    // 予測を大きく過ぎても買っていないものは、もう定期的には買っていないとみなす
    if (_days(now.difference(predicted)) > math.max(30.0, 2 * est.days)) {
      return null;
    }
    return StockForecast(
      purchaseRestartFrom: last.add(
        config.purchaseMergeWindow + const Duration(seconds: 1),
      ),
      itemId: null,
      name: series.name,
      source: ForecastSource.purchaseLog,
      currentLevel: ForecastLevel.full,
      cycleStart: last,
      predictedAt: predicted,
      earliestAt: last.add(_duration(est.days * math.exp(-est.sigma))),
      latestAt: last.add(_duration(est.days * math.exp(est.sigma))),
      typicalDays: est.days,
      sampleCount: est.count,
      confidence: _confidence(est),
    );
  }

  ForecastConfidence _confidence(_Estimate est) {
    if (est.effectiveCount >= 3 && est.sigma <= 0.35) {
      return ForecastConfidence.high;
    }
    if (est.effectiveCount >= 1.5 && est.sigma <= 0.6) {
      return ForecastConfidence.medium;
    }
    return ForecastConfidence.low;
  }

  // 近すぎる購入記録（チェックの付け外しのやり直し・同じ日の買い足し）を1回にまとめる
  List<DateTime> _mergeClose(List<DateTime> raw) {
    final sorted = [...raw]..sort();
    final out = <DateTime>[];
    for (final p in sorted) {
      if (out.isNotEmpty &&
          p.difference(out.last) <= config.purchaseMergeWindow) {
        continue;
      }
      out.add(p);
    }
    return out;
  }

  // 対数スケールでの頑健な推定:
  // 新しい記録ほど重くした加重中央値と MAD で外れ値を除外し、残りの加重平均をとる
  _Estimate? _estimate(List<_Obs> obs) {
    if (obs.isEmpty) return null;
    const minDays = 0.25;
    const sigmaPrior = 0.4;
    final n = obs.length;
    final xs = [for (final o in obs) math.log(math.max(o.days, minDays))];
    final ws = [
      for (var i = 0; i < n; i++)
        obs[i].weight *
            math.pow(0.5, (n - 1 - i) / config.recencyHalfLife).toDouble(),
    ];

    var keep = List<bool>.filled(n, true);
    if (n >= 3) {
      final m = _weightedMedian(xs, ws);
      final mad = _weightedMedian([for (final x in xs) (x - m).abs()], ws);
      final threshold = math.max(2.5 * 1.4826 * mad, math.log(1.8));
      keep = [for (final x in xs) (x - m).abs() <= threshold];
    }

    var sw = 0.0, swx = 0.0, effective = 0.0;
    var count = 0;
    for (var i = 0; i < n; i++) {
      if (!keep[i]) continue;
      sw += ws[i];
      swx += ws[i] * xs[i];
      effective += obs[i].weight;
      count++;
    }
    if (sw <= 0) return null;
    final mean = swx / sw;
    var swr = 0.0;
    for (var i = 0; i < n; i++) {
      if (!keep[i]) continue;
      swr += ws[i] * (xs[i] - mean) * (xs[i] - mean);
    }
    // 記録が少ないうちは既定のばらつき(sigmaPrior)に寄せる
    final variance =
        (sigmaPrior * sigmaPrior + swr) / (1 + math.max(sw - 1, 0));
    return _Estimate(
      days: math.exp(mean),
      sigma: math.sqrt(variance).clamp(0.08, 1.2).toDouble(),
      count: count,
      effectiveCount: effective,
    );
  }
}

class _Ev {
  final DateTime at;
  final ForecastLevel level;

  /// 補充日として信頼できない（初回の記録・一括リセット）
  final bool uncertain;

  /// 初期データの一斉登録・全データリセット（複数アイテムが同時刻に「買ったばっかり」）
  final bool bulk;

  /// 購入記録から補充時刻を補正した
  final bool fromPurchase;

  /// アプリ上は記録されていないが購入記録から補充を推定した
  final bool inferred;

  const _Ev(
    this.at,
    this.level, {
    this.uncertain = false,
    this.bulk = false,
    this.fromPurchase = false,
    this.inferred = false,
  });
}

class _Cycle {
  final DateTime start;
  final bool startUncertain;
  final bool startBulk;
  final bool fromPurchase;
  final bool inferred;
  final Duration? waitBefore;
  DateTime? low;
  DateTime? empty;
  DateTime? end;

  _Cycle({
    required this.start,
    required this.startUncertain,
    required this.startBulk,
    required this.fromPurchase,
    required this.inferred,
    required this.waitBefore,
  });
}

class _Obs {
  final double days;
  final double weight;

  /// 起点が初回の記録・一括リセット
  final bool uncertain;

  /// 起点が初期データの一斉登録・全データリセット
  final bool bulk;
  const _Obs(
    this.days,
    this.weight, {
    this.uncertain = false,
    this.bulk = false,
  });
}

class _Estimate {
  final double days;

  /// 対数スケールでのばらつき
  final double sigma;
  final int count;
  final double effectiveCount;

  const _Estimate({
    required this.days,
    required this.sigma,
    required this.count,
    required this.effectiveCount,
  });
}

double _days(Duration d) => d.inSeconds / 86400.0;

Duration _duration(double days) => Duration(seconds: (days * 86400).round());

double _median(List<double> values) {
  final s = [...values]..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

double _weightedMedian(List<double> xs, List<double> ws) {
  final idx = List<int>.generate(xs.length, (i) => i)
    ..sort((a, b) => xs[a].compareTo(xs[b]));
  final total = ws.fold<double>(0, (a, b) => a + b);
  var acc = 0.0;
  for (final i in idx) {
    acc += ws[i];
    if (acc >= total / 2) return xs[i];
  }
  return xs[idx.last];
}
