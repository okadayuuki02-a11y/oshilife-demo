import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../models/oshi_event.dart';
import '../services/image_analysis.dart';

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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _routeCard(
                context,
                number: '1',
                icon: Icons.search_rounded,
                title: 'イベントを検索して追加',
                subtitle: 'OshiLifeに登録済みのイベントを探して、そのまま予定に追加',
                onTap: () =>
                    _openRoute(context, const SharedEventSearchScreen()),
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
    final event = await Navigator.of(context)
        .push<OshiEvent>(MaterialPageRoute(builder: (_) => screen));

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
  State<SharedEventSearchScreen> createState() =>
      _SharedEventSearchScreenState();
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
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

class OcrEventScreen extends StatefulWidget {
  const OcrEventScreen({super.key});

  @override
  State<OcrEventScreen> createState() => _OcrEventScreenState();
}

class _OcrEventScreenState extends State<OcrEventScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  bool _loading = false;

  Future<void> _selectAndAnalyze() async {
    if (_loading) return;
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2600,
      imageQuality: 92,
    );
    if (image == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final result = await ImageAnalysisService.analyzeEvent(
        await image.readAsBytes(),
      );
      if (!mounted) return;

      final candidate = OshiEvent(
        title: result.title.trim().isEmpty ? 'イベント' : result.title.trim(),
        date: result.date ?? DateTime.now(),
        venue: result.venue,
        openTime: result.openTime,
        startTime: result.startTime,
        endTime: result.endTime,
        performers: result.performers,
        timetable: result.schedule,
        url: result.url,
      );

      final confirmed = await Navigator.of(context).push<OshiEvent>(
        MaterialPageRoute(
          builder: (_) => ManualEventScreen(initialEvent: candidate),
        ),
      );
      if (confirmed != null && mounted) {
        Navigator.of(context).pop(confirmed);
      }
    } on ImageAnalysisUnavailable catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('AI画像解析へ切り替え中'),
          content: Text(
            '${error.message}\n\n旧OCRのように文字を読むだけではなく、イベント名・日時・会場・出演者・タイムテーブルを項目として理解して返す方式にします。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _loading ? null : _selectAndAnalyze,
                child: Container(
                  height: 210,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE8E0F7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_loading)
                        const CircularProgressIndicator(color: purple)
                      else
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: purple,
                          size: 52,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        _loading ? '画像を解析中…' : 'イベント画像を選択',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '告知画像・タイムテーブル・X投稿スクショなど',
                        style: TextStyle(color: Color(0xFF716B78)),
                      ),
                    ],
                  ),
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
                  '画像 → AI解析 → 候補を手入力画面で確認・修正 → 登録\n\n解析エンジンは交換可能な構造にしているため、将来は端末内AIやOCR＋判定方式へ差し替えても画面・保存データはそのまま使えます。',
                  style: TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '※ update12修正版では、精度が低かった旧OCRを停止しています。AI解析APIの接続後にこの画面からそのまま使えるようになります。',
                style: TextStyle(
                  fontSize: 12,
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
}

enum _TimeField { open, start, end }

class _CompactTimeResult {
  const _CompactTimeResult.time(this.time) : clear = false;
  const _CompactTimeResult.clear() : time = null, clear = true;

  final TimeOfDay? time;
  final bool clear;
}

class ManualEventScreen extends StatefulWidget {
  const ManualEventScreen({super.key, this.initialEvent});

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
  final _url = TextEditingController();
  final _memo = TextEditingController();
  final _drinkAmount = TextEditingController();
  final _drinkMemo = TextEditingController();
  final _releaseName = TextEditingController();
  final _serviceName = TextEditingController();
  final _participationMethod = TextEditingController();
  String? _flyer;
  bool _drinkRequired = false;
  bool _drinkMandatory = true;
  bool _drinkIncluded = false;
  List<EventScheduleEntry> _schedule = [];
  List<EventParticipationSlot> _participationSlots = [];
  Set<SpecialActivityType> _specialActivities = <SpecialActivityType>{};
  SpecialEventFormat _specialFormat = SpecialEventFormat.faceToFace;

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
    _url.text = initial.url;
    _memo.text = initial.memo;
    _drinkAmount.text = initial.drinkAmount?.toString() ?? '';
    _drinkMemo.text = initial.drinkMemo;
    _releaseName.text = initial.releaseName;
    _serviceName.text = initial.serviceName;
    _participationMethod.text = initial.participationMethod;
    _drinkRequired = initial.drinkRequired;
    _drinkMandatory = initial.drinkMandatory;
    _drinkIncluded = initial.drinkIncluded;
    _flyer = initial.flyerBase64;
    _schedule = List.of(initial.mySchedule);
    _participationSlots = List.of(initial.participationSlots);
    _specialActivities = initial.specialActivities.toSet();
    _specialFormat = initial.specialFormat;
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
    _url.dispose();
    _memo.dispose();
    _drinkAmount.dispose();
    _drinkMemo.dispose();
    _releaseName.dispose();
    _serviceName.dispose();
    _participationMethod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpecial = _eventType == OshiEventType.specialEvent;

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
              _eventTypePicker(),
              const SizedBox(height: 12),

              if (isSpecial) ...[
                _specialEventSection(),
                const SizedBox(height: 12),
                _pickerTile(
                  icon: Icons.calendar_month_rounded,
                  title: '日付',
                  value: '${_date.year}/${_date.month}/${_date.day}',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                _field(
                  _venueController,
                  _specialFormat == SpecialEventFormat.online
                      ? '利用サービス・会場名'
                      : '会場',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward_rounded, color: purple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ここではイベント本体だけ作ります。保存後のイベント詳細から、参加する部・メンバー・時間・所持枚数を追加できます。',
                          style: TextStyle(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _field(_titleController, 'イベント名', Icons.event_rounded),
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
                _field(
                  _performersController,
                  '出演者（カンマ区切り）',
                  Icons.groups_rounded,
                ),
                const SizedBox(height: 12),
                _field(
                  _primaryController,
                  'お目当てグループ（任意）',
                  Icons.favorite_rounded,
                ),
                const SizedBox(height: 12),
                _field(_url, 'イベントURL（任意）', Icons.link),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFlyer,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_flyer == null ? 'フライヤーを選ぶ' : 'フライヤー選択済み・変更'),
                ),
                if (_flyer != null)
                  Image.memory(base64Decode(_flyer!), height: 120),
                const SizedBox(height: 12),
                _field(_memo, 'イベントメモ', Icons.note_alt_outlined),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '当日のスケジュール',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addSchedule,
                      icon: const Icon(Icons.add),
                      label: const Text('時間＋内容を追加'),
                    ),
                  ],
                ),
                for (var i = 0; i < _schedule.length; i++)
                  ListTile(
                    title: Text(
                      '${_timeText(_schedule[i].startTime)}  ${_schedule[i].title}',
                    ),
                    subtitle: Text(_schedule[i].label),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _schedule.removeAt(i)),
                    ),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('ドリンク代あり'),
                  value: _drinkRequired,
                  onChanged: (v) => setState(() => _drinkRequired = v),
                ),
                if (_drinkRequired) ...[
                  _field(_drinkAmount, 'ドリンク代（金額）', Icons.currency_yen),
                  SwitchListTile(
                    title: const Text('必須'),
                    value: _drinkMandatory,
                    onChanged: (v) => setState(() => _drinkMandatory = v),
                  ),
                  SwitchListTile(
                    title: const Text('チケット代に含む'),
                    value: _drinkIncluded,
                    onChanged: (v) => setState(() => _drinkIncluded = v),
                  ),
                  _field(_drinkMemo, 'ドリンク代メモ', Icons.edit_note),
                ],
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF716B78),
                    height: 1.45,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  _isEditing
                      ? '変更を保存'
                      : isSpecial
                          ? '登録して参加する部を追加'
                          : '登録してイベント詳細へ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFlyer() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
    );
    if (photo == null) return;
    final encoded = base64Encode(await photo.readAsBytes());
    if (mounted) setState(() => _flyer = encoded);
  }

  Future<void> _addSchedule() async {
    final content = TextEditingController();
    var time = const TimeOfDay(hour: 18, minute: 0);
    var label = 'ライブ';
    final entry = await showDialog<EventScheduleEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('予定を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: content,
                decoration: const InputDecoration(labelText: '内容'),
              ),
              ListTile(
                title: Text('時刻 ${_timeText(time)}'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: time,
                  );
                  if (picked != null) update(() => time = picked);
                },
              ),
              DropdownButton<String>(
                value: label,
                isExpanded: true,
                items: ['ライブ', '整列', 'OPEN', '物販', '特典会', 'お話会', '握手会', 'ミーグリ', '撮影', 'サイン', 'ステージ', 'ブース', 'その他']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => update(() => label = v ?? label),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (content.text.trim().isNotEmpty) {
                  Navigator.pop(
                    ctx,
                    EventScheduleEntry(
                      title: content.text.trim(),
                      startTime: time,
                      label: label,
                    ),
                  );
                }
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
    content.dispose();
    if (entry != null && mounted) setState(() => _schedule.add(entry));
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF716B78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OshiEventType.values.map((value) {
              final selected = _eventType == value;
              return ChoiceChip(
                label: Text(value.label),
                selected: selected,
                selectedColor: lightPurple,
                side: BorderSide(
                  color: selected ? purple : const Color(0xFFE8E0F7),
                ),
                onSelected: (_) => setState(() {
                  _eventType = value;
                  if (value == OshiEventType.specialEvent &&
                      _specialActivities.isEmpty) {
                    _specialActivities = <SpecialActivityType>{
                      SpecialActivityType.talk,
                    };
                  }
                }),
              );
            }).toList(),
          ),
          if (_eventType == OshiEventType.festival) ...[
            const SizedBox(height: 8),
            const Text(
              'フェスは全体タイテとMy予定を並行して管理できます。',
              style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
            ),
          ],
          if (_eventType == OshiEventType.specialEvent) ...[
            const SizedBox(height: 8),
            const Text(
              '握手会・お話会・ミーグリ・撮影会など、部ごとの参加枠を管理します。',
              style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _specialEventSection() {
    final selectedActivity = _specialActivities.isEmpty
        ? null
        : _specialActivities.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: purple),
              SizedBox(width: 8),
              Text(
                '特典会の種類',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'まずイベント本体だけ登録します。参加する部は次の画面で追加できます。',
            style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: SpecialActivityType.values.map((value) {
              final selected = selectedActivity == value;
              return ChoiceChip(
                label: Text(value.label),
                selected: selected,
                selectedColor: lightPurple,
                onSelected: (_) {
                  setState(() {
                    _specialActivities = <SpecialActivityType>{value};
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            '開催形式',
            style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [
                SpecialEventFormat.faceToFace,
                SpecialEventFormat.online,
              ])
                ChoiceChip(
                  label: Text(value.label),
                  selected: _specialFormat == value,
                  selectedColor: lightPurple,
                  onSelected: (_) => setState(() => _specialFormat = value),
                ),
            ],
          ),
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
        side: BorderSide(color: selected ? purple : const Color(0xFFE8E0F7)),
      ),
      child: RadioListTile<EventVisibility>(
        value: value,
        groupValue: _visibility,
        activeColor: purple,
        title: Row(
          children: [
            Icon(value.icon, color: purple, size: 20),
            const SizedBox(width: 8),
            Text(
              value.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedMinute,
                        decoration: const InputDecoration(
                          labelText: '分',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) {
                          final minute = index * 5;
                          return DropdownMenuItem(
                            value: minute,
                            child: Text(minute.toString().padLeft(2, '0')),
                          );
                        }),
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
                  onPressed: () =>
                      Navigator.of(dialogContext)
                          .pop(const _CompactTimeResult.clear()),
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

    final isSpecial = _eventType == OshiEventType.specialEvent;
    final selectedActivity = _specialActivities.isEmpty
        ? SpecialActivityType.talk
        : _specialActivities.first;
    final specialTitle =
        '${selectedActivity.label} ${_date.month}/${_date.day}';

    final event = OshiEvent(
      id: initial?.id,
      title: isSpecial
          ? specialTitle
          : (_titleController.text.trim().isEmpty
                ? '新しいイベント'
                : _titleController.text.trim()),
      date: DateTime(_date.year, _date.month, _date.day),
      venue: _venueController.text.trim(),
      type: _eventType,
      openTime: isSpecial ? null : _openTime,
      startTime: isSpecial ? null : _startTime,
      endTime: isSpecial ? null : _endTime,
      performers: isSpecial ? const [] : performers,
      timetable: initial?.timetable ?? const [],
      primaryGroup: isSpecial ? null : (primary.isEmpty ? null : primary),
      wantedGroups: isSpecial ? const [] : wantedGroups,
      mySchedule: isSpecial ? const [] : _schedule,
      url: isSpecial ? '' : _url.text.trim(),
      flyerBase64: isSpecial ? null : _flyer,
      memo: isSpecial ? '' : _memo.text.trim(),
      drinkRequired: isSpecial ? false : _drinkRequired,
      drinkAmount: isSpecial
          ? null
          : int.tryParse(_drinkAmount.text.replaceAll(',', '').trim()),
      drinkMandatory: _drinkMandatory,
      drinkIncluded: _drinkIncluded,
      drinkMemo: isSpecial ? '' : _drinkMemo.text.trim(),
      specialFormat: _specialFormat,
      specialActivities: isSpecial
          ? <SpecialActivityType>[selectedActivity]
          : const [],
      releaseName: '',
      serviceName: '',
      participationMethod: '',
      participationSlots: initial?.participationSlots ?? _participationSlots,
      ticketStatus: initial?.ticketStatus ?? '未設定',
      ticketAmount: initial?.ticketAmount,
      visibility: isSpecial ? EventVisibility.private : _visibility,
    );

    Navigator.of(context).pop(event);
  }
}
