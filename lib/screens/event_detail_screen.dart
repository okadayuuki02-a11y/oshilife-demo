import 'dart:convert';

import 'package:flutter/material.dart';

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
          .where((e) => e.eventId == _event.id)
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
          const SizedBox(height: 8),
          _iconLine(
            Icons.schedule_rounded,
            'OPEN ${_timeText(_event.openTime)} / START ${_timeText(_event.startTime)}',
          ),
        ],
      ),
    );
  }

  Widget _sharedInfoCard(BuildContext context) {
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
              _timeText(entry.startTime),
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
        .fold<int>(0, (sum, e) => sum + e.amount);
    final refunds = _transactions
        .where((e) => e.type == TransactionType.refund)
        .fold<int>(0, (sum, e) => sum + e.amount);
    final net = expense - refunds;

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
              'チェキ',
              '${_chekis.length}枚',
              onTap: _openChekis,
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
          'チェキ',
          _chekis.isEmpty ? '写真あり／画像なしのどちらでも記録' : '${_chekis.length}枚記録中',
          _openChekis,
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
