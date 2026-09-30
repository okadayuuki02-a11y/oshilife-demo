import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/oshi_event.dart';

/// 画像解析の呼び出し元が、特定のAI/OCR実装に依存しないための共通窓口。
/// 将来はクラウドAI、端末内AI、OCR+ルール判定などへ差し替え可能。
abstract class ImageAnalysisEngine {
  const ImageAnalysisEngine();

  Future<ProfileImageAnalysis> analyzeProfile(Uint8List bytes);

  Future<EventImageAnalysis> analyzeEvent(Uint8List bytes);
}

class ImageAnalysisUnavailable implements Exception {
  const ImageAnalysisUnavailable([
    this.message = 'AI画像解析サービスがまだ接続されていません。',
  ]);

  final String message;

  @override
  String toString() => message;
}

class ProfileImageAnalysis {
  const ProfileImageAnalysis({
    this.name = '',
    this.groupName = '',
    this.furigana = '',
    this.nickname = '',
    this.birthday = '',
    this.hometown = '',
    this.height = '',
    this.hobby = '',
    this.skill = '',
    this.likes = '',
    this.officialUrl = '',
    this.memberColor = '',
    this.confidence = const <String, double>{},
  });

  final String name;
  final String groupName;
  final String furigana;
  final String nickname;
  final String birthday;
  final String hometown;
  final String height;
  final String hobby;
  final String skill;
  final String likes;
  final String officialUrl;
  final String memberColor;
  final Map<String, double> confidence;
}

class EventImageAnalysis {
  const EventImageAnalysis({
    this.title = '',
    this.date,
    this.venue = '',
    this.openTime,
    this.startTime,
    this.endTime,
    this.performers = const <String>[],
    this.price,
    this.url = '',
    this.schedule = const <EventScheduleEntry>[],
    this.confidence = const <String, double>{},
  });

  final String title;
  final DateTime? date;
  final String venue;
  final TimeOfDay? openTime;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<String> performers;
  final int? price;
  final String url;
  final List<EventScheduleEntry> schedule;
  final Map<String, double> confidence;
}

class PendingAiImageAnalysisEngine extends ImageAnalysisEngine {
  const PendingAiImageAnalysisEngine();

  @override
  Future<ProfileImageAnalysis> analyzeProfile(Uint8List bytes) {
    throw const ImageAnalysisUnavailable(
      '旧OCRは精度不足のため停止中です。プロフィールはAI画像解析方式へ切り替えます。',
    );
  }

  @override
  Future<EventImageAnalysis> analyzeEvent(Uint8List bytes) {
    throw const ImageAnalysisUnavailable(
      'イベント画像はAI画像解析方式へ切り替え中です。告知・タイテを同じ解析基盤で扱う予定です。',
    );
  }
}

class ImageAnalysisService {
  ImageAnalysisService._();

  static ImageAnalysisEngine engine = const PendingAiImageAnalysisEngine();

  static Future<ProfileImageAnalysis> analyzeProfile(Uint8List bytes) =>
      engine.analyzeProfile(bytes);

  static Future<EventImageAnalysis> analyzeEvent(Uint8List bytes) =>
      engine.analyzeEvent(bytes);
}

String? memberColorHexFromAnalysis(String value) {
  final text = value.toLowerCase();
  const colors = <String, String>{
    '水色': '#63C7E8',
    'ライトブルー': '#63C7E8',
    '青': '#4A77E8',
    'ブルー': '#4A77E8',
    '赤': '#EF5350',
    'レッド': '#EF5350',
    'ピンク': '#F06292',
    '紫': '#9B5CFF',
    'パープル': '#9B5CFF',
    '黄': '#F4C542',
    '黄色': '#F4C542',
    '緑': '#4CAF72',
    'グリーン': '#4CAF72',
    'オレンジ': '#F59A45',
    '橙': '#F59A45',
    '白': '#F5F5F5',
    '黒': '#424242',
  };
  for (final entry in colors.entries) {
    if (text.contains(entry.key.toLowerCase())) return entry.value;
  }
  return null;
}
