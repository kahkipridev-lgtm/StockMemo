import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/developer_message.dart';

final developerMessagesProvider =
    FutureProvider<List<DeveloperMessage>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/developer_messages.json');
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => DeveloperMessage.fromJson(e as Map<String, dynamic>))
      .toList();
});
