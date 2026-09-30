import 'package:flutter/material.dart';

enum EventVisibility { shared, limited, private }

extension EventVisibilityX on EventVisibility {
  String get label {
    switch (this) {
      case EventVisibility.shared:
        return '共有';
      case EventVisibility.limited:
        return '限定公開';
      case EventVisibility.private:
        return '完全非公開';
    }
  }

  String get description {
    switch (this) {
      case EventVisibility.shared:
        return 'イベント名・日時・会場・出演者が、他のユーザーの検索にも表示されます。';
      case EventVisibility.limited:
        return 'イベントの存在は表示されますが、会場など一部情報は非公開になります。';
      case EventVisibility.private:
        return '自分の予定としてのみ保存され、他のユーザーには表示されません。';
    }
  }

  IconData get icon {
    switch (this) {
      case EventVisibility.shared:
        return Icons.public_rounded;
      case EventVisibility.limited:
        return Icons.visibility_off_rounded;
      case EventVisibility.private:
        return Icons.lock_rounded;
    }
  }
}

enum OshiEventType { solo, taiban, festival, specialEvent }

extension OshiEventTypeX on OshiEventType {
  String get label {
    switch (this) {
      case OshiEventType.solo:
        return '単独';
      case OshiEventType.taiban:
        return '対バン';
      case OshiEventType.festival:
        return 'フェス';
      case OshiEventType.specialEvent:
        return '特典会';
    }
  }
}



enum SpecialEventFormat { faceToFace, online, hybrid }

extension SpecialEventFormatX on SpecialEventFormat {
  String get label {
    switch (this) {
      case SpecialEventFormat.faceToFace:
        return '対面';
      case SpecialEventFormat.online:
        return 'オンライン';
      case SpecialEventFormat.hybrid:
        return '両方';
    }
  }
}

enum SpecialActivityType {
  talk,
  handshake,
  meetGreet,
  highTouch,
  oneShot,
  twoShot,
  threeShot,
  sign,
  other,
}

extension SpecialActivityTypeX on SpecialActivityType {
  String get label {
    switch (this) {
      case SpecialActivityType.talk:
        return 'お話会';
      case SpecialActivityType.handshake:
        return '握手会';
      case SpecialActivityType.meetGreet:
        return 'ミーグリ';
      case SpecialActivityType.highTouch:
        return 'ハイタッチ';
      case SpecialActivityType.oneShot:
        return '1ショット';
      case SpecialActivityType.twoShot:
        return '2ショット';
      case SpecialActivityType.threeShot:
        return '3ショット';
      case SpecialActivityType.sign:
        return 'サイン';
      case SpecialActivityType.other:
        return 'その他';
    }
  }

  bool get supportsPhoto =>
      this == SpecialActivityType.oneShot ||
      this == SpecialActivityType.twoShot ||
      this == SpecialActivityType.threeShot;
}

enum ParticipationSlotStatus {
  pending,
  attended,
  transferred,
  cancelled,

  // update12初版以前の保存データ互換用
  applying,
  wonUnpaid,
  paid,
  issued,
  lost,
}

extension ParticipationSlotStatusX on ParticipationSlotStatus {
  String get label {
    switch (this) {
      case ParticipationSlotStatus.pending:
        return '未参加';
      case ParticipationSlotStatus.attended:
        return '参加済';
      case ParticipationSlotStatus.transferred:
        return '振替';
      case ParticipationSlotStatus.cancelled:
        return '中止';
      case ParticipationSlotStatus.applying:
      case ParticipationSlotStatus.wonUnpaid:
      case ParticipationSlotStatus.paid:
      case ParticipationSlotStatus.issued:
      case ParticipationSlotStatus.lost:
        return '未参加';
    }
  }
}

class EventParticipationSlot {
  EventParticipationSlot({
    String? id,
    this.memberName = '',
    this.partLabel = '',
    this.activityType = SpecialActivityType.talk,
    this.startTime,
    this.endTime,
    this.receptionEndTime,
    this.appliedCount,
    this.wonCount,
    this.ownedCount,
    this.usedCount,
    this.status = ParticipationSlotStatus.pending,
    this.laneOrChannel = '',
    this.note = '',
    List<String>? imagesBase64,
  }) : id = id ?? 'slot_${DateTime.now().microsecondsSinceEpoch}',
       imagesBase64 = imagesBase64 ?? <String>[];

  final String id;
  final String memberName;
  final String partLabel;
  final SpecialActivityType activityType;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TimeOfDay? receptionEndTime;
  final int? appliedCount;
  final int? wonCount;
  final int? ownedCount;
  final int? usedCount;
  final ParticipationSlotStatus status;
  final String laneOrChannel;
  final String note;
  final List<String> imagesBase64;

  int get owned => ownedCount ?? 0;
  int get used => usedCount ?? 0;
  int get remainingCount {
    final value = owned - used;
    return value < 0 ? 0 : value;
  }

  EventParticipationSlot copyWith({
    String? id,
    String? memberName,
    String? partLabel,
    SpecialActivityType? activityType,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    TimeOfDay? receptionEndTime,
    int? appliedCount,
    int? wonCount,
    int? ownedCount,
    int? usedCount,
    ParticipationSlotStatus? status,
    String? laneOrChannel,
    String? note,
    List<String>? imagesBase64,
  }) {
    return EventParticipationSlot(
      id: id ?? this.id,
      memberName: memberName ?? this.memberName,
      partLabel: partLabel ?? this.partLabel,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      receptionEndTime: receptionEndTime ?? this.receptionEndTime,
      appliedCount: appliedCount ?? this.appliedCount,
      wonCount: wonCount ?? this.wonCount,
      ownedCount: ownedCount ?? this.ownedCount,
      usedCount: usedCount ?? this.usedCount,
      status: status ?? this.status,
      laneOrChannel: laneOrChannel ?? this.laneOrChannel,
      note: note ?? this.note,
      imagesBase64: imagesBase64 ?? this.imagesBase64,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberName': memberName,
    'partLabel': partLabel,
    'activityType': activityType.name,
    'startTime': _timeToJson(startTime),
    'endTime': _timeToJson(endTime),
    'receptionEndTime': _timeToJson(receptionEndTime),
    'appliedCount': appliedCount,
    'wonCount': wonCount,
    'ownedCount': ownedCount,
    'usedCount': usedCount,
    'status': status.name,
    'laneOrChannel': laneOrChannel,
    'note': note,
    'imagesBase64': imagesBase64,
  };

  factory EventParticipationSlot.fromJson(Map<String, dynamic> json) {
    return EventParticipationSlot(
      id: json['id'] as String?,
      memberName: json['memberName'] as String? ?? '',
      partLabel: json['partLabel'] as String? ?? '',
      activityType: SpecialActivityType.values.firstWhere(
        (value) => value.name == json['activityType'],
        orElse: () => SpecialActivityType.talk,
      ),
      startTime: _timeFromJson(json['startTime']),
      endTime: _timeFromJson(json['endTime']),
      receptionEndTime: _timeFromJson(json['receptionEndTime']),
      appliedCount: (json['appliedCount'] as num?)?.toInt(),
      wonCount: (json['wonCount'] as num?)?.toInt(),
      ownedCount: (json['ownedCount'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt(),
      status: _participationStatusFromJson(json['status']),
      laneOrChannel: json['laneOrChannel'] as String? ?? '',
      note: json['note'] as String? ?? '',
      imagesBase64: _stringList(json['imagesBase64']),
    );
  }
}

class EventScheduleEntry {
  const EventScheduleEntry({
    required this.title,
    this.startTime,
    this.endTime,
    this.label = 'ライブ',
    this.note,
    this.stage,
  });

  final String title;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String label;
  final String? note;
  final String? stage;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': _timeToJson(startTime),
      'endTime': _timeToJson(endTime),
      'label': label,
      'note': note,
      'stage': stage,
    };
  }

  factory EventScheduleEntry.fromJson(Map<String, dynamic> json) {
    return EventScheduleEntry(
      title: json['title'] as String? ?? '',
      startTime: _timeFromJson(json['startTime']),
      endTime: _timeFromJson(json['endTime']),
      label: json['label'] as String? ?? 'ライブ',
      note: json['note'] as String?,
      stage: json['stage'] as String?,
    );
  }
}

class OshiEvent {
  OshiEvent({
    String? id,
    required this.title,
    required this.date,
    required this.venue,
    this.type = OshiEventType.taiban,
    this.openTime,
    this.startTime,
    this.endTime,
    this.performers = const [],
    this.timetable = const [],
    this.primaryGroup,
    this.wantedGroups = const [],
    this.mySchedule = const [],
    this.ticketStatus = '未設定',
    this.ticketAmount,
    this.visibility = EventVisibility.shared,
    this.url = '',
    this.flyerBase64,
    this.memo = '',
    this.drinkRequired = false,
    this.drinkAmount,
    this.drinkMandatory = true,
    this.drinkIncluded = false,
    this.drinkMemo = '',
    this.specialFormat = SpecialEventFormat.faceToFace,
    this.specialActivities = const [],
    this.releaseName = '',
    this.serviceName = '',
    this.participationMethod = '',
    this.participationSlots = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? 'event_${DateTime.now().microsecondsSinceEpoch}',
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final DateTime date;
  final String venue;
  final OshiEventType type;
  final TimeOfDay? openTime;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<String> performers;

  // イベント参加者みんなで共有するタイムテーブル
  final List<EventScheduleEntry> timetable;

  // ここから下は自分専用の情報
  final String? primaryGroup;
  final List<String> wantedGroups;

  // 特典会など「自分の予定」として表示する追加スケジュール
  final List<EventScheduleEntry> mySchedule;

  // update08以前のデータ互換用。update09ではTicketRecordを正本として使う。
  final String ticketStatus;
  final int? ticketAmount;

  final EventVisibility visibility;
  final String url;
  final String? flyerBase64;
  final String memo;
  final bool drinkRequired;
  final int? drinkAmount;
  final bool drinkMandatory;
  final bool drinkIncluded;
  final String drinkMemo;

  // 地上系の握手会・お話会・ミーグリ・撮影会などをまとめて扱う情報
  final SpecialEventFormat specialFormat;
  final List<SpecialActivityType> specialActivities;
  final String releaseName;
  final String serviceName;
  final String participationMethod;
  final List<EventParticipationSlot> participationSlots;

  final DateTime createdAt;
  final DateTime updatedAt;

  OshiEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? venue,
    OshiEventType? type,
    TimeOfDay? openTime,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<String>? performers,
    List<EventScheduleEntry>? timetable,
    String? primaryGroup,
    List<String>? wantedGroups,
    List<EventScheduleEntry>? mySchedule,
    String? ticketStatus,
    int? ticketAmount,
    EventVisibility? visibility,
    String? url,
    String? flyerBase64,
    String? memo,
    bool? drinkRequired,
    int? drinkAmount,
    bool? drinkMandatory,
    bool? drinkIncluded,
    String? drinkMemo,
    SpecialEventFormat? specialFormat,
    List<SpecialActivityType>? specialActivities,
    String? releaseName,
    String? serviceName,
    String? participationMethod,
    List<EventParticipationSlot>? participationSlots,
  }) {
    return OshiEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      type: type ?? this.type,
      openTime: openTime ?? this.openTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      performers: performers ?? this.performers,
      timetable: timetable ?? this.timetable,
      primaryGroup: primaryGroup ?? this.primaryGroup,
      wantedGroups: wantedGroups ?? this.wantedGroups,
      mySchedule: mySchedule ?? this.mySchedule,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      ticketAmount: ticketAmount ?? this.ticketAmount,
      visibility: visibility ?? this.visibility,
      url: url ?? this.url,
      flyerBase64: flyerBase64 ?? this.flyerBase64,
      memo: memo ?? this.memo,
      drinkRequired: drinkRequired ?? this.drinkRequired,
      drinkAmount: drinkAmount ?? this.drinkAmount,
      drinkMandatory: drinkMandatory ?? this.drinkMandatory,
      drinkIncluded: drinkIncluded ?? this.drinkIncluded,
      drinkMemo: drinkMemo ?? this.drinkMemo,
      specialFormat: specialFormat ?? this.specialFormat,
      specialActivities: specialActivities ?? this.specialActivities,
      releaseName: releaseName ?? this.releaseName,
      serviceName: serviceName ?? this.serviceName,
      participationMethod: participationMethod ?? this.participationMethod,
      participationSlots: participationSlots ?? this.participationSlots,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'venue': venue,
      'type': type.name,
      'openTime': _timeToJson(openTime),
      'startTime': _timeToJson(startTime),
      'endTime': _timeToJson(endTime),
      'performers': performers,
      'timetable': timetable.map((entry) => entry.toJson()).toList(),
      'primaryGroup': primaryGroup,
      'wantedGroups': wantedGroups,
      'mySchedule': mySchedule.map((entry) => entry.toJson()).toList(),
      'ticketStatus': ticketStatus,
      'ticketAmount': ticketAmount,
      'visibility': visibility.name,
      'url': url,
      'flyerBase64': flyerBase64,
      'memo': memo,
      'drinkRequired': drinkRequired,
      'drinkAmount': drinkAmount,
      'drinkMandatory': drinkMandatory,
      'drinkIncluded': drinkIncluded,
      'drinkMemo': drinkMemo,
      'specialFormat': specialFormat.name,
      'specialActivities': specialActivities.map((e) => e.name).toList(),
      'releaseName': releaseName,
      'serviceName': serviceName,
      'participationMethod': participationMethod,
      'participationSlots': participationSlots.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OshiEvent.fromJson(Map<String, dynamic> json) {
    return OshiEvent(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'イベント',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      venue: json['venue'] as String? ?? '',
      type: OshiEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => OshiEventType.taiban,
      ),
      openTime: _timeFromJson(json['openTime']),
      startTime: _timeFromJson(json['startTime']),
      endTime: _timeFromJson(json['endTime']),
      performers: _stringList(json['performers']),
      timetable: _scheduleList(json['timetable']),
      primaryGroup: json['primaryGroup'] as String?,
      wantedGroups: _stringList(json['wantedGroups']),
      mySchedule: _scheduleList(json['mySchedule']),
      ticketStatus: json['ticketStatus'] as String? ?? '未設定',
      ticketAmount: (json['ticketAmount'] as num?)?.toInt(),
      url: json['url'] as String? ?? '',
      flyerBase64: json['flyerBase64'] as String?,
      memo: json['memo'] as String? ?? '',
      drinkRequired: json['drinkRequired'] as bool? ?? false,
      drinkAmount: (json['drinkAmount'] as num?)?.toInt(),
      drinkMandatory: json['drinkMandatory'] as bool? ?? true,
      drinkIncluded: json['drinkIncluded'] as bool? ?? false,
      drinkMemo: json['drinkMemo'] as String? ?? '',
      specialFormat: SpecialEventFormat.values.firstWhere(
        (value) => value.name == json['specialFormat'],
        orElse: () => SpecialEventFormat.faceToFace,
      ),
      specialActivities: _specialActivityList(json['specialActivities']),
      releaseName: json['releaseName'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      participationMethod: json['participationMethod'] as String? ?? '',
      participationSlots: _participationSlotList(json['participationSlots']),
      visibility: EventVisibility.values.firstWhere(
        (value) => value.name == json['visibility'],
        orElse: () => EventVisibility.shared,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

Map<String, int>? _timeToJson(TimeOfDay? time) {
  if (time == null) return null;
  return {'hour': time.hour, 'minute': time.minute};
}

TimeOfDay? _timeFromJson(dynamic value) {
  if (value is! Map) return null;
  final hour = value['hour'];
  final minute = value['minute'];
  if (hour is! num || minute is! num) return null;
  return TimeOfDay(hour: hour.toInt(), minute: minute.toInt());
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

List<EventScheduleEntry> _scheduleList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (entry) =>
            EventScheduleEntry.fromJson(Map<String, dynamic>.from(entry)),
      )
      .toList();
}


List<SpecialActivityType> _specialActivityList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map(
        (name) => SpecialActivityType.values.firstWhere(
          (item) => item.name == name,
          orElse: () => SpecialActivityType.other,
        ),
      )
      .toList();
}

ParticipationSlotStatus _participationStatusFromJson(dynamic value) {
  switch (value?.toString()) {
    case 'attended':
      return ParticipationSlotStatus.attended;
    case 'transferred':
      return ParticipationSlotStatus.transferred;
    case 'cancelled':
      return ParticipationSlotStatus.cancelled;
    case 'pending':
      return ParticipationSlotStatus.pending;
    case 'applying':
    case 'wonUnpaid':
    case 'paid':
    case 'issued':
    case 'lost':
    default:
      return ParticipationSlotStatus.pending;
  }
}

List<EventParticipationSlot> _participationSlotList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (entry) => EventParticipationSlot.fromJson(
          Map<String, dynamic>.from(entry),
        ),
      )
      .toList();
}
