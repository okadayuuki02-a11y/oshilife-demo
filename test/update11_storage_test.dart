import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshilife/models/activity_models.dart';
import 'package:oshilife/models/oshi.dart';
import 'package:oshilife/models/oshi_event.dart';
import 'package:oshilife/services/activity_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('旧版データを読み込み、新項目と日付を保存できる', () {
    final oldOshi = Oshi.fromJson({
      'id': '1',
      'name': 'ひより',
      'groupName': 'Lumière Palette',
    });
    expect(oldOshi.furigana, '');
    oldOshi.furigana = 'ほしのひより';
    oldOshi.birthday = DateTime(2000, 10, 9);
    expect(Oshi.fromJson(oldOshi.toJson()).birthday?.day, 9);

    final oldEvent = OshiEvent.fromJson({
      'id': 'event',
      'title': 'ライブ',
      'date': '2026-09-29T00:00:00',
      'venue': '会場',
    });
    expect(oldEvent.drinkRequired, false);
    final event = oldEvent.copyWith(drinkRequired: true, drinkAmount: 600);
    expect(OshiEvent.fromJson(event.toJson()).drinkAmount, 600);

    final oldTalk = TalkLog.fromJson({
      'id': 'talk',
      'eventId': 'event',
      'sessionLabel': '1部',
      'messages': [
        {'speaker': '自分', 'text': 'こんにちは', 'order': 0},
      ],
    });
    expect(oldTalk.messages.single.kind, TalkEntryKind.self);
    expect(TalkLog.fromJson(oldTalk.toJson()).sessionLabel, '1部');
  });

  test('複数の個別チェキを一括保存して、それぞれの写真と金額を保持する', () async {
    SharedPreferences.setMockInitialValues({});
    final records = [
      ChekiRecord(
        eventId: 'event',
        purchaseId: 'purchase',
        type: ChekiType.solo,
        imageBase64: 'photo-a',
        amount: 1000,
      ),
      ChekiRecord(
        eventId: 'event',
        purchaseId: 'purchase',
        type: ChekiType.twoShotSigned,
        imageBase64: 'photo-b',
        amount: 2000,
      ),
    ];
    await ActivityStorage.saveChekiBatch(records);
    final saved = await ActivityStorage.loadChekis();
    expect(saved.map((e) => e.imageBase64), ['photo-a', 'photo-b']);
    expect(saved.map((e) => e.amount), [1000, 2000]);
    expect(saved.map((e) => e.id).toSet().length, 2);
  });
}
