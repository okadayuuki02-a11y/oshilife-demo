import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshilife/models/activity_models.dart';
import 'package:oshilife/models/oshi.dart';
import 'package:oshilife/models/oshi_event.dart';

void main() {
  test('特典会の参加枠をJSON保存・復元できる', () {
    final event = OshiEvent(
      title: '握手会 12/20',
      date: DateTime(2026, 12, 20),
      venue: '幕張メッセ',
      type: OshiEventType.specialEvent,
      specialFormat: SpecialEventFormat.faceToFace,
      specialActivities: const [SpecialActivityType.handshake],
      participationSlots: [
        EventParticipationSlot(
          memberName: 'テストメンバー',
          partLabel: '第2部',
          activityType: SpecialActivityType.handshake,
          startTime: const TimeOfDay(hour: 12, minute: 0),
          endTime: const TimeOfDay(hour: 13, minute: 15),
          receptionEndTime: const TimeOfDay(hour: 12, minute: 50),
          ownedCount: 3,
          usedCount: 1,
          status: ParticipationSlotStatus.pending,
          laneOrChannel: '12レーン',
        ),
      ],
    );

    final restored = OshiEvent.fromJson(event.toJson());
    expect(restored.type, OshiEventType.specialEvent);
    expect(restored.specialActivities, contains(SpecialActivityType.handshake));
    expect(restored.participationSlots.single.partLabel, '第2部');
    expect(restored.participationSlots.single.owned, 3);
    expect(restored.participationSlots.single.remainingCount, 2);
    expect(restored.participationSlots.single.receptionEndTime?.minute, 50);
  });

  test('旧特典会ステータスは未参加へ移行する', () {
    final restored = EventParticipationSlot.fromJson({
      'id': 'slot_old',
      'status': 'paid',
      'ownedCount': 5,
    });
    expect(restored.status, ParticipationSlotStatus.pending);
    expect(restored.owned, 5);
  });

  test('トークログに参加枠IDを保持できる', () {
    final talk = TalkLog(
      eventId: 'event_1',
      participationSlotId: 'slot_1',
      participantNames: ['テストメンバー'],
      sessionLabel: '第2部 握手会',
      ticketCount: 3,
    );
    final restored = TalkLog.fromJson(talk.toJson());
    expect(restored.participationSlotId, 'slot_1');
    expect(restored.ticketCount, 3);
  });

  test('1件の支出を複数イベントへ配分できる', () {
    final transaction = OshiTransaction(
      amount: 50000,
      date: DateTime(2026, 9, 10),
      category: TransactionCategory.ticket,
      eventAllocations: [
        EventAllocation(eventId: 'tokyo', amount: 20000),
        EventAllocation(eventId: 'osaka', amount: 10000),
        EventAllocation(eventId: 'fukuoka', amount: 15000),
      ],
    );
    expect(transaction.amountForEvent('tokyo'), 20000);
    expect(transaction.amountForEvent('osaka'), 10000);
    expect(transaction.allocatedAmount, 45000);
    expect(transaction.unallocatedAmount, 5000);
  });

  test('年なし誕生日の表示文字を保持できる', () {
    final oshi = Oshi(
      id: 'oshi_1',
      name: '星野ひより',
      groupName: 'Lumière Palette',
      birthdayText: '4月12日',
    );
    final restored = Oshi.fromJson(oshi.toJson());
    expect(restored.birthdayText, '4月12日');
  });
}
