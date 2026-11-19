import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock_level.dart';
import '../providers/forecast_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/purchase_log_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/stock_forecast.dart';
import '../utils/native_tab_bar.dart';
import '../widgets/kangaroo_icon.dart';

/// 在庫予測タブ: これまでの記録から、次に切れそうなものを提案する
class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen>
    with WidgetsBindingObserver {
  static const _soonColor = Color(0xFFC0392B);
  static const _weekColor = Color(0xFF9B6000);
  static const _laterColor = Color(0xFF357A45);
  static const _staleColor = Color(0xFF7A7A7A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 日付をまたいでアプリに戻ってきたときに「あと何日」を更新する
    if (state == AppLifecycleState.resumed) {
      ref.read(forecastClockProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(forecastProvider);
    final now = ref.watch(forecastClockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('在庫予測'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: '予測のしくみ',
            onPressed: () => _showHowItWorks(context),
          ),
        ],
      ),
      body: result == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, result, now),
    );
  }

  Widget _buildBody(BuildContext context, ForecastResult result, DateTime now) {
    final active = result.forecasts.where((f) => !f.isStale(now)).toList();
    final stale = result.forecasts.where((f) => f.isStale(now)).toList();
    final soon = active
        .where((f) => forecastDaysUntil(f, now) <= forecastSoonDays)
        .toList();
    final week = active
        .where(
          (f) =>
              forecastDaysUntil(f, now) > forecastSoonDays &&
              forecastDaysUntil(f, now) <= 7,
        )
        .toList();
    final later = active.where((f) => forecastDaysUntil(f, now) > 7).toList();
    final collectingCount = result.collectingItemIds.length;

    if (result.forecasts.isEmpty) {
      return _EmptyState(
        collectingCount: collectingCount,
        readiness: result.readiness,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _IntroCard(),
        if (soon.isNotEmpty)
          ..._section(
            label: 'そろそろ切れそう',
            icon: Icons.notification_important_rounded,
            color: _soonColor,
            forecasts: soon,
            now: now,
          ),
        if (week.isNotEmpty)
          ..._section(
            label: '1週間以内',
            icon: Icons.event_rounded,
            color: _weekColor,
            forecasts: week,
            now: now,
          ),
        if (later.isNotEmpty)
          ..._section(
            label: 'それ以降',
            icon: Icons.event_available_rounded,
            color: _laterColor,
            forecasts: later,
            now: now,
          ),
        if (stale.isNotEmpty)
          ..._section(
            label: '予測を大きく過ぎているもの',
            icon: Icons.history_toggle_off_rounded,
            color: _staleColor,
            forecasts: stale,
            now: now,
            note: '在庫切れ・買ったばっかりにし忘れていないか、タップして確認してみてください',
          ),
        if (collectingCount > 0) _CollectingNote(count: collectingCount),
      ],
    );
  }

  List<Widget> _section({
    required String label,
    required IconData icon,
    required Color color,
    required List<StockForecast> forecasts,
    required DateTime now,
    String? note,
  }) {
    return [
      _SectionHeader(icon: icon, label: label, color: color, note: note),
      for (final f in forecasts)
        _ForecastTile(
          key: ValueKey('${f.source.name}:${f.itemId ?? f.name}'),
          forecast: f,
          color: color,
          now: now,
        ),
    ];
  }

  void _showHowItWorks(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('予測のしくみ'),
        content: const SingleChildScrollView(
          child: Text(
            '「買ったばっかり」にしてから「在庫切れ」にするまでの日数を、アイテムごとに記録して予測しています。\n\n'
            '・連打や、すぐに直した誤タップは自動で無視します\n'
            '・買ったのに戻し忘れた・在庫切れにし忘れたような、極端に外れた記録は除外します\n'
            '・新しい記録ほど重視するので、使うペースが変わっても追従します\n'
            '・「残りわずか」にしたものは、その時点からの日数で予測し直します\n'
            '・買い物リストでチェックした記録も使います（在庫と同じ名前なら補充日の補正に、それ以外は購入間隔の予測に）\n\n'
            '記録が増えるほど予測の精度が上がります。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          KangarooIcon(size: 28, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'これまでの記録から、次に切れそうなものを予測しています',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? note;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ForecastTile extends ConsumerWidget {
  final StockForecast forecast;
  final Color color;
  final DateTime now;

  const _ForecastTile({
    super.key,
    required this.forecast,
    required this.color,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = forecast;
    final colorScheme = Theme.of(context).colorScheme;
    final subtle = colorScheme.onSurface.withValues(alpha: 0.6);
    final progress = f.progress(now).clamp(0.0, 1.0);
    final appLevel = appLevelOf(ref, f);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context, f, now),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        if (appLevel == StockLevel.low)
                          _Tag(
                            label: StockLevel.low.label,
                            color: StockLevel.low.color,
                          ),
                        if (f.source == ForecastSource.purchaseLog)
                          _Tag(label: '買い物メモ', color: subtle),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _remainingLabel(f, now),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typicalLabel(f)}・${_confidenceLabel(f.confidence)}',
                      style: TextStyle(fontSize: 12, color: subtle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _AddToListButton(forecast: f),
            ],
          ),
        ),
      ),
    );
  }
}

/// 買い物リストに追加するボタン（追加済み・残りわずかで既に表示中なら代わりにチェック表示）
class _AddToListButton extends ConsumerWidget {
  final StockForecast forecast;

  const _AddToListButton({required this.forecast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listKeys = ref.watch(shoppingListKeysProvider);
    final inList = listKeys.contains(normalizeForecastName(forecast.name));
    // 「残りわずか」「在庫切れ」のアイテムは買い物リストに表示されている
    // （購入記録から補充を推定した予測でも、アプリ上の状態で判定する）
    final appLevel = appLevelOf(ref, forecast);
    final shownAsLow =
        appLevel == StockLevel.low || appLevel == StockLevel.empty;

    if (inList || shownAsLow) {
      return Tooltip(
        message: '買い物リストに表示中',
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.playlist_add_check_rounded,
            color: const Color(0xFF2E7D32).withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.add_shopping_cart_rounded),
      color: Theme.of(context).colorScheme.primary,
      tooltip: '買い物リストに追加',
      onPressed: () {
        ref.read(shoppingListProvider.notifier).addItem(forecast.name);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('「${forecast.name}」を買い物リストに追加しました'),
              duration: const Duration(seconds: 2),
            ),
          );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int collectingCount;

  /// 最初の予測が表示されるまでの準備度（0〜1）
  final double readiness;

  const _EmptyState({required this.collectingCount, required this.readiness});

  /// 準備度がこれ以上になったら大人のカンガルーにする
  static const _grownUpReadiness = 0.5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtle = colorScheme.onSurface.withValues(alpha: 0.5);
    final grownUp = readiness >= _grownUpReadiness;
    final percent = (readiness * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // データが溜まるまでは子供のカンガルー、半分くらい溜まったら大人のカンガルー
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: KangarooIcon(
                key: ValueKey(grownUp),
                size: 96,
                baby: !grownUp,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              grownUp ? 'もう少しで予測できます' : 'まだ予測できる記録がありません',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              grownUp
                  ? '使い切ったら「在庫切れ」、買ってきたら「買ったばっかり」と記録を続けると、'
                        'もうすぐ次に切れそうな時期をここでお知らせします。'
                  : '在庫を「在庫切れ」→「買ったばっかり」と記録していくと、'
                        '次に切れそうな時期をここでお知らせします。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: readiness,
                      minHeight: 8,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '予測の準備 $percent%',
                    style: TextStyle(fontSize: 12, color: subtle),
                  ),
                ],
              ),
            ),
            if (collectingCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                '$collectingCount件のアイテムの記録を集めています',
                style: TextStyle(fontSize: 12, color: subtle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectingNote extends StatelessWidget {
  final int count;

  const _CollectingNote({required this.count});

  @override
  Widget build(BuildContext context) {
    final subtle = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 16, color: subtle),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'ほかに$count件は記録を集めています。'
              '「在庫切れ」→「買ったばっかり」を一度記録すると予測できるようになります。'
              '（在庫切れ中のものは買い物リストに表示されます）',
              style: TextStyle(fontSize: 12, color: subtle),
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime d) => '${d.month}/${d.day}';

String _remainingLabel(StockForecast f, DateTime now) {
  final days = forecastDaysUntil(f, now);
  if (days < 0) return '予測日を${-days}日過ぎています';
  if (days == 0) return '今日にも切れそう';
  if (days == 1) return '明日ごろ切れそう';
  return 'あと約$days日（${_date(f.predictedAt)}頃）';
}

String _daysText(double days) {
  final d = days.round();
  return d < 1 ? '1日' : '$d日';
}

String _typicalLabel(StockForecast f) => f.source == ForecastSource.purchaseLog
    ? '約${_daysText(f.typicalDays)}ごとに購入'
    : 'いつも約${_daysText(f.typicalDays)}で使い切り';

String _confidenceLabel(ForecastConfidence c) => switch (c) {
  ForecastConfidence.high => '精度 高',
  ForecastConfidence.medium => '精度 中',
  ForecastConfidence.low => '目安',
};

void _showDetail(BuildContext context, StockForecast f, DateTime now) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _DetailSheet(forecast: f, now: now),
  );
}

class _DetailSheet extends ConsumerWidget {
  final StockForecast forecast;
  final DateTime now;

  const _DetailSheet({required this.forecast, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = forecast;
    final subtle = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final isInventory = f.itemId != null;

    final String startLabel;
    if (f.source == ForecastSource.purchaseLog) {
      startLabel = '${_date(f.cycleStart)}に購入';
    } else if (f.restockInferredFromPurchase) {
      startLabel = '${_date(f.cycleStart)}に購入（購入記録から推定）';
    } else {
      startLabel = '${_date(f.cycleStart)}に補充';
    }

    final notes = <String>[
      if (f.basedOnLowMark) '「残りわずか」にした日を起点に予測しています。',
      if (f.restockInferredFromPurchase)
        '購入記録（買い物リストのチェックや「買ってきた」）から、補充済みとみなして予測しています。',
      if (f.isStale(now))
        '予測を大きく過ぎても記録がありません。在庫切れにし忘れていたり、買ったのに「買ったばっかり」に戻し忘れていませんか？',
      if (f.confidence == ForecastConfidence.low)
        '記録がまだ少ない・ばらつきが大きいため、目安としてご覧ください。',
    ];

    // 「買ってきた」は、押せば確実に予測し直されるときだけ出す。
    // アプリ上で残りわずか・在庫切れのものは状態を「買ったばっかり」に戻し、
    // 「買ったばっかり」のままのものは購入記録を付ける（エンジンが反映される時刻を返す）
    final appLevel = appLevelOf(ref, f);
    final restartFrom = f.purchaseRestartFrom;
    final canRecordPurchase =
        (appLevel != null && appLevel != StockLevel.full) ||
        (restartFrom != null && !now.isBefore(restartFrom));

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 13, color: subtle)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );

    // iOSのネイティブタブバーに隠れないよう、その高さ分の余白を空ける
    return Padding(
      padding: EdgeInsets.only(bottom: nativeTabBarInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              row(
                '切れる予測',
                '${_date(f.predictedAt)}頃（${_remainingLabel(f, now)}）',
              ),
              // 「目安」のときは幅が広すぎて参考にならないので出さない
              if (f.confidence != ForecastConfidence.low)
                row('予測の幅', '${_date(f.earliestAt)}〜${_date(f.latestAt)}'),
              row(
                f.source == ForecastSource.purchaseLog ? '購入の間隔' : 'いつもの日数',
                f.source == ForecastSource.purchaseLog
                    ? '約${_daysText(f.typicalDays)}ごと'
                    : '補充から約${_daysText(f.typicalDays)}で使い切り',
              ),
              row('起点', startLabel),
              row('使った記録', '${f.sampleCount}回分'),
              row('精度', _confidenceLabel(f.confidence)),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '※$n',
                      style: TextStyle(fontSize: 12, color: subtle),
                    ),
                  ),
              ],
              if (isInventory || canRecordPurchase) ...[
                const SizedBox(height: 20),
                Text(
                  '予測とちがうときは、いまの状態を教えてください',
                  style: TextStyle(fontSize: 12, color: subtle),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isInventory)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            StockLevel.empty.icon,
                            color: StockLevel.empty.color,
                          ),
                          label: const Text('もう切れた'),
                          onPressed: () => _markEmpty(context, ref),
                        ),
                      ),
                    if (isInventory && canRecordPurchase)
                      const SizedBox(width: 12),
                    if (canRecordPurchase)
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.shopping_bag_rounded),
                          label: const Text('買ってきた'),
                          onPressed: () =>
                              _recordPurchase(context, ref, appLevel),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _markEmpty(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    ref
        .read(inventoryProvider.notifier)
        .updateStockLevel(forecast.itemId!, StockLevel.empty);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('「${forecast.name}」を在庫切れにしました（買い物リストに表示されます）'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _recordPurchase(
    BuildContext context,
    WidgetRef ref,
    StockLevel? appLevel,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    if (forecast.itemId != null &&
        appLevel != null &&
        appLevel != StockLevel.full) {
      // アプリ上は残りわずか・在庫切れ → 買ってきたので「買ったばっかり」に戻す
      ref
          .read(inventoryProvider.notifier)
          .updateStockLevel(forecast.itemId!, StockLevel.full);
    } else {
      // 「買ったばっかり」のまま（在庫切れにし忘れ等）や買い物メモの品は、購入記録として残す。
      // 予測エンジンはこれを補充とみなして予測し直す（在庫アイテムはIDも残し、同名の別アイテムに付けない）
      ref
          .read(purchaseLogProvider.notifier)
          .logPurchase(forecast.name, itemId: forecast.itemId);
    }
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('「${forecast.name}」の購入を記録しました'),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
