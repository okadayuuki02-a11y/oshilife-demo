import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/activity_models.dart';
import 'models/oshi.dart';
import 'models/oshi_event.dart';
import 'screens/oshi_add_screen.dart';
import 'screens/oshi_edit_screen.dart';
import 'screens/graduated_oshi_screen.dart';
import 'screens/event_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/activity_screens.dart';
import 'services/oshi_storage.dart';
import 'services/event_storage.dart';
import 'services/activity_storage.dart';
import 'widgets/free_plan_ad_banner.dart';
import 'utils/member_color.dart';

void main() {
  runApp(const OshiLifeApp());
}

class OshiLifeApp extends StatelessWidget {
  const OshiLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OshiLife',

      locale: const Locale('ja', 'JP'),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('ja', 'JP'),
      ],

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B5CFF),
        ),
      ),

      home: const MainScreen(),
    );
  }
}

class _ContentNavigatorObserver extends NavigatorObserver {
  _ContentNavigatorObserver(this.onRouteChanged);

  final ValueChanged<Route<dynamic>?> onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onRouteChanged(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onRouteChanged(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    onRouteChanged(newRoute);
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();
  late final _ContentNavigatorObserver _contentNavigatorObserver;
  bool _showShellAd = true;
  String? _currentContentRouteName = '/';

  List<Oshi> _oshis = [];
  List<OshiEvent> _events = [];
  List<TicketRecord> _tickets = [];
  List<OshiTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contentNavigatorObserver = _ContentNavigatorObserver(_handleRouteChange);
    _loadInitialData();
  }

  void _handleRouteChange(Route<dynamic>? route) {
    final name = route?.settings.name;
    _currentContentRouteName = name;
    final shouldShow = name == null ||
        name == '/' ||
        name.startsWith('tab_') ||
        name == 'oshi_detail' ||
        name == 'graduated_oshis' ||
        name == 'event_detail';

    if (shouldShow == _showShellAd || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || shouldShow == _showShellAd) return;
      setState(() {
        _showShellAd = shouldShow;
      });
    });
  }

  Future<void> _loadInitialData() async {
    await ActivityStorage.materializeRecurringTransactions();
    final results = await Future.wait([
      OshiStorage.loadOshis(),
      EventStorage.loadEvents(),
      ActivityStorage.loadTickets(),
      ActivityStorage.loadTransactions(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _oshis = results[0] as List<Oshi>;
      _events = results[1] as List<OshiEvent>;
      _tickets = results[2] as List<TicketRecord>;
      _transactions = results[3] as List<OshiTransaction>;
      _isLoading = false;
    });
  }

  Future<void> _saveOshis() async {
    await OshiStorage.saveOshis(_oshis);
  }

  Future<void> _saveEvents() async {
    await EventStorage.saveEvents(_events);
  }

  Future<void> _refreshActivityData() async {
    final result = await Future.wait([
      ActivityStorage.loadTickets(),
      ActivityStorage.loadTransactions(),
    ]);
    if (!mounted) return;
    setState(() {
      _tickets = result[0] as List<TicketRecord>;
      _transactions = result[1] as List<OshiTransaction>;
    });
  }

  Future<void> _addEvent(OshiEvent event) async {
    final sameIndex = _events.indexWhere(
      (saved) =>
          saved.id == event.id ||
          (saved.title == event.title &&
          saved.date.year == event.date.year &&
          saved.date.month == event.date.month &&
          saved.date.day == event.date.day &&
          saved.venue == event.venue),
    );

    setState(() {
      if (sameIndex >= 0) {
        final existing = _events[sameIndex];
        _events[sameIndex] =
            existing.id == event.id ? event : event.copyWith(id: existing.id);
      } else {
        _events.add(event);
      }
    });

    await _saveEvents();
  }

  int _findEventIndex(OshiEvent target) {
    final idIndex = _events.indexWhere((event) => event.id == target.id);
    if (idIndex >= 0) return idIndex;

    final identityIndex = _events.indexWhere((event) => identical(event, target));
    if (identityIndex >= 0) return identityIndex;

    return _events.indexWhere(
      (event) =>
          event.title == target.title &&
          event.date.year == target.date.year &&
          event.date.month == target.date.month &&
          event.date.day == target.date.day &&
          event.venue == target.venue,
    );
  }

  Future<void> _updateEvent(
    OshiEvent originalEvent,
    OshiEvent updatedEvent,
  ) async {
    final index = _findEventIndex(originalEvent);
    if (index < 0) return;

    setState(() {
      _events[index] = updatedEvent;
    });

    await _saveEvents();
  }

  Future<void> _deleteEvent(OshiEvent event) async {
    final index = _findEventIndex(event);
    if (index < 0) return;

    setState(() {
      _events.removeAt(index);
    });

    await _saveEvents();
    await ActivityStorage.deleteEventData(event.id);
    await _refreshActivityData();
  }

  OshiEvent? get _nextEvent {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _events
        .where((event) => !event.date.isBefore(today))
        .toList()
      ..sort((a, b) => _eventDateTime(a).compareTo(_eventDateTime(b)));

    if (upcoming.isEmpty) return null;
    return upcoming.first;
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

  String _eventDateLabel(OshiEvent event) {
    final weekday = const ['月', '火', '水', '木', '金', '土', '日'];
    final day = weekday[event.date.weekday - 1];
    final date = '${event.date.month}/${event.date.day}（$day）';
    final open = _timeLabel(event.openTime);
    final start = _timeLabel(event.startTime);

    if (event.openTime == null && event.startTime == null) {
      return date;
    }

    return '$date  OPEN $open / START $start';
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Oshi? get _primaryOshi {
    for (final oshi in _oshis) {
      if (oshi.isPrimary && !oshi.isGraduated && !oshi.isManagementPaused) {
        return oshi;
      }
    }

    return null;
  }

  List<String> get _groupSuggestions {
    return _oshis
        .map((oshi) => oshi.groupName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  List<OshiTransaction> get _currentMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  int get _currentMonthExpense => _currentMonthTransactions
      .where((e) => e.type == TransactionType.expense)
      .fold<int>(0, (sum, e) => sum + e.amount);

  int get _currentMonthIncome => _currentMonthTransactions
      .where((e) => e.type != TransactionType.expense)
      .fold<int>(0, (sum, e) => sum + e.amount);

  int get _currentBalance => _currentMonthIncome - _currentMonthExpense;

  TicketRecord? get _urgentTicket {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final candidates = _tickets.where((ticket) {
      if (ticket.status != TicketStatus.wonUnpaid ||
          ticket.paymentDeadline == null) {
        return false;
      }
      final deadline = DateTime(
        ticket.paymentDeadline!.year,
        ticket.paymentDeadline!.month,
        ticket.paymentDeadline!.day,
      );
      final days = deadline.difference(today).inDays;
      return days <= 3;
    }).toList()
      ..sort((a, b) => a.paymentDeadline!.compareTo(b.paymentDeadline!));

    return candidates.isEmpty ? null : candidates.first;
  }

  String _moneyLabel(int value) {
    final negative = value < 0;
    final text = value.abs().toString();
    final reversed = text.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.skip(i).take(3).toList().reversed.join());
    }
    return '${negative ? '-' : ''}¥${chunks.reversed.join(',')}';
  }

  Widget _buildTicketAlert(TicketRecord ticket) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      ticket.paymentDeadline!.year,
      ticket.paymentDeadline!.month,
      ticket.paymentDeadline!.day,
    );
    final days = deadline.difference(today).inDays;
    final label = days < 0
        ? '支払期限を過ぎています'
        : days == 0
            ? '今日が支払期限です'
            : days == 1
                ? '支払期限は明日です'
                : '支払期限まであと$days日';

    OshiEvent? event;
    for (final value in _events) {
      if (value.id == ticket.eventId) {
        event = value;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: event == null
          ? null
          : () async {
              setState(() => _selectedIndex = 2);
              final navigator = _contentNavigatorKey.currentState;
              if (navigator == null) return;
              await navigator.push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'event_detail'),
                  builder: (_) => EventDetailScreen(
                    event: event!,
                    onUpdateEvent: _updateEvent,
                    onDeleteEvent: _deleteEvent,
                    onBackToEventList: () => _switchTab(2),
                    oshis: _oshis,
                    onActivityChanged: _refreshActivityData,
                  ),
                ),
              );
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEF5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFB7D1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.pink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event?.title ?? 'チケット',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(
            color: purple,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: Navigator(
        key: _contentNavigatorKey,
        observers: [_contentNavigatorObserver],
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _buildPageForIndex(_selectedIndex),
          );
        },
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showShellAd) const FreePlanAdBanner(),
          NavigationBar(
        selectedIndex: _selectedIndex,
        height: 66,
        indicatorColor: lightPurple,

        onDestinationSelected: _handleDestinationSelected,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: purple,
            ),
            label: 'ホーム',
          ),

          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(
              Icons.favorite_rounded,
              color: purple,
            ),
            label: '推し',
          ),

          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(
              Icons.event_rounded,
              color: purple,
            ),
            label: 'イベント',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: purple,
            ),
            label: '家計簿',
          ),

          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'その他',
          ),
        ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDestinationSelected(int index) async {
    final currentRoute = _currentContentRouteName;
    const inputRoutes = <String>{
      'oshi_add',
      'oshi_edit',
      'oshi_photo_crop',
      'event_add',
      'event_edit',
    };

    if (currentRoute != null && inputRoutes.contains(currentRoute)) {
      final shouldMove = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              '入力画面から移動しますか？',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text('保存していない入力内容は失われます。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('入力を続ける'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('移動する'),
              ),
            ],
          );
        },
      );

      if (shouldMove != true || !mounted) return;
    }

    _switchTab(index);
  }

  void _switchTab(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });

    final navigator = _contentNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: 'tab_$index'),
        builder: (_) => _buildPageForIndex(index),
      ),
      (route) => false,
    );
  }

  Widget _buildPageForIndex(int index) {
    switch (index) {
      case 0:
        return _buildHome();

      case 1:
        return _buildOshiPage();

      case 2:
        return EventScreen(
          events: _events,
          onAddEvent: _addEvent,
          onUpdateEvent: _updateEvent,
          onDeleteEvent: _deleteEvent,
          onBackToEventList: () => _switchTab(2),
          oshis: _oshis,
          onActivityChanged: _refreshActivityData,
        );

      case 3:
        return OshiWalletScreen(
          oshis: _oshis,
          events: _events,
          onChanged: _refreshActivityData,
        );

      case 4:
        return _buildPlaceholder(
          icon: Icons.more_horiz_rounded,
          title: 'その他',
          text: 'その他画面',
        );

      default:
        return _buildHome();
    }
  }

  // =========================================================
  // ホーム
  // =========================================================

  Widget _buildHome() {
    final primary = _primaryOshi;
    final nextEvent = _nextEvent;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final horizontalPadding = isNarrow ? 12.0 : 18.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.menu_rounded,
                          ),
                        ),

                        const SizedBox(width: 2),

                        const Icon(
                          Icons.favorite_rounded,
                          color: purple,
                          size: 26,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            'OshiLife',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isNarrow ? 20 : 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {},
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 25,
                              ),
                            ),

                            Positioned(
                              right: 3,
                              top: 1,
                              child: Container(
                                width: 17,
                                height: 17,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '3',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.only(
                        left: 10,
                        top: 2,
                        bottom: 15,
                      ),
                      child: Text(
                        '推しと過ごす、最高の毎日を。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    if (_urgentTicket != null) ...[
                      _buildTicketAlert(_urgentTicket!),
                      const SizedBox(height: 17),
                    ],

                    const Text(
                      '次回の予定',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        if (nextEvent == null) {
                          _switchTab(2);
                          return;
                        }

                        setState(() {
                          _selectedIndex = 2;
                        });

                        final navigator = _contentNavigatorKey.currentState;
                        if (navigator == null) return;

                        await navigator.push(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'event_detail'),
                            builder: (_) => EventDetailScreen(
                              event: nextEvent,
                              onUpdateEvent: _updateEvent,
                              onDeleteEvent: _deleteEvent,
                              onBackToEventList: () => _switchTab(2),
                              oshis: _oshis,
                              onActivityChanged: _refreshActivityData,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          isNarrow ? 14 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6FAE),
                              Color(0xFF9B5CFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextEvent == null ? 'NEXT EVENT' : 'NEXT EVENT',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              nextEvent?.title ?? '次のイベントを登録しよう',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isNarrow ? 19 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white70,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    nextEvent == null
                                        ? 'イベントタブから予定を追加できます'
                                        : _eventDateLabel(nextEvent),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (nextEvent != null && nextEvent.venue.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white70,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nextEvent.venue,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 17),

                    const Text(
                      '推し活資金',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        _switchTab(3);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          isNarrow ? 14 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE9E0FA),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    '現在残高',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _moneyLabel(_currentBalance),
                                      style: TextStyle(
                                        fontSize: isNarrow ? 19 : 22,
                                        fontWeight: FontWeight.bold,
                                        color: purple,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 13),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: _currentMonthExpense <= 0
                                    ? 0
                                    : (_currentMonthExpense / (_currentMonthExpense + (_currentBalance > 0 ? _currentBalance : 0)))
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                minHeight: 8,
                                backgroundColor: Color(0xFFECE7F5),
                                color: purple,
                              ),
                            ),

                            const SizedBox(height: 11),

                            Row(
                              children: [
                                Expanded(
                                  child: MoneyItem(
                                    label: '入金・返金',
                                    value: _moneyLabel(_currentMonthIncome),
                                  ),
                                ),
                                Expanded(
                                  child: MoneyItem(
                                    label: '推し活支出',
                                    value: _moneyLabel(_currentMonthExpense),
                                  ),
                                ),
                                Expanded(
                                  child: MoneyItem(
                                    label: '差引',
                                    value: _moneyLabel(_currentBalance),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 17),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '推し',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            _switchTab(1);
                          },
                          child: const Text(
                            '推し一覧へ',
                            style: TextStyle(
                              color: purple,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (primary != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _openOshiDetail(primary);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 10 : 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE9E0FA),
                            ),
                          ),
                          child: OshiListTile(
                            oshi: primary,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE9E0FA),
                          ),
                        ),
                        child: const Text(
                          '1推しがまだ登録されていません',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 推し一覧
  // =========================================================

  Widget _buildOshiPage() {
    final managedOshis = _oshis
        .where((oshi) => !oshi.isGraduated && !oshi.isManagementPaused)
        .toList();
    final pausedOshis = _oshis
        .where((oshi) => !oshi.isGraduated && oshi.isManagementPaused)
        .toList();

    final primary = _primaryOshi;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '推し',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const Spacer(),

                    FilledButton.icon(
                      onPressed: _showAddOshi,
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 19,
                      ),
                      label: const Text('追加'),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                const Text(
                  'あなたの大切な推しを管理',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 22),

                if (primary != null) ...[
                  const Text(
                    '1推し',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 9),

                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      _openOshiDetail(primary);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF3EDFF),
                            Color(0xFFFFF9FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFD9C8FA),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          OshiListTile(
                            oshi: primary,
                          ),

                          const SizedBox(height: 15),

                          const Divider(
                            height: 1,
                            color: Color(0xFFE1D8F2),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: OshiStat(
                                  label: '推し日数',
                                  value: primary.oshiDays == null
                                      ? '未設定'
                                      : '${primary.oshiDays}日',
                                ),
                              ),

                              Expanded(
                                child: OshiStat(
                                  label: 'アプリ登録',
                                  value:
                                      '${primary.registeredDays}日',
                                ),
                              ),

                              const Expanded(
                                child: OshiStat(
                                  label: 'ポイント',
                                  value: '1 pt',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                ],

                Row(
                  children: [
                    const Text(
                      '推し一覧',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${managedOshis.length}人',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Expanded(
                  child: managedOshis.isEmpty && pausedOshis.isEmpty
                      ? const Center(
                          child: Text(
                            '推しを追加してみよう！',
                            style: TextStyle(color: Colors.black45),
                          ),
                        )
                      : ListView(
                          children: [
                            ...managedOshis.map(
                              (oshi) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _openOshiDetail(oshi),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFE9E0FA),
                                      ),
                                    ),
                                    child: OshiListTile(oshi: oshi),
                                  ),
                                ),
                              ),
                            ),
                            if (pausedOshis.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    '管理休止中',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${pausedOshis.length}人',
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              ...pausedOshis.map(
                                (oshi) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Opacity(
                                    opacity: 0.72,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _openOshiDetail(oshi),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFE9E0FA),
                                          ),
                                        ),
                                        child: OshiListTile(oshi: oshi),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = _contentNavigatorKey.currentState;
                    if (navigator == null) return;

                    await navigator.push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'graduated_oshis'),
                        builder: (context) {
                          return GraduatedOshiScreen(
                            oshis: _oshis,
                            onChanged: _saveOshis,
                            onOpenDetail: (oshi) {
                              Navigator.of(context).pop();
                              Future.microtask(() => _openOshiDetail(oshi));
                            },
                          );
                        },
                      ),
                    );

                    setState(() {});
                    await _saveOshis();
                  },

                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 48),
                    foregroundColor: purple,
                  ),

                  icon: const Icon(
                    Icons.history_rounded,
                  ),

                  label: const Text(
                    '卒業・過去の推しを見る',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 推し追加
  // =========================================================

  Future<void> _showAddOshi() async {
    final navigator = _contentNavigatorKey.currentState;
    if (navigator == null) return;

    final newOshi = await navigator.push<Oshi>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'oshi_add'),
        builder: (context) {
          return OshiAddScreen(
            defaultPrimary: _oshis.where((oshi) => !oshi.isGraduated).isEmpty,
            groupSuggestions: _groupSuggestions,
          );
        },
      ),
    );

    if (newOshi == null) {
      return;
    }

    setState(() {
      if (newOshi.isPrimary) {
        for (final oshi in _oshis) {
          oshi.isPrimary = false;
        }
      }

      _oshis.add(newOshi);
    });

    await _saveOshis();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${newOshi.name}を推しに追加しました！',
        ),
      ),
    );
  }

  // =========================================================
  // 推し詳細
  // =========================================================

  void _openOshiDetail(Oshi oshi) {
    setState(() {
      _selectedIndex = 1;
    });

    final navigator = _contentNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'oshi_detail'),
        builder: (context) {
          return OshiDetailScreen(
            oshi: oshi,
            groupSuggestions: _groupSuggestions,
            events: _events,
            onBackToList: () => _switchTab(1),
            onDelete: (deletedOshi) async {
              setState(() {
                _oshis.removeWhere((item) => item.id == deletedOshi.id);
              });
              await _saveOshis();
            },

            onChanged: (updatedOshi) async {
              setState(() {
                if (updatedOshi.isPrimary) {
                  for (final item in _oshis) {
                    if (item.id != updatedOshi.id) {
                      item.isPrimary = false;
                    }
                  }
                }
              });

              await _saveOshis();
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // 仮画面
  // =========================================================

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 55,
              color: purple,
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// 推し詳細画面
// ===========================================================

class OshiDetailScreen extends StatefulWidget {
  final Oshi oshi;
  final Future<void> Function(Oshi) onChanged;
  final Future<void> Function(Oshi) onDelete;
  final VoidCallback onBackToList;
  final List<String> groupSuggestions;
  final List<OshiEvent> events;

  const OshiDetailScreen({
    super.key,
    required this.oshi,
    required this.onChanged,
    required this.onDelete,
    required this.onBackToList,
    this.groupSuggestions = const <String>[],
    this.events = const <OshiEvent>[],
  });

  @override
  State<OshiDetailScreen> createState() =>
      _OshiDetailScreenState();
}

class _OshiDetailScreenState
    extends State<OshiDetailScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const background = Color(0xFFFFF8FF);

  Future<void> _editOshi() async {
    final updatedOshi =
        await Navigator.of(context).push<Oshi>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'oshi_edit'),
        builder: (context) {
          return OshiEditScreen(
            oshi: widget.oshi,
            groupSuggestions: widget.groupSuggestions,
          );
        },
      ),
    );

    if (updatedOshi == null) {
      return;
    }

    await widget.onChanged(updatedOshi);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '推し情報を更新しました！',
        ),
      ),
    );
  }

  Future<void> _graduateOshi() async {
    final oshi = widget.oshi;
    if (oshi.isGraduated || oshi.isManagementPaused) return;

    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: oshi.oshiStartDate ?? DateTime(1970, 1, 1),
      lastDate: now,
      locale: const Locale('ja', 'JP'),
      helpText: '卒業日を選択',
      confirmText: '確定',
      cancelText: 'キャンセル',
    );

    if (selected == null || !mounted) return;

    oshi.graduate(date: selected);
    await widget.onChanged(oshi);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${oshi.name}を過去の推しへ移動しました')),
    );
    widget.onBackToList();
  }

  Future<void> _deleteOshi() async {
    final oshi = widget.oshi;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('推しを削除'),
          content: Text(
            '${oshi.name}を削除しますか？\n誤登録を消すための操作です。削除したデータは元に戻せません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('削除する'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await widget.onDelete(oshi);
    if (!mounted) return;
    widget.onBackToList();
  }

  void _openFavoriteSong() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OshiFavoriteSongScreen(oshi: widget.oshi),
      ),
    );
  }

  void _openChekiHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OshiChekiHistoryScreen(oshi: widget.oshi),
      ),
    );
  }

  void _openEventHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OshiEventHistoryScreen(
          oshi: widget.oshi,
          events: widget.events,
        ),
      ),
    );
  }

  void _openTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OshiTimelineScreen(
          oshi: widget.oshi,
          events: widget.events,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oshi = widget.oshi;
    final memberColor = colorFromHex(oshi.memberColorHex) ?? purple;
    final memberTextColor = readableMemberColor(memberColor);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBackToList();
      },
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          backgroundColor: background,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: widget.onBackToList,
            icon: const Icon(Icons.arrow_back_rounded),
          ),

          title: const Text(
          '推し詳細',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          TextButton.icon(
            onPressed: widget.oshi.isManagementPaused ? null : _editOshi,
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
            ),
            label: const Text('編集'),
          ),
          PopupMenuButton<String>(
            tooltip: 'その他',
            onSelected: (value) {
              if (value == 'delete') _deleteOshi();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('推しを削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              30,
            ),
            children: [
              if (oshi.isManagementPaused) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2E8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCC7F7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.pause_circle_outline_rounded, color: purple),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '管理休止中・閲覧のみ',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Center(
                child: _OshiProfileAvatar(
                  oshi: oshi,
                  radius: 53,
                  iconSize: 60,
                ),
              ),

              const SizedBox(height: 12),

              if (oshi.isPrimary)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFB300),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '1推し',
                        style: TextStyle(
                          color: memberTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 5),

              Text(
                oshi.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: memberTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              Text(
                oshi.groupName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              if (oshi.memberColorHex != null) ...[
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: memberColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'メンバーカラー',
                      style: TextStyle(
                        color: memberTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
              if (oshi.isGraduated && oshi.graduatedAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  '卒業日：${oshi.graduatedAt!.year}年${oshi.graduatedAt!.month}月${oshi.graduatedAt!.day}日',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (!oshi.isGraduated && !oshi.isManagementPaused) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _graduateOshi,
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('卒業'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: memberTextColor,
                    side: BorderSide(color: memberColor.withOpacity(0.55)),
                  ),
                ),
              ],

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE9E0FA),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DetailStat(
                        title: '推し日数',
                        value: oshi.oshiDays == null
                            ? '未設定'
                            : '${oshi.oshiDays}日',
                      ),
                    ),

                    Expanded(
                      child: DetailStat(
                        title: '登録日数',
                        value: '${oshi.registeredDays}日',
                      ),
                    ),

                    const Expanded(
                      child: DetailStat(
                        title: 'ポイント',
                        value: '1 pt',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              DetailCard(
                icon: Icons.music_note_rounded,
                title: '好きな曲',
                value: oshi.favoriteSong,
                onTap: _openFavoriteSong,
              ),

              const SizedBox(height: 10),

              DetailCard(
                icon: Icons.photo_camera_rounded,
                title: 'チェキ',
                value: '撮影記録を見る',
                onTap: _openChekiHistory,
              ),

              const SizedBox(height: 10),

              DetailCard(
                icon: Icons.event_available_rounded,
                title: '参加イベント',
                value: '参加履歴を見る',
                onTap: _openEventHistory,
              ),

              const SizedBox(height: 10),

              DetailCard(
                icon: Icons.timeline_rounded,
                title: '推し年表',
                value: '記念日・活動履歴を見る',
                onTap: _openTimeline,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _OshiFavoriteSongScreen extends StatelessWidget {
  const _OshiFavoriteSongScreen({required this.oshi});

  final Oshi oshi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FF),
        title: Text('${oshi.name}の好きな曲',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE9E0FA)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFF2E8FF),
                      foregroundColor: Color(0xFF9B5CFF),
                      child: Icon(Icons.music_note_rounded),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('好きな曲',
                              style: TextStyle(color: Colors.black45)),
                          const SizedBox(height: 4),
                          Text(
                            oshi.favoriteSong,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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
}

class _OshiChekiHistoryScreen extends StatefulWidget {
  const _OshiChekiHistoryScreen({required this.oshi});

  final Oshi oshi;

  @override
  State<_OshiChekiHistoryScreen> createState() => _OshiChekiHistoryScreenState();
}

class _OshiChekiHistoryScreenState extends State<_OshiChekiHistoryScreen> {
  List<ChekiRecord> _values = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await ActivityStorage.loadChekis();
    if (!mounted) return;
    setState(() {
      _values = values
          .where((value) => value.memberNames.contains(widget.oshi.name))
          .toList()
        ..sort((a, b) => (b.shotAt ?? b.createdAt).compareTo(a.shotAt ?? a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FF),
        title: Text('${widget.oshi.name}のチェキ',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _values.isEmpty
          ? const Center(child: Text('まだチェキ記録がありません'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemCount: _values.length,
              itemBuilder: (context, index) {
                final value = _values[index];
                MemoryImage? image;
                if ((value.imageBase64 ?? '').isNotEmpty) {
                  try {
                    image = MemoryImage(base64Decode(value.imageBase64!));
                  } catch (_) {
                    image = null;
                  }
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE9E0FA)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: image == null
                            ? const ColoredBox(
                                color: Color(0xFFF2E8FF),
                                child: Icon(Icons.photo_camera_rounded,
                                    size: 46, color: Color(0xFF9B5CFF)),
                              )
                            : Image(image: image, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value.type.label,
                                style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              _simpleDate(value.shotAt ?? value.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _OshiEventHistoryScreen extends StatelessWidget {
  const _OshiEventHistoryScreen({required this.oshi, required this.events});

  final Oshi oshi;
  final List<OshiEvent> events;

  bool _matches(OshiEvent event) {
    if (event.primaryGroup == oshi.groupName) return true;
    if (event.wantedGroups.contains(oshi.groupName)) return true;
    if (event.performers.contains(oshi.groupName)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final values = events.where(_matches).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FF),
        title: Text('${oshi.name}の参加イベント',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: values.isEmpty
          ? const Center(child: Text('まだ参加イベントがありません'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = values[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE9E0FA)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF2E8FF),
                      foregroundColor: Color(0xFF9B5CFF),
                      child: Icon(Icons.event_rounded),
                    ),
                    title: Text(event.title,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('${_simpleDate(event.date)}・${event.venue.isEmpty ? '会場未定' : event.venue}'),
                  ),
                );
              },
            ),
    );
  }
}

class _OshiTimelineScreen extends StatelessWidget {
  const _OshiTimelineScreen({required this.oshi, required this.events});

  final Oshi oshi;
  final List<OshiEvent> events;

  bool _matches(OshiEvent event) {
    return event.primaryGroup == oshi.groupName ||
        event.wantedGroups.contains(oshi.groupName) ||
        event.performers.contains(oshi.groupName);
  }

  @override
  Widget build(BuildContext context) {
    final items = <(DateTime, String, IconData)>[];
    if (oshi.oshiStartDate != null) {
      items.add((oshi.oshiStartDate!, '推し始め', Icons.favorite_rounded));
    }
    for (final event in events.where(_matches)) {
      items.add((event.date, event.title, Icons.event_rounded));
    }
    if (oshi.graduatedAt != null) {
      items.add((oshi.graduatedAt!, '卒業', Icons.school_rounded));
    }
    items.sort((a, b) => b.$1.compareTo(a.$1));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FF),
        title: Text('${oshi.name}の推し年表',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: items.isEmpty
          ? const Center(child: Text('年表に表示する記録がありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF2E8FF),
                          child: Icon(item.$3, size: 18, color: const Color(0xFF9B5CFF)),
                        ),
                        if (index != items.length - 1)
                          Container(width: 2, height: 54, color: const Color(0xFFE9E0FA)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_simpleDate(item.$1),
                                style: const TextStyle(fontSize: 12, color: Colors.black45)),
                            const SizedBox(height: 3),
                            Text(item.$2,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

String _simpleDate(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

// ===========================================================
// 共通パーツ
// ===========================================================

class _OshiProfileAvatar extends StatelessWidget {
  const _OshiProfileAvatar({
    required this.oshi,
    required this.radius,
    required this.iconSize,
  });

  final Oshi oshi;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    MemoryImage? image;
    final encoded = oshi.profilePhotoBase64;

    if (encoded != null && encoded.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(encoded));
      } catch (_) {
        image = null;
      }
    }

    final memberColor = colorFromHex(oshi.memberColorHex) ?? _MainScreenState.purple;
    return CircleAvatar(
      radius: radius,
      backgroundColor: softMemberColor(memberColor),
      backgroundImage: image,
      child: image == null
          ? Icon(
              Icons.person_rounded,
              color: readableMemberColor(memberColor),
              size: iconSize,
            )
          : null,
    );
  }
}

class OshiListTile extends StatelessWidget {
  final Oshi oshi;

  const OshiListTile({
    super.key,
    required this.oshi,
  });

  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 280;
        final avatarRadius = compact ? 22.0 : 27.0;
        final memberColor = colorFromHex(oshi.memberColorHex) ?? purple;
        final memberTextColor = readableMemberColor(memberColor);

        return Row(
          children: [
            _OshiProfileAvatar(
              oshi: oshi,
              radius: avatarRadius,
              iconSize: compact ? 26 : 30,
            ),

            SizedBox(width: compact ? 9 : 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (oshi.isManagementPaused)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: lightPurple,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '管理休止中・閲覧のみ',
                        style: TextStyle(
                          color: purple,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (oshi.isPrimary)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: compact ? 15 : 17,
                          color: const Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '1推し',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: purple,
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 11 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                  Text(
                    oshi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: memberTextColor,
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  Text(
                    oshi.groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black38,
              size: compact ? 20 : 24,
            ),
          ],
        );
      },
    );
  }
}

class MoneyItem extends StatelessWidget {
  final String label;
  final String value;

  const MoneyItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(height: 3),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OshiStat extends StatelessWidget {
  final String label;
  final String value;

  const OshiStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black45,
              ),
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailStat extends StatelessWidget {
  final String title;
  final String value;

  const DetailStat({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black45,
              ),
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const DetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE9E0FA),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E8FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF9B5CFF),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
