import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/oshi.dart';

class OshiStorage {
  static const String _storageKey = 'oshilife_oshis_v2';

  static final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  // =========================================================
  // 推し一覧を保存
  // =========================================================

  static Future<void> saveOshis(
    List<Oshi> oshis,
  ) async {
    final jsonList = oshis
        .map(
          (oshi) => oshi.toJson(),
        )
        .toList();

    final jsonString =
        jsonEncode(jsonList);

    await _prefs.setString(
      _storageKey,
      jsonString,
    );

    // 開発中の確認用
    debugPrint(
      'OshiStorage 保存完了: ${oshis.length}人',
    );
  }

  // =========================================================
  // 保存されている推し一覧を読み込み
  // =========================================================

  static Future<List<Oshi>>
      loadOshis() async {
    final jsonString =
        await _prefs.getString(
      _storageKey,
    );

    if (jsonString == null ||
        jsonString.isEmpty) {
      debugPrint(
        'OshiStorage: 保存データなし',
      );

      return [];
    }

    try {
      final decoded =
          jsonDecode(jsonString);

      if (decoded is! List) {
        debugPrint(
          'OshiStorage: 保存形式が不正',
        );

        return [];
      }

      final oshis =
          decoded.map<Oshi>(
        (item) {
          return Oshi.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          );
        },
      ).toList();

      debugPrint(
        'OshiStorage 読込完了: ${oshis.length}人',
      );

      return oshis;
    } catch (e, stackTrace) {
      debugPrint(
        'OshiStorage 読込エラー: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      return [];
    }
  }

  // =========================================================
  // 保存データ削除
  // =========================================================

  static Future<void>
      clearOshis() async {
    await _prefs.remove(
      _storageKey,
    );

    debugPrint(
      'OshiStorage: 保存データ削除',
    );
  }

  // =========================================================
  // 保存確認用
  // =========================================================

  static Future<bool>
      hasSavedData() async {
    final value =
        await _prefs.getString(
      _storageKey,
    );

    return value != null &&
        value.isNotEmpty;
  }
}