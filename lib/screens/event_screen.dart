import 'package:flutter/material.dart';

import '../models/oshi.dart';
import '../models/oshi_event.dart';
import 'event_add_screen.dart';
import 'event_detail_screen.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({
    super.key,
    required this.events,
    required this.onAddEvent,
    required this.onUpdateEvent,
    required this.onDeleteEvent,
    required this.onBackToEventList,
    required this.oshis,
    required this.onActivityChanged,
  });

  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  final List<OshiEvent> events;
  final List<Oshi> oshis;
  final Future<void> Function() onActivityChanged;
  final Future<void> Function(OshiEvent event) onAddEvent;
  final Future<void> Function(
    OshiEvent originalEvent,
    OshiEvent updatedEvent,
  ) onUpdateEvent;
  final Future<void> Function(OshiEvent event) onDeleteEvent;
  final VoidCallback onBackToEventList;

  @override
  Widget build(BuildContext context) {
    final sortedEvents = [...events]
      ..sort((a, b) => _eventDateTime(a).compareTo(_eventDateTime(b)));

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final upcoming = sortedEvents
        .where((event) => !event.date.isBefore(todayStart))
        .toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  const Icon(Icons.event_rounded, color: purple, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'イベント',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openAdd(context),
                    style: FilledButton.styleFrom(backgroundColor: purple),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('追加'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _searchEntry(context),
              const SizedBox(height: 20),
              const Text(
                '次の予定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                _emptyCard(context)
              else
                ...upcoming.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _eventCard(context, event),
                  ),
                ),
              if (sortedEvents.length > upcoming.length) ...[
                const SizedBox(height: 12),
                const Text(
                  '過去のイベント',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...sortedEvents
                    .where((event) => event.date.isBefore(todayStart))
                    .toList()
                    .reversed
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _eventCard(context, event),
                      ),
                    ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_rounded, color: purple),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '登録したイベントは保存され、次の予定はホームにも自動表示されます。',
                        style: TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final event = await Navigator.of(context).push<OshiEvent>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_add'),
        builder: (_) => const EventAddScreen(),
      ),
    );

    if (event == null || !context.mounted) return;

    await onAddEvent(event);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_detail'),
        builder: (_) => EventDetailScreen(
          event: event,
          onUpdateEvent: onUpdateEvent,
          onDeleteEvent: onDeleteEvent,
          onBackToEventList: onBackToEventList,
          oshis: oshis,
          onActivityChanged: onActivityChanged,
        ),
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final event = await Navigator.of(context).push<OshiEvent>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_search'),
        builder: (_) => const SharedEventSearchScreen(),
      ),
    );

    if (event == null || !context.mounted) return;

    await onAddEvent(event);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'event_detail'),
        builder: (_) => EventDetailScreen(
          event: event,
          onUpdateEvent: onUpdateEvent,
          onDeleteEvent: onDeleteEvent,
          onBackToEventList: onBackToEventList,
          oshis: oshis,
          onActivityChanged: onActivityChanged,
        ),
      ),
    );
  }

  Widget _searchEntry(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openSearch(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E0F7)),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: purple),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '日付・地域・出演者からイベントを探す',
                style: TextStyle(color: Color(0xFF716B78)),
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E0F7)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded, color: purple, size: 38),
          const SizedBox(height: 10),
          const Text(
            '次のイベントはまだありません',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            '検索・画像・手入力から予定を追加してみよう',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF716B78)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openAdd(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('イベントを追加'),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(BuildContext context, OshiEvent event) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
        settings: const RouteSettings(name: 'event_detail'),
        builder: (_) => EventDetailScreen(
          event: event,
          onUpdateEvent: onUpdateEvent,
          onDeleteEvent: onDeleteEvent,
          onBackToEventList: onBackToEventList,
          oshis: oshis,
          onActivityChanged: onActivityChanged,
        ),
      ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E0F7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: lightPurple,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.type.label,
                      style: const TextStyle(color: purple, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Icon(event.visibility.icon, color: purple, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    event.visibility.label,
                    style: const TextStyle(color: purple, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              _iconLine(Icons.calendar_month_rounded, _dateText(event.date)),
              const SizedBox(height: 6),
              _iconLine(
                Icons.location_on_outlined,
                event.venue.isEmpty ? '会場未定' : event.venue,
              ),
              if (event.openTime != null || event.startTime != null) ...[
                const SizedBox(height: 6),
                _iconLine(
                  Icons.schedule_rounded,
                  'OPEN ${_timeText(event.openTime)} / START ${_timeText(event.startTime)}',
                ),
              ],
              if (event.primaryGroup != null && event.primaryGroup!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'お目当て：${event.primaryGroup}',
                  style: const TextStyle(color: purple, fontWeight: FontWeight.w800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF716B78)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF5F5965)),
          ),
        ),
      ],
    );
  }

  DateTime _eventDateTime(OshiEvent event) {
    final time = event.openTime ?? event.startTime;
    return DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
  }

  String _dateText(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  String _timeText(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
