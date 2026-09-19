import 'package:flutter/material.dart';

enum EventVisibility {
  shared,
  limited,
  private,
}

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

enum OshiEventType { solo, taiban, festival }

extension OshiEventTypeX on OshiEventType {
  String get label {
    switch (this) {
      case OshiEventType.solo:
        return '単独';
      case OshiEventType.taiban:
        return '対バン';
      case OshiEventType.festival:
        return 'フェス';
    }
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
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? 'event_${DateTime.now().microsecondsSinceEpoch}',
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
      .map((entry) => EventScheduleEntry.fromJson(Map<String, dynamic>.from(entry)))
      .toList();
}
