import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/oshi_event.dart';

class EventStorage {
  static const _key = 'oshilife_events_v1';

  static Future<List<OshiEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      var needsMigration = false;
      final events = <OshiEvent>[];
      for (final item in decoded.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final rawId = map['id'];
        if (rawId is! String || rawId.trim().isEmpty) {
          needsMigration = true;
        }
        events.add(OshiEvent.fromJson(map));
      }

      // update08以前のイベントにはIDが無いため、update09初回起動時に
      // 一度だけID付きデータへ保存し直して関連データの紐付けを安定させる。
      if (needsMigration) {
        final migrated = jsonEncode(events.map((event) => event.toJson()).toList());
        await prefs.setString(_key, migrated);
      }

      return events;
    } catch (error, stackTrace) {
      debugPrint('EventStorage.loadEvents failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  static Future<void> saveEvents(List<OshiEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(events.map((event) => event.toJson()).toList());
    final saved = await prefs.setString(_key, raw);
    if (!saved) {
      throw StateError('イベントの保存に失敗しました。');
    }
  }
}
