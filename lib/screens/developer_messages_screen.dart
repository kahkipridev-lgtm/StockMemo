import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/developer_message.dart';
import '../providers/developer_messages_provider.dart';

final _urlPattern = RegExp(r'https?://[^\s)]+');

class DeveloperMessagesScreen extends ConsumerWidget {
  const DeveloperMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(developerMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('開発者からのメッセージ'),
        centerTitle: true,
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (messages) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, index) => _MessageCard(message: messages[index]),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final DeveloperMessage message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${message.version}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                children: _bodySpans(message.body, colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _bodySpans(String body, Color linkColor) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _urlPattern.allMatches(body)) {
      if (match.start > start) {
        spans.add(TextSpan(text: body.substring(start, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(color: linkColor, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
      );
      start = match.end;
    }
    if (start < body.length) {
      spans.add(TextSpan(text: body.substring(start)));
    }
    return spans;
  }
}
