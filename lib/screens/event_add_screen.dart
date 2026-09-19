import 'package:flutter/material.dart';

import '../models/oshi_event.dart';

class EventAddScreen extends StatelessWidget {
  const EventAddScreen({super.key});

  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'イベントを追加',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const Text(
                'なるべく入力しなくていい方法から選べます',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _routeCard(
                context,
                number: '1',
                icon: Icons.search_rounded,
                title: 'イベントを検索して追加',
                subtitle: 'OshiLifeに登録済みのイベントを探して、そのまま予定に追加',
                onTap: () => _openRoute(context, const SharedEventSearchScreen()),
              ),
              const SizedBox(height: 12),
              _routeCard(
                context,
                number: '2',
                icon: Icons.document_scanner_rounded,
                title: '画像から登録',
                subtitle: '告知・タイテ・X投稿・DM・LINE・メール等の画像から読み取り',
                onTap: () => _openRoute(context, const OcrEventScreen()),
              ),
              const SizedBox(height: 12),
              _routeCard(
                context,
                number: '3',
                icon: Icons.edit_calendar_rounded,
                title: '手入力で登録',
                subtitle: '検索や画像が使えないイベントを自分で入力',
                onTap: () => _openRoute(context, const ManualEventScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRoute(BuildContext context, Widget screen) async {
    final event = await Navigator.of(context).push<OshiEvent>(
      MaterialPageRoute(builder: (_) => screen),
    );

    if (event == null || !context.mounted) return;
    Navigator.of(context).pop(event);
  }

  Widget _routeCard(
    BuildContext context, {
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8E0F7)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: purple, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number  $title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF716B78),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedEventSearchScreen extends StatefulWidget {
  const SharedEventSearchScreen({super.key});

  @override
  State<SharedEventSearchScreen> createState() => _SharedEventSearchScreenState();
}

class _SharedEventSearchScreenState extends State<SharedEventSearchScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const background = Color(0xFFFFF8FF);

  final _controller = TextEditingController();

  final OshiEvent sample = OshiEvent(
    title: 'TOKYO IDOL LIVE 2026',
    date: DateTime(2026, 9, 12),
    venue: '渋谷○○ホール',
    openTime: const TimeOfDay(hour: 17, minute: 0),
    startTime: const TimeOfDay(hour: 17, minute: 30),
    performers: const ['AQUA PLANET', 'Stella!', 'Lumière', 'CODE:IRiS'],
    primaryGroup: 'AQUA PLANET',
    wantedGroups: const ['AQUA PLANET', 'Stella!'],
    timetable: const [
      EventScheduleEntry(
        title: 'AQUA PLANET',
        startTime: TimeOfDay(hour: 18, minute: 10),
        endTime: TimeOfDay(hour: 18, minute: 30),
      ),
      EventScheduleEntry(
        title: 'Stella!',
        startTime: TimeOfDay(hour: 19, minute: 0),
        endTime: TimeOfDay(hour: 19, minute: 20),
      ),
    ],
    visibility: EventVisibility.shared,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'イベント検索',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '例：9/12 東京、AQUA PLANET',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('日付')),
                  Chip(label: Text('地域')),
                  Chip(label: Text('イベント形式')),
                  Chip(label: Text('出演者')),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '検索イメージ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8E0F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text('9/12（土） 17:00 OPEN / 17:30 START'),
                    const SizedBox(height: 4),
                    Text('📍 ${sample.venue}'),
                    const SizedBox(height: 4),
                    Text("出演：${sample.performers.join(' / ')}"),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(sample),
                        style: FilledButton.styleFrom(backgroundColor: purple),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('予定に追加'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '※ この画面は導線確認用です。共有イベントDBへの実接続は次段階で行います。',
                style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OcrEventScreen extends StatelessWidget {
  const OcrEventScreen({super.key});

  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  OshiEvent get sample => OshiEvent(
        title: 'IDOL CROSSING',
        date: DateTime(2026, 9, 21),
        venue: 'Spotify O-EAST',
        openTime: const TimeOfDay(hour: 16, minute: 0),
        startTime: const TimeOfDay(hour: 16, minute: 30),
        performers: const ['AQUA PLANET', 'MOONLiGHT', 'Stella!'],
        timetable: const [
          EventScheduleEntry(
            title: 'AQUA PLANET',
            startTime: TimeOfDay(hour: 17, minute: 10),
            endTime: TimeOfDay(hour: 17, minute: 30),
          ),
          EventScheduleEntry(
            title: 'Stella!',
            startTime: TimeOfDay(hour: 17, minute: 40),
            endTime: TimeOfDay(hour: 18, minute: 0),
          ),
          EventScheduleEntry(
            title: 'MOONLiGHT',
            startTime: TimeOfDay(hour: 18, minute: 15),
            endTime: TimeOfDay(hour: 18, minute: 35),
          ),
        ],
        primaryGroup: 'AQUA PLANET',
        wantedGroups: const ['AQUA PLANET', 'MOONLiGHT'],
        mySchedule: const [
          EventScheduleEntry(
            title: 'AQUA PLANET',
            startTime: TimeOfDay(hour: 19, minute: 30),
            endTime: TimeOfDay(hour: 20, minute: 30),
            label: '特典会',
            note: '場所：特典会エリアA',
          ),
        ],
        visibility: EventVisibility.shared,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '画像から登録',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8E0F7), width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search_rounded, color: purple, size: 52),
                    SizedBox(height: 12),
                    Text(
                      'イベント情報が写った画像を選択',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '告知・タイテ・X・DM・LINE・メール等に対応予定',
                      style: TextStyle(color: Color(0xFF716B78)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '画像選択 → 読み取り → 確認・修正 → 登録\n\nDM・LINE・メールなど個別連絡の画像も登録できます。個人的な連絡と判断した画像は「完全非公開」を初期候補にし、元画像やDM本文を共有イベントへ自動公開することはありません。\n\n※ 実際のOCR処理は後から接続します。',
                  style: TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(sample),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('読み取り結果のデモを予定に追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TimeField { open, start, end }

class _CompactTimeResult {
  const _CompactTimeResult.time(this.time) : clear = false;
  const _CompactTimeResult.clear() : time = null, clear = true;

  final TimeOfDay? time;
  final bool clear;
}

class ManualEventScreen extends StatefulWidget {
  const ManualEventScreen({
    super.key,
    this.initialEvent,
  });

  final OshiEvent? initialEvent;

  @override
  State<ManualEventScreen> createState() => _ManualEventScreenState();
}

class _ManualEventScreenState extends State<ManualEventScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _performersController = TextEditingController();
  final _primaryController = TextEditingController();

  EventVisibility _visibility = EventVisibility.shared;
  OshiEventType _eventType = OshiEventType.taiban;
  DateTime _date = DateTime.now();
  TimeOfDay? _openTime;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialEvent;
    if (initial == null) return;

    _titleController.text = initial.title;
    _venueController.text = initial.venue;
    _performersController.text = initial.performers.join('、');
    _primaryController.text = initial.primaryGroup ?? '';
    _visibility = initial.visibility;
    _eventType = initial.type;
    _date = initial.date;
    _openTime = initial.openTime;
    _startTime = initial.startTime;
    _endTime = initial.endTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _performersController.dispose();
    _primaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isEditing ? 'イベントを編集' : '手入力で登録',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(_titleController, 'イベント名', Icons.event_rounded),
              const SizedBox(height: 12),
              _eventTypePicker(),
              const SizedBox(height: 12),
              _pickerTile(
                icon: Icons.calendar_month_rounded,
                title: '日付',
                value: '${_date.year}/${_date.month}/${_date.day}',
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      icon: Icons.door_front_door_outlined,
                      title: 'OPEN',
                      value: _timeText(_openTime),
                      onTap: () => _pickCompactTime(_TimeField.open),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pickerTile(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'START',
                      value: _timeText(_startTime),
                      onTap: () => _pickCompactTime(_TimeField.start),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pickerTile(
                      icon: Icons.flag_outlined,
                      title: 'END',
                      value: _timeText(_endTime),
                      onTap: () => _pickCompactTime(_TimeField.end),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_venueController, '会場（任意）', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _field(_performersController, '出演者（カンマ区切り）', Icons.groups_rounded),
              const SizedBox(height: 12),
              _field(_primaryController, 'お目当てグループ（任意）', Icons.favorite_rounded),
              const SizedBox(height: 20),
              const Text(
                '公開範囲',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...EventVisibility.values.map(_visibilityTile),
              const SizedBox(height: 6),
              const Text(
                '※ お目当て・見たい・支出・チェキ・トークログ・メモなどの個人記録は、どの設定でも共有されません。',
                style: TextStyle(fontSize: 12, color: Color(0xFF716B78), height: 1.45),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(_isEditing ? '変更を保存' : '登録してイベント詳細へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E0F7)),
          ),
          child: Row(
            children: [
              Icon(icon, color: purple, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF716B78)),
                    ),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventTypePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'イベント種類',
            style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
          ),
          const SizedBox(height: 8),
          SegmentedButton<OshiEventType>(
            segments: OshiEventType.values
                .map(
                  (value) => ButtonSegment<OshiEventType>(
                    value: value,
                    label: Text(value.label),
                  ),
                )
                .toList(),
            selected: {_eventType},
            showSelectedIcon: false,
            onSelectionChanged: (values) {
              if (values.isEmpty) return;
              setState(() => _eventType = values.first);
            },
          ),
          if (_eventType == OshiEventType.festival) ...[
            const SizedBox(height: 8),
            const Text(
              'フェスは全体タイテ／My予定／特典会を使える土台を先に用意します。',
              style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _visibilityTile(EventVisibility value) {
    final selected = _visibility == value;
    return Card(
      color: selected ? lightPurple : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? purple : const Color(0xFFE8E0F7),
        ),
      ),
      child: RadioListTile<EventVisibility>(
        value: value,
        groupValue: _visibility,
        activeColor: purple,
        title: Row(
          children: [
            Icon(value.icon, color: purple, size: 20),
            const SizedBox(width: 8),
            Text(value.label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value.description),
        ),
        onChanged: (newValue) {
          if (newValue == null) return;
          setState(() => _visibility = newValue);
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('ja', 'JP'),
    );

    if (selected == null || !mounted) return;
    setState(() => _date = selected);
  }

  Future<void> _pickCompactTime(_TimeField field) async {
    final current = switch (field) {
      _TimeField.open => _openTime ?? const TimeOfDay(hour: 17, minute: 0),
      _TimeField.start => _startTime ?? const TimeOfDay(hour: 18, minute: 0),
      _TimeField.end => _endTime ?? const TimeOfDay(hour: 20, minute: 0),
    };

    var selectedHour = current.hour;
    var selectedMinute = (current.minute ~/ 5) * 5;

    final result = await showDialog<_CompactTimeResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${_timeFieldLabel(field)}の時間'),
              content: SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedHour,
                        decoration: const InputDecoration(
                          labelText: '時',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          24,
                          (hour) => DropdownMenuItem(
                            value: hour,
                            child: Text(hour.toString().padLeft(2, '0')),
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedHour = value);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        ':',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMinute,
                        decoration: const InputDecoration(
                          labelText: '分',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          12,
                          (index) {
                            final minute = index * 5;
                            return DropdownMenuItem(
                              value: minute,
                              child: Text(minute.toString().padLeft(2, '0')),
                            );
                          },
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedMinute = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    const _CompactTimeResult.clear(),
                  ),
                  child: const Text('未設定'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: purple),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      _CompactTimeResult.time(
                        TimeOfDay(hour: selectedHour, minute: selectedMinute),
                      ),
                    );
                  },
                  child: const Text('決定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      final value = result.clear ? null : result.time;
      switch (field) {
        case _TimeField.open:
          _openTime = value;
          break;
        case _TimeField.start:
          _startTime = value;
          break;
        case _TimeField.end:
          _endTime = value;
          break;
      }
    });
  }

  String _timeFieldLabel(_TimeField field) {
    return switch (field) {
      _TimeField.open => 'OPEN',
      _TimeField.start => 'START',
      _TimeField.end => 'END',
    };
  }

  String _timeText(TimeOfDay? time) {
    if (time == null) return '未設定';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _save() {
    final performers = _performersController.text
        .split(RegExp(r'[,、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final primary = _primaryController.text.trim();
    final initial = widget.initialEvent;

    final wantedGroups = initial == null
        ? (primary.isEmpty ? <String>[] : <String>[primary])
        : <String>[...initial.wantedGroups];

    if (primary.isNotEmpty && !wantedGroups.contains(primary)) {
      wantedGroups.add(primary);
    }

    final event = OshiEvent(
      id: initial?.id,
      title: _titleController.text.trim().isEmpty
          ? '新しいイベント'
          : _titleController.text.trim(),
      date: DateTime(_date.year, _date.month, _date.day),
      venue: _venueController.text.trim(),
      type: _eventType,
      openTime: _openTime,
      startTime: _startTime,
      endTime: _endTime,
      performers: performers,
      timetable: initial?.timetable ?? const [],
      primaryGroup: primary.isEmpty ? null : primary,
      wantedGroups: wantedGroups,
      mySchedule: initial?.mySchedule ?? const [],
      ticketStatus: initial?.ticketStatus ?? '未設定',
      ticketAmount: initial?.ticketAmount,
      visibility: _visibility,
    );

    Navigator.of(context).pop(event);
  }
}
