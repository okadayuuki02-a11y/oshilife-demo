import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/activity_models.dart';
import '../models/oshi.dart';
import '../models/oshi_event.dart';
import '../services/activity_storage.dart';
import 'activity_screens.dart';
import 'event_add_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.onUpdateEvent,
    required this.onDeleteEvent,
    required this.onBackToEventList,
    required this.oshis,
    required this.onActivityChanged,
  });

  final OshiEvent event;
  final List<Oshi> oshis;
  final Future<void> Function() onActivityChanged;
  final Future<void> Function(OshiEvent originalEvent, OshiEvent updatedEvent)
  onUpdateEvent;
  final Future<void> Function(OshiEvent event) onDeleteEvent;
  final VoidCallback onBackToEventList;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  late OshiEvent _event;
  List<TicketRecord> _tickets = [];
  List<ChekiPurchase> _purchases = [];
  List<ChekiRecord> _chekis = [];
  List<TalkLog> _talks = [];
  List<OshiTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _reloadActivity();
  }

  Future<void> _reloadActivity() async {
    final result = await Future.wait([
      ActivityStorage.loadTickets(),
      ActivityStorage.loadChekiPurchases(),
      ActivityStorage.loadChekis(),
      ActivityStorage.loadTalks(),
      ActivityStorage.loadTransactions(),
    ]);
    if (!mounted) return;
    setState(() {
      _tickets = (result[0] as List<TicketRecord>)
          .where((e) => e.eventId == _event.id)
          .toList();
      _purchases = (result[1] as List<ChekiPurchase>)
          .where((e) => e.eventId == _event.id)
          .toList();
      _chekis = (result[2] as List<ChekiRecord>)
          .where((e) => e.eventId == _event.id)
          .toList();
      _talks = (result[3] as List<TalkLog>)
          .where((e) => e.eventId == _event.id)
          .toList();
      _transactions = (result[4] as List<OshiTransaction>)
          .where((e) => e.isLinkedToEvent(_event.id))
          .toList();
    });
  }

  Future<void> _activityChanged() async {
    await _reloadActivity();
    await widget.onActivityChanged();
  }

  String _dateText(DateTime value) {
    const week = ['月', '火', '水', '木', '金', '土', '日'];
    return '${value.year}/${value.month}/${value.day} (${week[value.weekday - 1]})';
  }

  String _timeText(TimeOfDay? value) {
    if (value == null) return '未定';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _scheduleTime(EventScheduleEntry entry) {
    final start = _timeText(entry.startTime);
    if (entry.endTime == null) return start;
    return '$start〜${_timeText(entry.endTime)}';
  }

  EventScheduleEntry? _primaryLiveEntry() {
    final primary = _event.primaryGroup;
    if (primary == null || primary.trim().isEmpty) return null;
    for (final entry in _event.timetable) {
      if (entry.title == primary && entry.label == 'ライブ') return entry;
    }
    return null;
  }

  List<EventScheduleEntry> _primaryExtraSchedule() {
    final primary = _event.primaryGroup;
    if (primary == null || primary.trim().isEmpty) return const [];
    return _event.mySchedule.where((entry) => entry.title == primary).toList();
  }

  Future<void> _editEvent() async {
    final updatedEvent = await Navigator.of(context).push<OshiEvent>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_edit'),
        builder: (_) => ManualEventScreen(initialEvent: _event),
      ),
    );

    if (updatedEvent == null || !mounted) return;

    final originalEvent = _event;
    await widget.onUpdateEvent(originalEvent, updatedEvent);
    if (!mounted) return;

    setState(() {
      _event = updatedEvent;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('イベントを更新しました')));
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('イベントを削除しますか？'),
        content: Text('「${_event.title}」を削除します。\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    await widget.onDeleteEvent(_event);
    if (!mounted) return;

    widget.onBackToEventList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBackToEventList();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: widget.onBackToEventList,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'イベント詳細',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            TextButton.icon(
              onPressed: _editEvent,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('編集'),
            ),
            PopupMenuButton<String>(
              tooltip: 'イベントメニュー',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red),
                      SizedBox(width: 10),
                      Text('イベントを削除'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _summaryCard(),
                const SizedBox(height: 14),
                _sharedInfoCard(context),
                const SizedBox(height: 14),
                if (_event.type == OshiEventType.specialEvent)
                  _specialEventCard(context)
                else
                  _myPlanCard(context),
                const SizedBox(height: 14),
                _eventHubCard(),
                const SizedBox(height: 14),
                _recordActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _event.type.label,
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(_event.visibility.icon, color: purple, size: 18),
              const SizedBox(width: 4),
              Text(
                _event.visibility.label,
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _event.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _iconLine(Icons.calendar_month_rounded, _dateText(_event.date)),
          const SizedBox(height: 8),
          _iconLine(
            Icons.location_on_outlined,
            _event.venue.isEmpty ? '会場未定' : _event.venue,
          ),
          if (_event.type != OshiEventType.specialEvent) ...[
            const SizedBox(height: 8),
            _iconLine(
              Icons.schedule_rounded,
              'OPEN ${_timeText(_event.openTime)} / START ${_timeText(_event.startTime)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _sharedInfoCard(BuildContext context) {
    if (_event.type == OshiEventType.specialEvent) {
      final activities = _event.specialActivities.isEmpty
          ? '特典会'
          : _event.specialActivities.map((e) => e.label).join(' / ');
      return _sectionCard(
        title: 'イベント情報',
        icon: Icons.badge_outlined,
        children: [
          _detailRow('種類', activities),
          _detailRow('日付', _dateText(_event.date)),
          _detailRow('会場', _event.venue.isEmpty ? '未定' : _event.venue),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_bolt_rounded, color: purple, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'イベント・参加枠・トーク・券情報は端末に保存されるので、会場で通信が弱くても確認・更新できます。',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _sectionCard(
      title: 'みんな共通のイベント情報',
      icon: Icons.public_rounded,
      children: [
        _detailRow('イベント名', _event.title),
        _detailRow('日付', _dateText(_event.date)),
        _detailRow('会場', _event.venue.isEmpty ? '未定' : _event.venue),
        _detailRow(
          '出演者',
          _event.performers.isEmpty ? '未登録' : '${_event.performers.length}組',
        ),
        if (_event.url.isNotEmpty) _detailRow('URL', _event.url),
        if (_event.memo.isNotEmpty) _detailRow('メモ', _event.memo),
        if (_event.flyerBase64 != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Image.memory(base64Decode(_event.flyerBase64!), height: 150),
          ),
        if (_event.mySchedule.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              '当日のスケジュール',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final entry in _event.mySchedule)
            _detailRow(
              _scheduleTime(entry),
              '${entry.title}（${entry.label}）',
            ),
        ],
        if (_event.drinkRequired) ...[
          const SizedBox(height: 12),
          _detailRow(
            'ドリンク代',
            '${_event.drinkAmount ?? 0}円・${_event.drinkMandatory ? '必須' : '任意'}・${_event.drinkIncluded ? 'チケット込み' : '当日支払'}',
          ),
          if (_event.drinkMemo.isNotEmpty)
            _detailRow('ドリンクメモ', _event.drinkMemo),
          if (!_event.drinkIncluded && (_event.drinkAmount ?? 0) > 0)
            TextButton.icon(
              onPressed: _recordDrink,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                _transactions.any(
                      (t) => t.sourceType == 'drink' && t.sourceId == _event.id,
                    )
                    ? 'ドリンク代は支出に登録済み'
                    : '支払ったドリンク代を支出に登録',
              ),
            ),
        ],
        const SizedBox(height: 8),
        _linkTile(
          icon: Icons.view_timeline_rounded,
          title: '全体タイムテーブル',
          subtitle: _event.timetable.isEmpty
              ? '未登録'
              : '${_event.timetable.length}組の出演時間を確認',
          onTap: () => _showFullTimetable(context),
        ),
        const SizedBox(height: 8),
        _linkTile(
          icon: _event.visibility.icon,
          title: '公開範囲：${_event.visibility.label}',
          subtitle: 'タップして説明を見る',
          onTap: () => _showVisibilityInfo(context),
        ),
      ],
    );
  }

  List<EventParticipationSlot> _sortedParticipationSlots() {
    final slots = [..._event.participationSlots];
    slots.sort((a, b) {
      final am = (a.startTime?.hour ?? 99) * 60 + (a.startTime?.minute ?? 99);
      final bm = (b.startTime?.hour ?? 99) * 60 + (b.startTime?.minute ?? 99);
      return am.compareTo(bm);
    });
    return slots;
  }

  List<EventParticipationSlot> _upcomingParticipationSlots() {
    final slots = _sortedParticipationSlots()
        .where(
          (slot) =>
              slot.status != ParticipationSlotStatus.attended &&
              slot.status != ParticipationSlotStatus.cancelled,
        )
        .toList();

    final now = DateTime.now();
    final eventDay = DateTime(_event.date.year, _event.date.month, _event.date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (eventDay.isAfter(today)) return slots;
    if (eventDay.isBefore(today)) return slots;

    return slots.where((slot) {
      final boundary =
          slot.receptionEndTime ?? slot.endTime ?? slot.startTime;
      if (boundary == null) return true;
      final point = DateTime(
        now.year,
        now.month,
        now.day,
        boundary.hour,
        boundary.minute,
      );
      return !point.isBefore(now);
    }).toList();
  }

  String _slotDeadlineHint(EventParticipationSlot slot) {
    final deadline = slot.receptionEndTime;
    if (deadline == null) return '';

    final now = DateTime.now();
    final eventDay = DateTime(_event.date.year, _event.date.month, _event.date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (eventDay != today) return '受付終了 ${_timeText(deadline)}';

    final point = DateTime(
      now.year,
      now.month,
      now.day,
      deadline.hour,
      deadline.minute,
    );
    final minutes = point.difference(now).inMinutes;
    if (minutes < 0) return '受付終了済み';
    if (minutes == 0) return '受付終了まで1分未満';
    if (minutes < 60) return '受付終了まであと$minutes分';
    return '受付終了 ${_timeText(deadline)}';
  }

  Widget _specialEventCard(BuildContext context) {
    final slots = _sortedParticipationSlots();
    final upcoming = _upcomingParticipationSlots();

    return _sectionCard(
      title: '参加する部・枠',
      icon: Icons.badge_outlined,
      children: [
        if (upcoming.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '次の予定',
                  style: TextStyle(
                    color: purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                for (final slot in upcoming.take(2)) ...[
                  Text(
                    [
                      if (slot.startTime != null) _timeText(slot.startTime),
                      if (slot.partLabel.isNotEmpty) slot.partLabel,
                      if (slot.memberName.isNotEmpty) slot.memberName,
                    ].join('  '),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      slot.activityType.label,
                      if (_slotDeadlineHint(slot).isNotEmpty)
                        _slotDeadlineHint(slot),
                      '所持 ${slot.owned}枚',
                    ].join(' ・ '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF716B78),
                    ),
                  ),
                  if (slot != upcoming.take(2).last)
                    const Divider(height: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E0F7)),
            ),
            child: const Text(
              '参加する部だけ追加すればOKです。当日券を取った時も、あとからすぐ追加・枚数変更できます。',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF716B78),
                height: 1.45,
              ),
            ),
          )
        else
          for (final slot in slots) ...[
            _participationSlotCard(slot),
            const SizedBox(height: 10),
          ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _editParticipationSlot(),
            style: FilledButton.styleFrom(backgroundColor: purple),
            icon: const Icon(Icons.add_rounded),
            label: const Text('参加する部を追加'),
          ),
        ),
      ],
    );
  }

  Widget _participationSlotCard(EventParticipationSlot slot) {
    final relatedTalks = _talks
        .where((talk) => talk.participationSlotId == slot.id)
        .toList();
    final isDone = slot.status == ParticipationSlotStatus.attended;
    final remaining = slot.remainingCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFCFC6D7) : const Color(0xFFDCCBFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (slot.partLabel.isNotEmpty) slot.partLabel,
                        if (slot.memberName.isNotEmpty) slot.memberName,
                      ].join('  '),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.activityType.label,
                      style: const TextStyle(
                        color: purple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFEDE8F1) : lightPurple,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  slot.status.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (slot.startTime != null)
            _iconLine(
              Icons.schedule_rounded,
              slot.endTime == null
                  ? _timeText(slot.startTime)
                  : '${_timeText(slot.startTime)}〜${_timeText(slot.endTime)}',
            ),
          if (slot.receptionEndTime != null) ...[
            const SizedBox(height: 6),
            _iconLine(
              Icons.timer_outlined,
              _slotDeadlineHint(slot),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _slotCountPill('所持', '${slot.owned}枚'),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _slotCountPill('使用', '${slot.used}枚'),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _slotCountPill('残り', '$remaining枚'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton(
                onPressed: () => _changeOwnedCount(slot, 1),
                child: const Text('＋1枚'),
              ),
              OutlinedButton(
                onPressed: () => _changeOwnedCount(slot, 5),
                child: const Text('＋5枚'),
              ),
              if (remaining > 0 && !isDone)
                OutlinedButton(
                  onPressed: () => _changeUsedCount(slot, 1),
                  child: const Text('使用＋1'),
                ),
            ],
          ),
          if (slot.laneOrChannel.isNotEmpty) ...[
            const SizedBox(height: 6),
            _iconLine(Icons.signpost_outlined, slot.laneOrChannel),
          ],
          if (slot.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              slot.note,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF716B78),
              ),
            ),
          ],
          if (slot.imagesBase64.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: slot.imagesBase64.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  try {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(slot.imagesBase64[index]),
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
          if (relatedTalks.isNotEmpty) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => _openTalksForSlot(slot),
              icon: const Icon(Icons.forum_outlined, size: 17),
              label: Text('この枠のトークログ ${relatedTalks.length}件を見る'),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _addTalkForSlot(slot),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('トーク記録'),
              ),
              if (slot.activityType.supportsPhoto)
                FilledButton.tonalIcon(
                  onPressed: () => _addPhotosForSlot(slot),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(slot.imagesBase64.isEmpty ? '写真追加' : '写真を追加'),
                ),
              if (!isDone)
                OutlinedButton.icon(
                  onPressed: () => _markSlotAttended(slot),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('参加済み'),
                ),
              TextButton.icon(
                onPressed: () => _editParticipationSlot(initial: slot),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('編集'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotCountPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0F7)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF716B78),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Future<void> _changeOwnedCount(
    EventParticipationSlot slot,
    int delta,
  ) async {
    final next = slot.owned + delta;
    await _replaceParticipationSlot(
      slot.copyWith(
        ownedCount: next < 0 ? 0 : next,
        status: slot.status == ParticipationSlotStatus.attended
            ? ParticipationSlotStatus.pending
            : slot.status,
      ),
    );
  }

  Future<void> _changeUsedCount(
    EventParticipationSlot slot,
    int delta,
  ) async {
    final max = slot.owned;
    var next = slot.used + delta;
    if (next < 0) next = 0;
    if (max > 0 && next > max) next = max;
    await _replaceParticipationSlot(
      slot.copyWith(
        usedCount: next,
        status: max > 0 && next >= max
            ? ParticipationSlotStatus.attended
            : ParticipationSlotStatus.pending,
      ),
    );
  }

  Future<void> _editParticipationSlot({
    EventParticipationSlot? initial,
  }) async {
    final member = TextEditingController(text: initial?.memberName ?? '');
    final part = TextEditingController(text: initial?.partLabel ?? '');
    final owned = TextEditingController(
      text: initial?.ownedCount?.toString() ?? '',
    );
    final lane = TextEditingController(text: initial?.laneOrChannel ?? '');
    final note = TextEditingController(text: initial?.note ?? '');

    var activity = initial?.activityType ??
        (_event.specialActivities.isNotEmpty
            ? _event.specialActivities.first
            : SpecialActivityType.talk);
    var status = initial?.status ?? ParticipationSlotStatus.pending;
    var start = initial?.startTime;
    var end = initial?.endTime;
    var receptionEnd = initial?.receptionEndTime;

    final result = await showModalBottomSheet<EventParticipationSlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              16,
              18,
              18 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initial == null ? '参加する部を追加' : '参加枠を編集',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '当日必要な情報だけ入れればOK。申込枚数や当選枚数の入力は不要です。',
                    style: TextStyle(
                      color: Color(0xFF716B78),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: part,
                    decoration: const InputDecoration(
                      labelText: '部・枠（例：第2部）',
                      prefixIcon: Icon(Icons.view_agenda_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: member,
                    decoration: const InputDecoration(
                      labelText: 'メンバー名',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SpecialActivityType>(
                    initialValue: activity,
                    decoration: const InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(),
                    ),
                    items: SpecialActivityType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        update(() => activity = value ?? activity),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _slotTimeButton(
                          ctx,
                          label: '開始',
                          value: start,
                          onChanged: (value) => update(() => start = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _slotTimeButton(
                          ctx,
                          label: '終了',
                          value: end,
                          onChanged: (value) => update(() => end = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _slotTimeButton(
                    ctx,
                    label: '受付終了',
                    value: receptionEnd,
                    onChanged: (value) => update(() => receptionEnd = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: owned,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '所持枚数',
                      suffixText: '枚',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ParticipationSlotStatus>(
                    initialValue: [
                      ParticipationSlotStatus.pending,
                      ParticipationSlotStatus.attended,
                      ParticipationSlotStatus.transferred,
                      ParticipationSlotStatus.cancelled,
                    ].contains(status)
                        ? status
                        : ParticipationSlotStatus.pending,
                    decoration: const InputDecoration(
                      labelText: '状態',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      ParticipationSlotStatus.pending,
                      ParticipationSlotStatus.attended,
                      ParticipationSlotStatus.transferred,
                      ParticipationSlotStatus.cancelled,
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        update(() => status = value ?? status),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lane,
                    decoration: const InputDecoration(
                      labelText: 'レーン・チャンネル（任意）',
                      prefixIcon: Icon(Icons.signpost_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'メモ（任意）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: purple),
                      onPressed: () {
                        Navigator.pop(
                          ctx,
                          EventParticipationSlot(
                            id: initial?.id,
                            memberName: member.text.trim(),
                            partLabel: part.text.trim(),
                            activityType: activity,
                            startTime: start,
                            endTime: end,
                            receptionEndTime: receptionEnd,
                            ownedCount: int.tryParse(owned.text.trim()) ?? 0,
                            usedCount: initial?.usedCount,
                            status: status,
                            laneOrChannel: lane.text.trim(),
                            note: note.text.trim(),
                            imagesBase64: initial?.imagesBase64,
                          ),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    member.dispose();
    part.dispose();
    owned.dispose();
    lane.dispose();
    note.dispose();

    if (result == null || !mounted) return;

    final slots = [..._event.participationSlots];
    if (initial == null) {
      slots.add(result);
    } else {
      final index = slots.indexWhere((item) => item.id == initial.id);
      if (index >= 0) slots[index] = result;
    }
    final updated = _event.copyWith(participationSlots: slots);
    final original = _event;
    await widget.onUpdateEvent(original, updated);
    if (!mounted) return;
    setState(() => _event = updated);
  }

  Widget _slotTimeButton(
    BuildContext context, {
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay?> onChanged,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? const TimeOfDay(hour: 12, minute: 0),
        );
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.schedule_rounded, size: 18),
      label: Text('$label ${_timeText(value)}'),
    );
  }

  Future<void> _replaceParticipationSlot(EventParticipationSlot slot) async {
    final slots = [..._event.participationSlots];
    final index = slots.indexWhere((item) => item.id == slot.id);
    if (index < 0) return;
    slots[index] = slot;
    final updated = _event.copyWith(participationSlots: slots);
    final original = _event;
    await widget.onUpdateEvent(original, updated);
    if (!mounted) return;
    setState(() => _event = updated);
  }

  Future<void> _addPhotosForSlot(EventParticipationSlot slot) async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 70,
      maxWidth: 1400,
      maxHeight: 1800,
    );
    if (files.isEmpty) return;
    final images = [...slot.imagesBase64];
    for (final file in files) {
      images.add(base64Encode(await file.readAsBytes()));
    }
    try {
      await _replaceParticipationSlot(slot.copyWith(imagesBase64: images));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を保存できませんでした。画像枚数や保存容量を確認してください。')),
      );
    }
  }

  Future<void> _markSlotAttended(EventParticipationSlot slot) async {
    await _replaceParticipationSlot(
      slot.copyWith(
        status: ParticipationSlotStatus.attended,
        usedCount: slot.usedCount ?? slot.ownedCount,
      ),
    );
  }

  Future<void> _openTalksForSlot(EventParticipationSlot slot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'slot_talk_list'),
        builder: (_) => TalkListScreen(
          event: _event,
          memberName: slot.memberName.isEmpty ? null : slot.memberName,
          participationSlotId: slot.id,
          oshis: widget.oshis,
          onChanged: _activityChanged,
        ),
      ),
    );
    await _reloadActivity();
  }

  Future<void> _addTalkForSlot(EventParticipationSlot slot) async {
    final chekis = (await ActivityStorage.loadChekis())
        .where((e) => e.eventId == _event.id)
        .toList();
    if (!mounted) return;

    final ticketCount = slot.usedCount ?? slot.ownedCount;
    final talk = await Navigator.of(context).push<TalkLog>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'slot_talk_add'),
        builder: (_) => TalkEditScreen(
          event: _event,
          oshis: widget.oshis,
          chekis: chekis,
          preselectedMember: slot.memberName.isEmpty ? null : slot.memberName,
          preselectedSessionLabel: [
            if (slot.partLabel.isNotEmpty) slot.partLabel,
            slot.activityType.label,
          ].join(' '),
          preselectedTicketCount: ticketCount,
          participationSlotId: slot.id,
        ),
      ),
    );
    if (talk == null) return;
    await ActivityStorage.saveTalk(talk);
    await _activityChanged();
  }

  Widget _myPlanCard(BuildContext context) {
    final primary = _event.primaryGroup ?? '未設定';
    final primaryLive = _primaryLiveEntry();
    final primaryExtras = _primaryExtraSchedule();

    return _sectionCard(
      title: 'あなたの予定',
      icon: Icons.favorite_rounded,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lightPurple,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'お目当て',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF716B78),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                primary,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: purple, size: 20),
                  const SizedBox(width: 7),
                  Text(
                    primaryLive == null
                        ? '出演時間 未登録'
                        : '出演 ${_scheduleTime(primaryLive)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (primaryLive == null) ...[
                const SizedBox(height: 5),
                const Text(
                  'タイテ公開後やOCR読み取り後に追加できます。',
                  style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
                ),
              ],
              ...primaryExtras.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: purple,
                        size: 20,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.label} ${_scheduleTime(entry)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (entry.note != null &&
                                entry.note!.trim().isNotEmpty)
                              Text(
                                entry.note!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF716B78),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _linkTile(
          icon: Icons.visibility_rounded,
          title: '見たいグループ',
          subtitle: _event.wantedGroups.isEmpty
              ? '未設定'
              : '${_event.wantedGroups.length}組を登録中',
          onTap: () => _showWantedGroups(context),
        ),
        const SizedBox(height: 6),
        _linkTile(
          icon: Icons.confirmation_number_rounded,
          title: 'チケット',
          subtitle: _tickets.isEmpty
              ? '未登録'
              : '${_tickets.length}枚・${_tickets.map((e) => e.status.label).toSet().join(' / ')}',
          onTap: _openTickets,
        ),
        const SizedBox(height: 8),
        const Text(
          '※ お目当て・見たい・支出・チェキ・トークログ・メモなどの個人記録は共有されません。',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B6674),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  void _showFullTimetable(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _scheduleSheet(
        context,
        title: '全体タイムテーブル',
        entries: _event.timetable,
        emptyText: 'タイムテーブルはまだ登録されていません。',
      ),
    );
  }

  void _showWantedGroups(BuildContext context) {
    final entries = <EventScheduleEntry>[];
    for (final group in _event.wantedGroups) {
      final matches = _event.timetable
          .where((entry) => entry.title == group)
          .toList();
      if (matches.isEmpty) {
        entries.add(EventScheduleEntry(title: group));
      } else {
        entries.addAll(matches);
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _scheduleSheet(
        context,
        title: '見たいグループ詳細',
        entries: entries,
        emptyText: '見たいグループはまだ設定されていません。',
      ),
    );
  }

  Widget _scheduleSheet(
    BuildContext context, {
    required String title,
    required List<EventScheduleEntry> entries,
    required String emptyText,
  }) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D2E5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(emptyText),
                )
              else
                ...entries.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E0F7)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            entry.startTime == null
                                ? '時間未登録'
                                : _scheduleTime(entry),
                            style: const TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (entry.stage != null &&
                                  entry.stage!.trim().isNotEmpty)
                                Text(
                                  entry.stage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: purple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (entry.label != 'ライブ')
                                Text(
                                  entry.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF716B78),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showVisibilityInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '公開範囲：${_event.visibility.label}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _event.visibility.description,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'お目当て・見たい・支出・チェキ・トークログ・メモなどの個人記録は共有されません。',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF716B78),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: lightPurple,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: purple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF716B78),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventHubCard() {
    final expense = _transactions
        .where((e) => e.type == TransactionType.expense)
        .fold<int>(0, (sum, e) => sum + e.amountForEvent(_event.id));
    final refunds = _transactions
        .where((e) => e.type == TransactionType.refund)
        .fold<int>(0, (sum, e) => sum + e.amountForEvent(_event.id));
    final net = expense - refunds;
    final slotPhotoCount = _event.participationSlots.fold<int>(
      0,
      (sum, slot) => sum + slot.imagesBase64.length,
    );
    final isSpecial = _event.type == OshiEventType.specialEvent;

    return _sectionCard(
      title: '今日の記録',
      icon: Icons.dashboard_customize_rounded,
      children: [
        Row(
          children: [
            _miniStat(
              Icons.confirmation_number_outlined,
              'チケット',
              '${_tickets.length}枚',
              onTap: _openTickets,
            ),
            const SizedBox(width: 8),
            _miniStat(
              Icons.camera_alt_outlined,
              isSpecial ? '写真' : 'チェキ',
              isSpecial
                  ? '${_chekis.length + slotPhotoCount}枚'
                  : '${_chekis.length}枚',
              onTap: isSpecial ? _showEventPhotos : _openChekis,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _miniStat(
              Icons.forum_outlined,
              'トーク',
              '${_talks.length}回',
              onTap: _openTalks,
            ),
            const SizedBox(width: 8),
            _miniStat(
              Icons.currency_yen_rounded,
              '支出',
              _moneyText(net),
              onTap: _openTransactions,
            ),
          ],
        ),
        if (_event.type == OshiEventType.festival) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.view_timeline_rounded, color: purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'フェスモード：全体タイテと自分の予定をこのイベント内でまとめて管理できます。',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isSpecial) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_outlined, color: purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '特典会モード：部ごとの時間・受付終了・券・トーク・撮影写真を同じ参加枠にまとめます。',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _miniStat(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E0F7)),
            ),
            child: Column(
              children: [
                Icon(icon, color: purple, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF716B78),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _moneyText(int value) {
    final text = value.toString();
    final chars = text.split('').reversed.toList();
    final parts = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      parts.add(chars.skip(i).take(3).toList().reversed.join());
    }
    return '¥${parts.reversed.join(',')}';
  }

  Future<void> _openTickets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_tickets'),
        builder: (_) =>
            EventTicketsScreen(event: _event, onChanged: _activityChanged),
      ),
    );
    await _reloadActivity();
  }

  Future<void> _openChekis() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_chekis'),
        builder: (_) => EventChekiScreen(
          event: _event,
          oshis: widget.oshis,
          onChanged: _activityChanged,
        ),
      ),
    );
    await _reloadActivity();
  }

  void _showEventPhotos() {
    final slotPhotos = <({String label, String image})>[];
    for (final slot in _event.participationSlots) {
      final label = [
        if (slot.partLabel.isNotEmpty) slot.partLabel,
        if (slot.memberName.isNotEmpty) slot.memberName,
        slot.activityType.label,
      ].join(' ');
      for (final image in slot.imagesBase64) {
        slotPhotos.add((label: label, image: image));
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D2E5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'このイベントの写真',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              '撮影会の写真は参加した部・メンバーに紐づけて表示します。',
              style: TextStyle(color: Color(0xFF716B78)),
            ),
            const SizedBox(height: 14),
            if (slotPhotos.isEmpty && _chekis.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('まだ写真はありません。撮影会の参加枠から追加できます。'),
              )
            else ...[
              for (final item in slotPhotos)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E0F7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(item.image),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_chekis.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openChekis();
                  },
                  icon: const Icon(Icons.collections_outlined),
                  label: Text('チェキ記録も見る（${_chekis.length}枚）'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _recordDrink() async {
    if (_transactions.any(
      (t) => t.sourceType == 'drink' && t.sourceId == _event.id,
    ))
      return;
    await ActivityStorage.saveTransaction(
      OshiTransaction(
        amount: _event.drinkAmount!,
        type: TransactionType.expense,
        date: DateTime.now(),
        category: TransactionCategory.food,
        eventId: _event.id,
        memo: 'ドリンク代 ${_event.drinkMemo}',
        sourceType: 'drink',
        sourceId: _event.id,
      ),
    );
    await _activityChanged();
  }

  Future<void> _openTalks() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_talks'),
        builder: (_) => EventTalkScreen(
          event: _event,
          oshis: widget.oshis,
          onChanged: _activityChanged,
        ),
      ),
    );
    await _reloadActivity();
  }

  Future<void> _openTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_transactions'),
        builder: (_) => EventTransactionScreen(
          event: _event,
          oshis: widget.oshis,
          onChanged: _activityChanged,
        ),
      ),
    );
    await _reloadActivity();
  }

  Widget _recordActions() {
    return _sectionCard(
      title: 'このイベントで追加',
      icon: Icons.auto_awesome_rounded,
      children: [
        _actionTile(
          Icons.confirmation_number_rounded,
          'チケット',
          _tickets.isEmpty ? '申込・支払・整理番号・URLを管理' : '${_tickets.length}枚登録中',
          _openTickets,
        ),
        _actionTile(
          Icons.camera_alt_rounded,
          _event.type == OshiEventType.specialEvent ? '写真' : 'チェキ',
          _event.type == OshiEventType.specialEvent
              ? '写メ会・撮影会は参加枠から写真を紐付け'
              : (_chekis.isEmpty ? '写真あり／画像なしのどちらでも記録' : '${_chekis.length}枚記録中'),
          _event.type == OshiEventType.specialEvent ? _showEventPhotos : _openChekis,
        ),
        _actionTile(
          Icons.chat_bubble_rounded,
          'トークログ',
          _talks.isEmpty ? '1対1も1対2以上も会話形式で記録' : '${_talks.length}回記録中',
          _openTalks,
        ),
        _actionTile(
          Icons.receipt_long_rounded,
          '支出',
          'チケット・チェキは自動、その他は手動で追加',
          _openTransactions,
        ),
      ],
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: lightPurple,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: purple),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: purple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF716B78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: purple, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
