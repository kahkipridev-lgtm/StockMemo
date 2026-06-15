import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';

const _kSupportUrl = 'https://kahkipridev-lgtm.github.io/StockMemo/';
const _kPrivacyUrl = 'https://kahkipridev-lgtm.github.io/StockMemo/privacy.html';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (settings) => ListView(
          children: [
            _SectionHeader(title: '表示'),
            _ThemeSetting(settings: settings),
            _SortSetting(settings: settings),
            const Divider(),
            _SectionHeader(title: 'データ管理'),
            _ResetStockTile(),
            _RestoreDefaultsTile(),
            const Divider(),
            _SectionHeader(title: 'アプリについて'),
            const _DeveloperMessagesTile(),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('バージョン'),
              trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
            ),
            const _LinkTile(
              icon: Icons.help_outline_rounded,
              title: 'サポート',
              url: _kSupportUrl,
            ),
            const _LinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'プライバシーポリシー',
              url: _kPrivacyUrl,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThemeSetting extends ConsumerWidget {
  final AppSettings settings;
  const _ThemeSetting({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('テーマ'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_rounded, size: 18),
            label: Text('ライト'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_rounded, size: 18),
            label: Text('ダーク'),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.settings_rounded, size: 18),
            label: Text('自動'),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (value) {
          ref
              .read(settingsProvider.notifier)
              .updateThemeMode(value.first);
        },
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _SortSetting extends ConsumerWidget {
  final AppSettings settings;
  const _SortSetting({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.sort_rounded),
      title: const Text('デフォルトのソート順'),
      trailing: DropdownButton<SortOrder>(
        value: settings.defaultSortOrder,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: SortOrder.alphabetical,
            child: Text('50音順'),
          ),
          DropdownMenuItem(
            value: SortOrder.stockLevel,
            child: Text('残量順'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            ref
                .read(settingsProvider.notifier)
                .updateDefaultSortOrder(value);
          }
        },
      ),
    );
  }
}

Future<bool> _showConfirmDialog(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  Color? confirmColor,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('確認'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

class _ResetStockTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.refresh_rounded, color: Colors.orange),
      title: const Text('全データをリセット'),
      subtitle: const Text('全アイテムを「買ったばっかり」に戻す'),
      onTap: () async {
        final confirmed = await _showConfirmDialog(
          context,
          message: '全アイテムの残量を「買ったばっかり」にリセットしますか？',
          confirmLabel: 'リセット',
          confirmColor: Colors.orange,
        );
        if (confirmed) {
          await ref.read(inventoryProvider.notifier).resetAllToFull();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('全アイテムをリセットしました')),
            );
          }
        }
      },
    );
  }
}

class _RestoreDefaultsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.restore_rounded, color: Colors.blue),
      title: const Text('デフォルトアイテムを復元'),
      subtitle: const Text('削除したデフォルトアイテムを再登録する'),
      onTap: () async {
        final confirmed = await _showConfirmDialog(
          context,
          message: '削除済みのデフォルトアイテムを復元しますか？\n既存のアイテムには影響しません。',
          confirmLabel: '復元',
        );
        if (confirmed) {
          await ref.read(inventoryProvider.notifier).restoreDefaults();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('デフォルトアイテムを復元しました')),
            );
          }
        }
      },
    );
  }
}

class _DeveloperMessagesTile extends StatelessWidget {
  const _DeveloperMessagesTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.campaign_outlined),
      title: const Text('開発者からのメッセージ'),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {
        Navigator.of(context).pushNamed('/developer_messages');
      },
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.grey),
      onTap: () async {
        final uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ページを開けませんでした')),
            );
          }
        }
      },
    );
  }
}
