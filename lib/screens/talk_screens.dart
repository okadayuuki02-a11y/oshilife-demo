import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/activity_models.dart';
import '../models/oshi.dart';
import '../models/oshi_event.dart';
import '../services/activity_storage.dart';

const _purple = Color(0xFF9B5CFF);
const _background = Color(0xFFFFF8FF);

String _day(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class EventTalkScreen extends TalkListScreen {
  const EventTalkScreen({
    super.key,
    required super.event,
    required super.oshis,
    required super.onChanged,
  });
}

class TalkListScreen extends StatefulWidget {
  const TalkListScreen({
    super.key,
    this.event,
    this.memberName,
    this.oshis = const [],
    this.onChanged,
  });
  final OshiEvent? event;
  final String? memberName;
  final List<Oshi> oshis;
  final Future<void> Function()? onChanged;

  @override
  State<TalkListScreen> createState() => _TalkListScreenState();
}

class _TalkListScreenState extends State<TalkListScreen> {
  List<TalkLog> _talks = [];
  List<ChekiRecord> _chekis = [];
  final _query = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  bool? _hasCheki;
  bool? _hasImage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final talks = await ActivityStorage.loadTalks();
    final chekis = await ActivityStorage.loadChekis();
    if (!mounted) return;
    setState(() {
      _talks =
          talks
              .where(
                (t) =>
                    (widget.event == null || t.eventId == widget.event!.id) &&
                    (widget.memberName == null ||
                        t.participantNames.contains(widget.memberName)),
              )
              .toList()
            ..sort((a, b) => b.talkedAt.compareTo(a.talkedAt));
      _chekis = chekis;
    });
  }

  List<TalkLog> get _filtered => _talks.where((t) {
    final q = _query.text.trim().toLowerCase();
    final allText = [
      t.sessionLabel,
      t.eventName,
      ...t.participantNames,
      ...t.messages.map((m) => m.text),
    ].join(' ').toLowerCase();
    final date = DateTime(t.talkedAt.year, t.talkedAt.month, t.talkedAt.day);
    return (q.isEmpty || allText.contains(q)) &&
        (_from == null || !date.isBefore(_from!)) &&
        (_to == null || !date.isAfter(_to!)) &&
        (_hasCheki == null || t.chekiIds.isNotEmpty == _hasCheki) &&
        (_hasImage == null || t.imagesBase64.isNotEmpty == _hasImage);
  }).toList();

  Future<void> _edit([TalkLog? initial]) async {
    final value = await Navigator.of(context).push<TalkLog>(
      MaterialPageRoute(
        builder: (_) => TalkEditScreen(
          event: widget.event,
          oshis: widget.oshis,
          chekis: _chekis,
          initial: initial,
          preselectedMember: widget.memberName,
        ),
      ),
    );
    if (value == null) return;
    try {
      await ActivityStorage.saveTalk(value);
      await widget.onChanged?.call();
      await _reload();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('トークを保存できませんでした。画像の枚数や保存容量を確認してください')),
        );
    }
  }

  Future<void> _delete(TalkLog talk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('トークを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('戻る'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ActivityStorage.deleteTalk(talk.id);
    await widget.onChanged?.call();
    await _reload();
  }

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(() {
        if (start) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TalkLog>>{};
    for (final talk in _filtered) {
      groups.putIfAbsent(_day(talk.talkedAt), () => []).add(talk);
    }
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          widget.memberName == null ? 'トーク' : '${widget.memberName}のトーク',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('トーク追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: '題名・イベント・メンバー・本文を検索',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(_from == null ? '開始日' : _day(_from!)),
                onPressed: () => _pickDate(true),
              ),
              ActionChip(
                label: Text(_to == null ? '終了日' : _day(_to!)),
                onPressed: () => _pickDate(false),
              ),
              if (_from != null || _to != null)
                ActionChip(
                  label: const Text('期間を解除'),
                  onPressed: () => setState(() {
                    _from = null;
                    _to = null;
                  }),
                ),
              FilterChip(
                label: const Text('チェキあり'),
                selected: _hasCheki == true,
                onSelected: (v) => setState(() => _hasCheki = v ? true : null),
              ),
              FilterChip(
                label: const Text('チェキなし'),
                selected: _hasCheki == false,
                onSelected: (v) => setState(() => _hasCheki = v ? false : null),
              ),
              FilterChip(
                label: const Text('画像あり'),
                selected: _hasImage == true,
                onSelected: (v) => setState(() => _hasImage = v ? true : null),
              ),
              FilterChip(
                label: const Text('画像なし'),
                selected: _hasImage == false,
                onSelected: (v) => setState(() => _hasImage = v ? false : null),
              ),
            ],
          ),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('該当するトークはありません')),
            ),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final talk in entry.value)
              Card(
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${talk.participantNames.join('・')} ${talk.sessionLabel}'
                        .trim(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      if (talk.eventName.isNotEmpty) talk.eventName,
                      if (talk.messages.isNotEmpty) talk.messages.last.text,
                      if (talk.chekiIds.isNotEmpty)
                        'チェキ${talk.chekiIds.length}枚',
                      if (talk.imagesBase64.isNotEmpty)
                        '画像${talk.imagesBase64.length}枚',
                    ].join('・'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _delete(talk),
                  ),
                  onTap: () => _edit(talk),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class TalkEditScreen extends StatefulWidget {
  const TalkEditScreen({
    super.key,
    this.event,
    this.oshis = const [],
    this.chekis = const [],
    this.initial,
    this.preselectedChekiIds,
    this.preselectedMember,
  });
  final OshiEvent? event;
  final List<Oshi> oshis;
  final List<ChekiRecord> chekis;
  final TalkLog? initial;
  final List<String>? preselectedChekiIds;
  final String? preselectedMember;
  @override
  State<TalkEditScreen> createState() => _TalkEditScreenState();
}

class _TalkEditScreenState extends State<TalkEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _eventName;
  late final TextEditingController _memo;
  late final TextEditingController _newMember;
  final _message = TextEditingController();
  late DateTime _date;
  late Set<String> _members;
  late Set<String> _chekiIds;
  late List<String> _images;
  late List<TalkMessage> _messages;
  TalkEntryKind _kind = TalkEntryKind.self;
  String? _speaker;
  bool _chatStep = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _title = TextEditingController(text: t?.sessionLabel ?? '');
    _eventName = TextEditingController(
      text: t?.eventName ?? widget.event?.title ?? '',
    );
    _memo = TextEditingController(text: t?.memo ?? '');
    _newMember = TextEditingController();
    _date = t?.talkedAt ?? widget.event?.date ?? DateTime.now();
    _members =
        (t?.participantNames ??
                [
                  if (widget.preselectedMember != null)
                    widget.preselectedMember!,
                ])
            .toSet();
    _chekiIds = (t?.chekiIds ?? widget.preselectedChekiIds ?? []).toSet();
    _images = List.of(t?.imagesBase64 ?? []);
    _messages = List.of(t?.messages ?? []);
    _speaker = _members.isEmpty ? null : _members.first;
    _chatStep = t != null;
  }

  @override
  void dispose() {
    _title.dispose();
    _eventName.dispose();
    _memo.dispose();
    _newMember.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 55,
      maxWidth: 900,
      maxHeight: 1200,
    );
    if (files.isEmpty) return;
    final result = <String>[];
    for (final file in files) {
      result.add(base64Encode(await file.readAsBytes()));
    }
    if (mounted) setState(() => _images.addAll(result));
  }

  void _addMember() {
    final name = _newMember.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _members.add(name);
      _newMember.clear();
      _speaker ??= name;
    });
  }

  void _send() {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    if (_kind == TalkEntryKind.member && _speaker == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先にメンバーを登録してください')));
      return;
    }
    setState(() {
      _messages.add(
        TalkMessage(
          kind: _kind,
          speaker: _kind == TalkEntryKind.member
              ? _speaker!
              : _kind == TalkEntryKind.self
              ? '自分'
              : _kind.name,
          text: text,
          order: _messages.length,
        ),
      );
      _message.clear();
    });
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _chatStep = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('題名を入力してください')));
      return;
    }
    Navigator.pop(
      context,
      TalkLog(
        id: widget.initial?.id,
        eventId: widget.event?.id ?? widget.initial?.eventId ?? '',
        eventName: _eventName.text.trim(),
        participantNames: _members.toList(),
        talkedAt: _date,
        sessionLabel: _title.text.trim(),
        ticketCount: widget.initial?.ticketCount,
        chekiIds: _chekiIds.toList(),
        imagesBase64: _images,
        memo: _memo.text.trim(),
        messages: _messages,
        createdAt: widget.initial?.createdAt,
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Widget _messageTile(TalkMessage m, int index) {
    final isSelf = m.kind == TalkEntryKind.self;
    final isMember = m.kind == TalkEntryKind.member;
    final photo = widget.oshis
        .where((o) => o.name == m.speaker)
        .firstOrNull
        ?.profilePhotoBase64;
    final content = Card(
      color: isSelf
          ? const Color(0xFFDCCBFF)
          : isMember
          ? Colors.white
          : const Color(0xFFEFEAF3),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMember)
              Text(
                m.speaker,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            if (m.kind == TalkEntryKind.thought) const Text('💭 心の声'),
            if (m.kind == TalkEntryKind.action) const Text('動作・状態'),
            if (m.kind == TalkEntryKind.system) const Text('スタッフ・システム'),
            Text(m.text),
          ],
        ),
      ),
    );
    return Row(
      mainAxisAlignment: isSelf
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (isMember)
          CircleAvatar(
            radius: 14,
            backgroundImage: photo == null
                ? null
                : MemoryImage(base64Decode(photo)),
            child: photo == null ? const Icon(Icons.person, size: 16) : null,
          ),
        Flexible(
          child: GestureDetector(
            onLongPress: () => setState(() => _messages.removeAt(index)),
            child: content,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      title: Text(_chatStep ? _title.text : 'トークの基本情報'),
      leading: _chatStep
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _chatStep = false),
            )
          : null,
      actions: [
        if (_chatStep) TextButton(onPressed: _save, child: const Text('保存')),
      ],
    ),
    body: _chatStep
        ? Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _messageTile(_messages[i], i),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      PopupMenuButton<TalkEntryKind>(
                        icon: const Icon(Icons.change_history),
                        tooltip: '入力タイプを選択',
                        onSelected: (v) => setState(() => _kind = v),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: TalkEntryKind.self,
                            child: Text('自分の発言'),
                          ),
                          PopupMenuItem(
                            value: TalkEntryKind.member,
                            child: Text('相手の発言'),
                          ),
                          PopupMenuItem(
                            value: TalkEntryKind.action,
                            child: Text('動作・状態'),
                          ),
                          PopupMenuItem(
                            value: TalkEntryKind.thought,
                            child: Text('心の声・補足'),
                          ),
                          PopupMenuItem(
                            value: TalkEntryKind.system,
                            child: Text('スタッフ・システム'),
                          ),
                        ],
                      ),
                      if (_kind == TalkEntryKind.member && _members.isNotEmpty)
                        DropdownButton<String>(
                          value: _members.contains(_speaker)
                              ? _speaker
                              : _members.first,
                          items: _members
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _speaker = v),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _message,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: '内容を入力',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send, color: _purple),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: '題名（必須）・例：1部、特典会2回目',
                ),
              ),
              ListTile(
                title: const Text('日付'),
                subtitle: Text(_day(_date)),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDate,
              ),
              TextField(
                controller: _eventName,
                decoration: const InputDecoration(labelText: 'イベント名（任意）'),
              ),
              const SizedBox(height: 12),
              const Text('メンバー（複数選択可）'),
              Wrap(
                spacing: 8,
                children: [
                  ...widget.oshis.map(
                    (o) => FilterChip(
                      label: Text(o.name),
                      selected: _members.contains(o.name),
                      onSelected: (v) => setState(() {
                        v ? _members.add(o.name) : _members.remove(o.name);
                        _speaker = _members.isEmpty ? null : _members.first;
                      }),
                    ),
                  ),
                  ..._members
                      .where((v) => widget.oshis.every((o) => o.name != v))
                      .map(
                        (v) => InputChip(
                          label: Text(v),
                          onDeleted: () => setState(() {
                            _members.remove(v);
                            _speaker = _members.isEmpty ? null : _members.first;
                          }),
                        ),
                      ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newMember,
                      decoration: const InputDecoration(labelText: 'メンバー名を追加'),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              TextField(
                controller: _memo,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'メモ'),
              ),
              const SizedBox(height: 16),
              const Text('関連チェキ'),
              Wrap(
                spacing: 8,
                children: widget.chekis
                    .map(
                      (c) => FilterChip(
                        label: Text(
                          '${c.memberNames.join('・')} ${c.type.label}',
                        ),
                        selected: _chekiIds.contains(c.id),
                        onSelected: (v) => setState(
                          () =>
                              v ? _chekiIds.add(c.id) : _chekiIds.remove(c.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
              for (final cheki in widget.chekis.where(
                (c) => _chekiIds.contains(c.id),
              ))
                ListTile(
                  title: Text(
                    '${cheki.memberNames.join('・')} ${cheki.type.label}',
                  ),
                  subtitle: Text(
                    cheki.amount == null ? 'チェキを見る' : '${cheki.amount}円',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(cheki.type.label),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cheki.imageBase64 != null)
                            Image.memory(
                              base64Decode(cheki.imageBase64!),
                              height: 180,
                            ),
                          Text('メンバー: ${cheki.memberNames.join('・')}'),
                          if (cheki.memo.isNotEmpty) Text(cheki.memo),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: Text('画像を追加（${_images.length}枚）'),
              ),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Image.memory(
                          base64Decode(_images[i]),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        IconButton(
                          onPressed: () => setState(() => _images.removeAt(i)),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (_title.text.trim().isEmpty) {
                    _save();
                  } else {
                    setState(() => _chatStep = true);
                  }
                },
                child: const Text('会話を入力する'),
              ),
              if (widget.initial != null)
                TextButton(onPressed: _save, child: const Text('基本情報だけ保存')),
            ],
          ),
  );
}
