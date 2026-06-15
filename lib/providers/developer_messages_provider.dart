import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/developer_message.dart';

final developerMessagesProvider =
    FutureProvider<List<DeveloperMessage>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/developer_messages.json');
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => DeveloperMessage.fromJson(e as Map<String, dynamic>))
      .toList();
});

class DeveloperMessagesReadNotifier extends AsyncNotifier<String?> {
  static const _key = 'last_read_developer_message_version';

  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> markLatestAsRead(String version) async {
    if (state.value == version) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, version);
    state = AsyncData(version);
  }
}

final developerMessagesReadProvider =
    AsyncNotifierProvider<DeveloperMessagesReadNotifier, String?>(
        DeveloperMessagesReadNotifier.new);

final hasUnreadDeveloperMessageProvider = Provider<bool>((ref) {
  final messages = ref.watch(developerMessagesProvider).value;
  final lastRead = ref.watch(developerMessagesReadProvider).value;
  if (messages == null || messages.isEmpty) return false;
  return messages.first.version != lastRead;
});
