import 'dart:convert';

String newActivityId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

enum TicketStatus { unset, applying, wonUnpaid, paid, lost, refunded }

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.unset:
        return '未設定';
      case TicketStatus.applying:
        return '申込中';
      case TicketStatus.wonUnpaid:
        return '当選未決済';
      case TicketStatus.paid:
        return '支払済';
      case TicketStatus.lost:
        return '落選';
      case TicketStatus.refunded:
        return '払戻';
    }
  }
}

class TicketRecord {
  TicketRecord({
    String? id,
    required this.eventId,
    this.status = TicketStatus.unset,
    this.amount,
    this.serialNumber = '',
    this.paymentDeadline,
    this.memo = '',
    this.url = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newActivityId('ticket'),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String eventId;
  TicketStatus status;
  int? amount;
  String serialNumber;
  DateTime? paymentDeadline;
  String memo;
  String url;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'status': status.name,
    'amount': amount,
    'serialNumber': serialNumber,
    'paymentDeadline': paymentDeadline?.toIso8601String(),
    'memo': memo,
    'url': url,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TicketRecord.fromJson(Map<String, dynamic> json) => TicketRecord(
    id: json['id'] as String?,
    eventId: json['eventId'] as String? ?? '',
    status: TicketStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => TicketStatus.unset,
    ),
    amount: (json['amount'] as num?)?.toInt(),
    serialNumber: json['serialNumber'] as String? ?? '',
    paymentDeadline: DateTime.tryParse(
      json['paymentDeadline'] as String? ?? '',
    ),
    memo: json['memo'] as String? ?? '',
    url: json['url'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

enum ChekiType {
  solo,
  soloSigned,
  soloTalk,
  twoShot,
  twoShotSigned,
  twoShotTalk,
  signTicket,
  talkTicket,
  group,
  other,
}

extension ChekiTypeX on ChekiType {
  String get label {
    switch (this) {
      case ChekiType.solo:
        return 'ソロ（サインなし）';
      case ChekiType.soloSigned:
        return 'ソロ（サインあり）';
      case ChekiType.soloTalk:
        return 'ソロ（トークあり）';
      case ChekiType.twoShot:
        return '2S（サインなし）';
      case ChekiType.twoShotSigned:
        return '2S（サインあり）';
      case ChekiType.twoShotTalk:
        return '2S（トークあり）';
      case ChekiType.signTicket:
        return 'サイン券';
      case ChekiType.talkTicket:
        return 'トーク券';
      case ChekiType.group:
        return '複数人';
      case ChekiType.other:
        return 'その他';
    }
  }
}

class ChekiSourcePhoto {
  ChekiSourcePhoto({
    String? id,
    required this.eventId,
    required this.imageBase64,
    this.detectedCount,
    this.isSplit = false,
    DateTime? createdAt,
  }) : id = id ?? newActivityId('cheki_source'),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String eventId;
  final String imageBase64;
  final int? detectedCount;
  final bool isSplit;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'imageBase64': imageBase64,
    'detectedCount': detectedCount,
    'isSplit': isSplit,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChekiSourcePhoto.fromJson(Map<String, dynamic> json) =>
      ChekiSourcePhoto(
        id: json['id'] as String?,
        eventId: json['eventId'] as String? ?? '',
        imageBase64: json['imageBase64'] as String? ?? '',
        detectedCount: (json['detectedCount'] as num?)?.toInt(),
        isSplit: json['isSplit'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

class ChekiPurchase {
  ChekiPurchase({
    String? id,
    required this.eventId,
    this.quantity = 1,
    this.totalAmount,
    this.purchasedAt,
    this.sourcePhotoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newActivityId('cheki_purchase'),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String eventId;
  int quantity;
  int? totalAmount;
  DateTime? purchasedAt;
  String? sourcePhotoId;
  final DateTime createdAt;
  DateTime updatedAt;

  int? get unitPrice {
    if (totalAmount == null || quantity <= 0) return null;
    return (totalAmount! / quantity).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'quantity': quantity,
    'totalAmount': totalAmount,
    'purchasedAt': purchasedAt?.toIso8601String(),
    'sourcePhotoId': sourcePhotoId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChekiPurchase.fromJson(Map<String, dynamic> json) => ChekiPurchase(
    id: json['id'] as String?,
    eventId: json['eventId'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    totalAmount: (json['totalAmount'] as num?)?.toInt(),
    purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? ''),
    sourcePhotoId: json['sourcePhotoId'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

class ChekiRecord {
  ChekiRecord({
    String? id,
    required this.eventId,
    required this.purchaseId,
    this.sourcePhotoId,
    this.participationSlotId,
    this.shotAt,
    List<String>? memberNames,
    this.type = ChekiType.twoShot,
    this.imageBase64,
    this.amount,
    this.memo = '',
    this.isFavorite = false,
    List<String>? talkLogIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newActivityId('cheki'),
       memberNames = memberNames ?? <String>[],
       talkLogIds = talkLogIds ?? <String>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String eventId;
  final String purchaseId;
  String? sourcePhotoId;
  String? participationSlotId;
  DateTime? shotAt;
  List<String> memberNames;
  ChekiType type;
  String? imageBase64;
  int? amount;
  String memo;
  bool isFavorite;
  List<String> talkLogIds;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'purchaseId': purchaseId,
    'sourcePhotoId': sourcePhotoId,
    'participationSlotId': participationSlotId,
    'shotAt': shotAt?.toIso8601String(),
    'memberNames': memberNames,
    'type': type.name,
    'imageBase64': imageBase64,
    'amount': amount,
    'memo': memo,
    'isFavorite': isFavorite,
    'talkLogIds': talkLogIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChekiRecord.fromJson(Map<String, dynamic> json) => ChekiRecord(
    id: json['id'] as String?,
    eventId: json['eventId'] as String? ?? '',
    purchaseId: json['purchaseId'] as String? ?? '',
    sourcePhotoId: json['sourcePhotoId'] as String?,
    participationSlotId: json['participationSlotId'] as String?,
    shotAt: DateTime.tryParse(json['shotAt'] as String? ?? ''),
    memberNames: _stringList(json['memberNames']),
    type: ChekiType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => ChekiType.twoShot,
    ),
    imageBase64: json['imageBase64'] as String?,
    amount: (json['amount'] as num?)?.toInt(),
    memo: json['memo'] as String? ?? '',
    isFavorite: json['isFavorite'] as bool? ?? false,
    talkLogIds: _stringList(json['talkLogIds']),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

enum TalkEntryKind { self, member, action, thought, system }

class TalkMessage {
  TalkMessage({
    String? id,
    required this.speaker,
    required this.text,
    required this.order,
    this.kind = TalkEntryKind.member,
    DateTime? createdAt,
  }) : id = id ?? newActivityId('talk_message'),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  String speaker;
  String text;
  int order;
  TalkEntryKind kind;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'speaker': speaker,
    'text': text,
    'order': order,
    'kind': kind.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TalkMessage.fromJson(Map<String, dynamic> json) => TalkMessage(
    id: json['id'] as String?,
    speaker: json['speaker'] as String? ?? '自分',
    text: json['text'] as String? ?? '',
    order: (json['order'] as num?)?.toInt() ?? 0,
    kind: TalkEntryKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () =>
          json['speaker'] == '自分' ? TalkEntryKind.self : TalkEntryKind.member,
    ),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}

class TalkLog {
  TalkLog({
    String? id,
    this.eventId = '',
    this.eventName = '',
    this.participationSlotId,
    List<String>? participantNames,
    DateTime? talkedAt,
    this.sessionLabel = '',
    this.ticketCount,
    List<String>? chekiIds,
    List<String>? imagesBase64,
    this.memo = '',
    List<TalkMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newActivityId('talk'),
       participantNames = participantNames ?? <String>[],
       talkedAt = talkedAt ?? DateTime.now(),
       chekiIds = chekiIds ?? <String>[],
       imagesBase64 = imagesBase64 ?? <String>[],
       messages = messages ?? <TalkMessage>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String eventId;
  String eventName;
  String? participationSlotId;
  List<String> participantNames;
  DateTime talkedAt;
  String sessionLabel;
  int? ticketCount;
  List<String> chekiIds;
  List<String> imagesBase64;
  String memo;
  List<TalkMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  int get messageCount => messages.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'eventName': eventName,
    'participationSlotId': participationSlotId,
    'participantNames': participantNames,
    'talkedAt': talkedAt.toIso8601String(),
    'sessionLabel': sessionLabel,
    'ticketCount': ticketCount,
    'chekiIds': chekiIds,
    'imagesBase64': imagesBase64,
    'memo': memo,
    'messages': messages.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TalkLog.fromJson(Map<String, dynamic> json) => TalkLog(
    id: json['id'] as String?,
    eventId: json['eventId'] as String? ?? '',
    eventName: json['eventName'] as String? ?? '',
    participationSlotId: json['participationSlotId'] as String?,
    participantNames: _stringList(json['participantNames']),
    talkedAt:
        DateTime.tryParse(json['talkedAt'] as String? ?? '') ?? DateTime.now(),
    sessionLabel: json['sessionLabel'] as String? ?? '',
    ticketCount: (json['ticketCount'] as num?)?.toInt(),
    chekiIds: _stringList(json['chekiIds']),
    imagesBase64: _stringList(json['imagesBase64']),
    memo: json['memo'] as String? ?? '',
    messages: _mapList(json['messages']).map(TalkMessage.fromJson).toList(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

enum TransactionType { expense, income, refund, adjustment }

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.expense:
        return '支出';
      case TransactionType.income:
        return '収入';
      case TransactionType.refund:
        return '返金';
      case TransactionType.adjustment:
        return '調整';
    }
  }

  int get sign {
    switch (this) {
      case TransactionType.expense:
        return -1;
      case TransactionType.income:
      case TransactionType.refund:
      case TransactionType.adjustment:
        return 1;
    }
  }
}

enum TransactionCategory {
  ticket,
  cheki,
  goods,
  transport,
  hotel,
  food,
  fanclub,
  income,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.ticket:
        return 'チケット';
      case TransactionCategory.cheki:
        return 'チェキ・特典会';
      case TransactionCategory.goods:
        return 'グッズ';
      case TransactionCategory.transport:
        return '交通費';
      case TransactionCategory.hotel:
        return '宿泊費';
      case TransactionCategory.food:
        return '飲食費';
      case TransactionCategory.fanclub:
        return 'ファンクラブ';
      case TransactionCategory.income:
        return '推し活資金';
      case TransactionCategory.other:
        return 'その他';
    }
  }
}


class EventAllocation {
  EventAllocation({
    required this.eventId,
    required this.amount,
  });

  final String eventId;
  final int amount;

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'amount': amount,
  };

  factory EventAllocation.fromJson(Map<String, dynamic> json) => EventAllocation(
    eventId: json['eventId'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
  );
}

class OshiTransaction {
  OshiTransaction({
    String? id,
    this.type = TransactionType.expense,
    required this.amount,
    DateTime? date,
    this.category = TransactionCategory.other,
    this.paymentMethod = '',
    this.eventId,
    List<EventAllocation>? eventAllocations,
    List<String>? memberNames,
    this.memo = '',
    this.sourceType,
    this.sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newActivityId('txn'),
       date = date ?? DateTime.now(),
       eventAllocations = eventAllocations ?? <EventAllocation>[],
       memberNames = memberNames ?? <String>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  TransactionType type;
  int amount;
  DateTime date;
  TransactionCategory category;
  String paymentMethod;
  String? eventId;
  List<EventAllocation> eventAllocations;
  List<String> memberNames;
  String memo;
  String? sourceType;
  String? sourceId;
  final DateTime createdAt;
  DateTime updatedAt;

  int get signedAmount => amount * type.sign;

  int amountForEvent(String targetEventId) {
    final allocated = eventAllocations
        .where((item) => item.eventId == targetEventId)
        .fold<int>(0, (sum, item) => sum + item.amount);
    if (allocated > 0) return allocated;
    return eventId == targetEventId ? amount : 0;
  }

  bool isLinkedToEvent(String targetEventId) => amountForEvent(targetEventId) > 0;

  int get allocatedAmount =>
      eventAllocations.fold<int>(0, (sum, item) => sum + item.amount);

  int get unallocatedAmount {
    final value = amount - allocatedAmount;
    return value < 0 ? 0 : value;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.name,
    'paymentMethod': paymentMethod,
    'eventId': eventId,
    'eventAllocations': eventAllocations.map((e) => e.toJson()).toList(),
    'memberNames': memberNames,
    'memo': memo,
    'sourceType': sourceType,
    'sourceId': sourceId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory OshiTransaction.fromJson(Map<String, dynamic> json) =>
      OshiTransaction(
        id: json['id'] as String?,
        type: TransactionType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        category: TransactionCategory.values.firstWhere(
          (value) => value.name == json['category'],
          orElse: () => TransactionCategory.other,
        ),
        paymentMethod: json['paymentMethod'] as String? ?? '',
        eventId: json['eventId'] as String?,
        eventAllocations: _mapList(json['eventAllocations'])
            .map(EventAllocation.fromJson)
            .where((e) => e.eventId.isNotEmpty && e.amount > 0)
            .toList(),
        memberNames: _stringList(json['memberNames']),
        memo: json['memo'] as String? ?? '',
        sourceType: json['sourceType'] as String?,
        sourceId: json['sourceId'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

enum RecurringFrequency { monthly, yearly }

extension RecurringFrequencyX on RecurringFrequency {
  String get label {
    switch (this) {
      case RecurringFrequency.monthly:
        return '毎月';
      case RecurringFrequency.yearly:
        return '毎年';
    }
  }
}

class RecurringTransaction {
  RecurringTransaction({
    String? id,
    required this.name,
    this.type = TransactionType.expense,
    required this.amount,
    this.category = TransactionCategory.other,
    this.frequency = RecurringFrequency.monthly,
    this.dayOfMonth = 1,
    this.monthOfYear,
    DateTime? startDate,
    this.endDate,
    this.enabled = true,
    List<String>? memberNames,
    this.memo = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newActivityId('recurring'),
       startDate = startDate ?? DateTime.now(),
       memberNames = memberNames ?? <String>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  TransactionType type;
  int amount;
  TransactionCategory category;
  RecurringFrequency frequency;
  int dayOfMonth;
  int? monthOfYear;
  DateTime startDate;
  DateTime? endDate;
  bool enabled;
  List<String> memberNames;
  String memo;
  final DateTime createdAt;
  DateTime updatedAt;

  String get scheduleLabel {
    if (frequency == RecurringFrequency.yearly) {
      return '毎年${monthOfYear ?? startDate.month}月${dayOfMonth}日';
    }
    return '毎月${dayOfMonth}日';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'amount': amount,
    'category': category.name,
    'frequency': frequency.name,
    'dayOfMonth': dayOfMonth,
    'monthOfYear': monthOfYear,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'enabled': enabled,
    'memberNames': memberNames,
    'memo': memo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    final loadedType = TransactionType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => TransactionType.expense,
    );
    return RecurringTransaction(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '定期入出金',
      type: loadedType == TransactionType.income
          ? TransactionType.income
          : TransactionType.expense,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      category: TransactionCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => TransactionCategory.other,
      ),
      frequency: RecurringFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt() ?? 1,
      monthOfYear: (json['monthOfYear'] as num?)?.toInt(),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      enabled: json['enabled'] as bool? ?? true,
      memberNames: _stringList(json['memberNames']),
      memo: json['memo'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return <String>[];
  return value.whereType<String>().toList();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

String encodeJsonList(List<Map<String, dynamic>> values) => jsonEncode(values);
