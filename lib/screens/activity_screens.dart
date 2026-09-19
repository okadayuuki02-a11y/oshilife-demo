import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/activity_models.dart';
import '../models/oshi.dart';
import '../models/oshi_event.dart';
import '../services/activity_storage.dart';

const _purple = Color(0xFF9B5CFF);
const _lightPurple = Color(0xFFF2E8FF);
const _background = Color(0xFFFFF8FF);
const _border = Color(0xFFE8E0F7);

String _money(int? value) {
  if (value == null) return '未設定';
  final text = value.toString();
  final chars = text.split('').reversed.toList();
  final parts = <String>[];
  for (var i = 0; i < chars.length; i += 3) {
    parts.add(chars.skip(i).take(3).toList().reversed.join());
  }
  return '¥${parts.reversed.join(',')}';
}

String _date(DateTime? value) {
  if (value == null) return '未設定';
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}

InputDecoration _decoration(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
    );

class EventTicketsScreen extends StatefulWidget {
  const EventTicketsScreen({
    super.key,
    required this.event,
    required this.onChanged,
  });

  final OshiEvent event;
  final Future<void> Function() onChanged;

  @override
  State<EventTicketsScreen> createState() => _EventTicketsScreenState();
}

class _EventTicketsScreenState extends State<EventTicketsScreen> {
  List<TicketRecord> _tickets = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final values = await ActivityStorage.loadTickets();
    if (!mounted) return;
    setState(() {
      _tickets = values.where((e) => e.eventId == widget.event.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _edit([TicketRecord? initial]) async {
    final result = await Navigator.of(context).push<TicketRecord>(
      MaterialPageRoute(
        builder: (_) => TicketEditScreen(
          eventId: widget.event.id,
          initial: initial,
        ),
      ),
    );
    if (result == null) return;
    await ActivityStorage.saveTicket(result);
    await widget.onChanged();
    await _reload();
  }

  Future<void> _delete(TicketRecord ticket) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チケットを削除しますか？'),
        content: const Text('紐づく自動支出も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ActivityStorage.deleteTicket(ticket.id);
    await widget.onChanged();
    await _reload();
  }

  String? _deadlineLabel(TicketRecord ticket) {
    if (ticket.status != TicketStatus.wonUnpaid ||
        ticket.paymentDeadline == null) {
      return null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      ticket.paymentDeadline!.year,
      ticket.paymentDeadline!.month,
      ticket.paymentDeadline!.day,
    );
    final days = deadline.difference(today).inDays;
    if (days < 0) return '期限超過';
    if (days == 0) return '今日が支払期限';
    if (days == 1) return '支払期限は明日';
    if (days <= 3) return '支払期限まであと$days日';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('チケット', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('チケット追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(widget.event.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (_tickets.isEmpty)
            _EmptyCard(
              icon: Icons.confirmation_number_outlined,
              text: 'チケットはまだ登録されていません',
              buttonText: '追加する',
              onPressed: () => _edit(),
            )
          else
            ..._tickets.map((ticket) {
              final alert = _deadlineLabel(ticket);
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Pill(text: ticket.status.label),
                          const Spacer(),
                          Text(_money(ticket.amount),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      if (alert != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.pink),
                              const SizedBox(width: 8),
                              Text(alert,
                                  style: const TextStyle(fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                      if (ticket.serialNumber.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('整理番号：${ticket.serialNumber}'),
                      ],
                      if (ticket.paymentDeadline != null) ...[
                        const SizedBox(height: 4),
                        Text('支払期限：${_date(ticket.paymentDeadline)}'),
                      ],
                      if (ticket.url.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: ticket.url));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URLをコピーしました')),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, color: _purple, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ticket.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _purple,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text('コピー',
                                  style: TextStyle(color: _purple, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                      if (ticket.memo.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(ticket.memo,
                            style: const TextStyle(color: Color(0xFF716B78))),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _edit(ticket),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('編集'),
                          ),
                          TextButton.icon(
                            onPressed: () => _delete(ticket),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('削除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class TicketEditScreen extends StatefulWidget {
  const TicketEditScreen({super.key, required this.eventId, this.initial});

  final String eventId;
  final TicketRecord? initial;

  @override
  State<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends State<TicketEditScreen> {
  late TicketStatus _status;
  late final TextEditingController _amount;
  late final TextEditingController _serial;
  late final TextEditingController _memo;
  late final TextEditingController _url;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _status = initial?.status ?? TicketStatus.unset;
    _amount = TextEditingController(text: initial?.amount?.toString() ?? '');
    _serial = TextEditingController(text: initial?.serialNumber ?? '');
    _memo = TextEditingController(text: initial?.memo ?? '');
    _url = TextEditingController(text: initial?.url ?? '');
    _deadline = initial?.paymentDeadline;
  }

  @override
  void dispose() {
    _amount.dispose();
    _serial.dispose();
    _memo.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      locale: const Locale('ja', 'JP'),
    );
    if (value == null) return;
    setState(() => _deadline = value);
  }

  void _save() {
    final amount = int.tryParse(_amount.text.replaceAll(',', '').trim());
    final initial = widget.initial;
    Navigator.of(context).pop(
      TicketRecord(
        id: initial?.id,
        eventId: widget.eventId,
        status: _status,
        amount: amount,
        serialNumber: _serial.text.trim(),
        paymentDeadline: _deadline,
        memo: _memo.text.trim(),
        url: _url.text.trim(),
        createdAt: initial?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(widget.initial == null ? 'チケット追加' : 'チケット編集',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<TicketStatus>(
            value: _status,
            decoration: _decoration('状態', icon: Icons.flag_outlined),
            items: TicketStatus.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) => setState(() => _status = value ?? _status),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: _decoration('金額', icon: Icons.currency_yen_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serial,
            decoration: _decoration('整理番号', icon: Icons.numbers_rounded),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            leading: const Icon(Icons.event_busy_rounded, color: _purple),
            title: const Text('支払期限'),
            subtitle: Text(_date(_deadline)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_deadline != null)
                  IconButton(
                    onPressed: () => setState(() => _deadline = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            onTap: _pickDeadline,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: _decoration('URL', icon: Icons.link_rounded).copyWith(
              hintText: '購入・申込・電子チケット・公式案内など',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memo,
            minLines: 3,
            maxLines: 6,
            decoration: _decoration('メモ', icon: Icons.notes_rounded),
          ),
        ],
      ),
    );
  }
}

class EventChekiScreen extends StatefulWidget {
  const EventChekiScreen({
    super.key,
    required this.event,
    required this.oshis,
    required this.onChanged,
  });

  final OshiEvent event;
  final List<Oshi> oshis;
  final Future<void> Function() onChanged;

  @override
  State<EventChekiScreen> createState() => _EventChekiScreenState();
}

class _EventChekiScreenState extends State<EventChekiScreen> {
  List<ChekiPurchase> _purchases = [];
  List<ChekiRecord> _chekis = [];
  List<ChekiSourcePhoto> _sources = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final result = await Future.wait([
      ActivityStorage.loadChekiPurchases(),
      ActivityStorage.loadChekis(),
      ActivityStorage.loadChekiSources(),
    ]);
    if (!mounted) return;
    setState(() {
      _purchases = (result[0] as List<ChekiPurchase>)
          .where((e) => e.eventId == widget.event.id)
          .toList();
      _chekis = (result[1] as List<ChekiRecord>)
          .where((e) => e.eventId == widget.event.id)
          .toList();
      _sources = (result[2] as List<ChekiSourcePhoto>)
          .where((e) => e.eventId == widget.event.id)
          .toList();
    });
  }

  Future<void> _add() async {
    final draft = await Navigator.of(context).push<ChekiPurchaseDraft>(
      MaterialPageRoute(
        builder: (_) => ChekiPurchaseEditScreen(
          event: widget.event,
          oshis: widget.oshis,
        ),
      ),
    );
    if (draft == null) return;

    ChekiSourcePhoto? source;
    if (draft.sourcePhotoBase64 != null) {
      source = ChekiSourcePhoto(
        eventId: widget.event.id,
        imageBase64: draft.sourcePhotoBase64!,
        detectedCount: draft.quantity,
      );
      await ActivityStorage.saveChekiSource(source);
    }

    final purchase = ChekiPurchase(
      eventId: widget.event.id,
      quantity: draft.quantity,
      totalAmount: draft.totalAmount,
      purchasedAt: DateTime.now(),
      sourcePhotoId: source?.id,
    );
    await ActivityStorage.saveChekiPurchase(purchase);

    var overallIndex = 0;
    for (final breakdown in draft.breakdowns) {
      for (var i = 0; i < breakdown.quantity; i++) {
        overallIndex++;
        await ActivityStorage.saveCheki(
          ChekiRecord(
            eventId: widget.event.id,
            purchaseId: purchase.id,
            sourcePhotoId: source?.id,
            shotAt: DateTime.now(),
            memberNames: List<String>.from(draft.memberNames),
            type: breakdown.type,
            imageBase64: draft.quantity == 1 ? draft.sourcePhotoBase64 : null,
            memo: draft.quantity > 1
                ? '${breakdown.type.label} $overallIndex/${draft.quantity}'
                : '',
          ),
        );
      }
    }

    await widget.onChanged();
    await _reload();
  }

  Future<void> _activityChangedForCheki() async {
    await widget.onChanged();
    await _reload();
  }

  Future<void> _editCheki(ChekiRecord cheki) async {
    final result = await Navigator.of(context).push<ChekiRecord>(
      MaterialPageRoute(
        builder: (_) => ChekiRecordEditScreen(
          initial: cheki,
          event: widget.event,
          oshis: widget.oshis,
          onChanged: _activityChangedForCheki,
        ),
      ),
    );
    if (result == null) return;
    await ActivityStorage.saveCheki(result);
    await widget.onChanged();
    await _reload();
  }

  Future<void> _deletePurchase(ChekiPurchase purchase) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入記録を削除しますか？'),
        content: const Text('この購入に紐づく個別チェキと自動支出も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ActivityStorage.deleteChekiPurchase(purchase.id);
    await widget.onChanged();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _purchases.fold<int>(
      0,
      (sum, e) => sum + (e.totalAmount ?? 0),
    );
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('チェキ', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('チェキを記録'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SummaryStrip(
            values: [
              ('枚数', '${_chekis.length}枚'),
              ('購入額', _money(totalAmount)),
              ('購入回数', '${_purchases.length}回'),
            ],
          ),
          const SizedBox(height: 12),
          if (_purchases.isEmpty)
            _EmptyCard(
              icon: Icons.camera_alt_outlined,
              text: 'チェキはまだ記録されていません',
              buttonText: 'チェキを記録',
              onPressed: _add,
            )
          else
            ..._purchases.map((purchase) {
              final records =
                  _chekis.where((e) => e.purchaseId == purchase.id).toList();
              final source = purchase.sourcePhotoId == null
                  ? null
                  : _sources.cast<ChekiSourcePhoto?>().firstWhere(
                        (e) => e?.id == purchase.sourcePhotoId,
                        orElse: () => null,
                      );
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: _border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${purchase.quantity}枚',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 10),
                          Text(_money(purchase.totalAmount),
                              style: const TextStyle(color: _purple)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _deletePurchase(purchase),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      if (purchase.unitPrice != null)
                        Text('1枚あたり ${_money(purchase.unitPrice)}',
                            style: const TextStyle(
                                color: Color(0xFF716B78), fontSize: 12)),
                      if (source != null) ...[
                        const SizedBox(height: 10),
                        _SourcePhotoCard(source: source),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: records
                            .map(
                              (cheki) => InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _editCheki(cheki),
                                child: Container(
                                  width: 104,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _lightPurple,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      if (cheki.imageBase64 != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            base64Decode(cheki.imageBase64!),
                                            width: 54,
                                            height: 54,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else
                                        Icon(
                                          cheki.isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.photo_outlined,
                                          color: _purple,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(cheki.type.label,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      Text(
                                        cheki.memberNames.isEmpty
                                            ? 'メンバー未設定'
                                            : cheki.memberNames.join('・'),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SourcePhotoCard extends StatelessWidget {
  const _SourcePhotoCard({required this.source});

  final ChekiSourcePhoto source;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(source.imageBase64);
    } catch (_) {}
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
            )
          else
            const SizedBox(
              width: 72,
              height: 72,
              child: Icon(Icons.broken_image_outlined),
            ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('まとめ写真を保存済み',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(
                  '自動分割は外注機能を接続予定。今は個別チェキのデータだけ先に作成します。',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF716B78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChekiBreakdownDraft {
  const ChekiBreakdownDraft({
    required this.type,
    required this.quantity,
  });

  final ChekiType type;
  final int quantity;
}

class ChekiPurchaseDraft {
  const ChekiPurchaseDraft({
    required this.breakdowns,
    this.totalAmount,
    required this.memberNames,
    this.sourcePhotoBase64,
  });

  final List<ChekiBreakdownDraft> breakdowns;
  final int? totalAmount;
  final List<String> memberNames;
  final String? sourcePhotoBase64;

  int get quantity => breakdowns.fold<int>(0, (sum, value) => sum + value.quantity);
}

class _ChekiBreakdownInput {
  _ChekiBreakdownInput({
    this.type = ChekiType.twoShot,
    int quantity = 1,
  }) : quantityController = TextEditingController(text: quantity.toString());

  ChekiType type;
  final TextEditingController quantityController;

  void dispose() => quantityController.dispose();
}

class ChekiPurchaseEditScreen extends StatefulWidget {
  const ChekiPurchaseEditScreen({
    super.key,
    required this.event,
    required this.oshis,
  });

  final OshiEvent event;
  final List<Oshi> oshis;

  @override
  State<ChekiPurchaseEditScreen> createState() => _ChekiPurchaseEditScreenState();
}

class _ChekiPurchaseEditScreenState extends State<ChekiPurchaseEditScreen> {
  final _amount = TextEditingController();
  final _extraMember = TextEditingController();
  final Set<String> _members = {};
  final List<_ChekiBreakdownInput> _breakdowns = [
    _ChekiBreakdownInput(type: ChekiType.twoShot, quantity: 1),
  ];
  String? _sourcePhotoBase64;

  int get _totalQuantity => _breakdowns.fold<int>(
        0,
        (sum, row) => sum + (int.tryParse(row.quantityController.text.trim()) ?? 0),
      );

  @override
  void dispose() {
    _amount.dispose();
    _extraMember.dispose();
    for (final row in _breakdowns) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSourcePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1400,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _sourcePhotoBase64 = base64Encode(bytes));
  }

  void _addExtra() {
    final name = _extraMember.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _members.add(name);
      _extraMember.clear();
    });
  }

  void _addBreakdown() {
    setState(() {
      _breakdowns.add(_ChekiBreakdownInput(type: ChekiType.solo, quantity: 1));
    });
  }

  void _removeBreakdown(int index) {
    if (_breakdowns.length <= 1) return;
    setState(() {
      final row = _breakdowns.removeAt(index);
      row.dispose();
    });
  }

  void _save() {
    final breakdowns = <ChekiBreakdownDraft>[];
    for (final row in _breakdowns) {
      final quantity = int.tryParse(row.quantityController.text.trim()) ?? 0;
      if (quantity <= 0) continue;
      breakdowns.add(ChekiBreakdownDraft(type: row.type, quantity: quantity));
    }

    final quantity = breakdowns.fold<int>(0, (sum, value) => sum + value.quantity);
    if (quantity <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('チェキの枚数を入力してください')));
      return;
    }

    Navigator.pop(
      context,
      ChekiPurchaseDraft(
        breakdowns: breakdowns,
        totalAmount: int.tryParse(_amount.text.replaceAll(',', '').trim()),
        memberNames: _members.toList(),
        sourcePhotoBase64: _sourcePhotoBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOshis = widget.oshis.where((e) => !e.isGraduated).toList();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('チェキを記録', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, color: _purple),
                      const SizedBox(width: 10),
                      const Text('合計枚数'),
                      const Spacer(),
                      Text(
                        '${_totalQuantity}枚',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('合計金額', icon: Icons.currency_yen_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('チェキ内訳', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: _addBreakdown,
                icon: const Icon(Icons.add_rounded),
                label: const Text('種類を追加'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(_breakdowns.length, (index) {
            final row = _breakdowns[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<ChekiType>(
                      value: row.type,
                      decoration: _decoration('種類'),
                      items: ChekiType.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                          .toList(),
                      onChanged: (value) => setState(() => row.type = value ?? row.type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.quantityController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration('枚数'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_breakdowns.length > 1) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: '削除',
                      onPressed: () => _removeBreakdown(index),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text('写っているメンバー', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...activeOshis.map(
                (oshi) => FilterChip(
                  selected: _members.contains(oshi.name),
                  label: Text(oshi.name),
                  onSelected: (selected) => setState(() {
                    selected ? _members.add(oshi.name) : _members.remove(oshi.name);
                  }),
                ),
              ),
              ..._members
                  .where((name) => activeOshis.every((e) => e.name != name))
                  .map(
                    (name) => InputChip(
                      label: Text(name),
                      onDeleted: () => setState(() => _members.remove(name)),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _extraMember,
                  decoration: _decoration('未登録メンバー名', icon: Icons.person_add_alt_1),
                  onSubmitted: (_) => _addExtra(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: _addExtra, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickSourcePhoto,
            icon: Icon(_sourcePhotoBase64 == null
                ? Icons.add_photo_alternate_outlined
                : Icons.check_circle_rounded),
            label: Text(_sourcePhotoBase64 == null
                ? 'まとめ写真を選ぶ（任意）'
                : 'まとめ写真を選択済み'),
          ),
          const SizedBox(height: 8),
          const Text(
            '種類ごとに枚数を分けて登録できます。複数チェキの自動分割は外注実装予定で、今は元画像を保持しながら個別チェキデータを作成します。',
            style: TextStyle(fontSize: 12, color: Color(0xFF716B78), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class ChekiRecordEditScreen extends StatefulWidget {
  const ChekiRecordEditScreen({
    super.key,
    required this.initial,
    required this.event,
    required this.oshis,
    required this.onChanged,
  });

  final ChekiRecord initial;
  final OshiEvent event;
  final List<Oshi> oshis;
  final Future<void> Function() onChanged;

  @override
  State<ChekiRecordEditScreen> createState() => _ChekiRecordEditScreenState();
}

class _ChekiRecordEditScreenState extends State<ChekiRecordEditScreen> {
  late ChekiType _type;
  late Set<String> _members;
  late final TextEditingController _memo;
  late bool _favorite;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _members = widget.initial.memberNames.toSet();
    _memo = TextEditingController(text: widget.initial.memo);
    _favorite = widget.initial.isFavorite;
    _imageBase64 = widget.initial.imageBase64;
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _addTalk() async {
    final chekis = (await ActivityStorage.loadChekis())
        .where((e) => e.eventId == widget.event.id)
        .toList();
    if (!mounted) return;
    final talk = await Navigator.of(context).push<TalkLog>(
      MaterialPageRoute(
        builder: (_) => TalkEditScreen(
          event: widget.event,
          oshis: widget.oshis,
          chekis: chekis,
          preselectedChekiIds: [widget.initial.id],
        ),
      ),
    );
    if (talk == null) return;
    await ActivityStorage.saveTalk(talk);
    await widget.onChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('このチェキにトークログを紐付けました')),
    );
  }

  void _save() {
    final initial = widget.initial;
    Navigator.pop(
      context,
      ChekiRecord(
        id: initial.id,
        eventId: initial.eventId,
        purchaseId: initial.purchaseId,
        sourcePhotoId: initial.sourcePhotoId,
        shotAt: initial.shotAt,
        memberNames: _members.toList(),
        type: _type,
        imageBase64: _imageBase64,
        memo: _memo.text.trim(),
        isFavorite: _favorite,
        talkLogIds: List<String>.from(initial.talkLogIds),
        createdAt: initial.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('チェキ詳細', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                if (_imageBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_imageBase64!),
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: Icon(Icons.photo_outlined, size: 46, color: _purple),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_imageBase64 == null ? '個別画像を追加' : '画像を変更'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ChekiType>(
            value: _type,
            decoration: _decoration('種類'),
            items: ChekiType.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 14),
          const Text('メンバー', style: TextStyle(fontWeight: FontWeight.w900)),
          Wrap(
            spacing: 8,
            children: widget.oshis
                .where((e) => !e.isGraduated)
                .map(
                  (oshi) => FilterChip(
                    selected: _members.contains(oshi.name),
                    label: Text(oshi.name),
                    onSelected: (selected) => setState(() {
                      selected ? _members.add(oshi.name) : _members.remove(oshi.name);
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _favorite,
            activeColor: _purple,
            title: const Text('お気に入り'),
            secondary: const Icon(Icons.favorite_rounded, color: _purple),
            onChanged: (value) => setState(() => _favorite = value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addTalk,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('このチェキのトークを記録'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memo,
            minLines: 3,
            maxLines: 8,
            decoration: _decoration('メモ'),
          ),
        ],
      ),
    );
  }
}

class EventTalkScreen extends StatefulWidget {
  const EventTalkScreen({
    super.key,
    required this.event,
    required this.oshis,
    required this.onChanged,
  });

  final OshiEvent event;
  final List<Oshi> oshis;
  final Future<void> Function() onChanged;

  @override
  State<EventTalkScreen> createState() => _EventTalkScreenState();
}

class _EventTalkScreenState extends State<EventTalkScreen> {
  List<TalkLog> _talks = [];
  List<ChekiRecord> _chekis = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final result = await Future.wait([
      ActivityStorage.loadTalks(),
      ActivityStorage.loadChekis(),
    ]);
    if (!mounted) return;
    setState(() {
      _talks = (result[0] as List<TalkLog>)
          .where((e) => e.eventId == widget.event.id)
          .toList()
        ..sort((a, b) => b.talkedAt.compareTo(a.talkedAt));
      _chekis = (result[1] as List<ChekiRecord>)
          .where((e) => e.eventId == widget.event.id)
          .toList();
    });
  }

  Future<void> _edit([TalkLog? initial, List<String>? preselectedChekiIds]) async {
    final result = await Navigator.of(context).push<TalkLog>(
      MaterialPageRoute(
        builder: (_) => TalkEditScreen(
          event: widget.event,
          oshis: widget.oshis,
          chekis: _chekis,
          initial: initial,
          preselectedChekiIds: preselectedChekiIds,
        ),
      ),
    );
    if (result == null) return;
    await ActivityStorage.saveTalk(result);
    await widget.onChanged();
    await _reload();
  }

  Future<void> _delete(TalkLog talk) async {
    await ActivityStorage.deleteTalk(talk.id);
    await widget.onChanged();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final totalMessages = _talks.fold<int>(0, (sum, e) => sum + e.messageCount);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('トークログ', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('トーク追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SummaryStrip(
            values: [
              ('トーク', '${_talks.length}回'),
              ('発言', '$totalMessages件'),
              ('チェキ紐付け', '${_talks.fold<int>(0, (sum, e) => sum + e.chekiIds.length)}件'),
            ],
          ),
          const SizedBox(height: 12),
          if (_talks.isEmpty)
            _EmptyCard(
              icon: Icons.chat_bubble_outline_rounded,
              text: 'トークログはまだありません',
              buttonText: 'トークを記録',
              onPressed: () => _edit(),
            )
          else
            ..._talks.map(
              (talk) => Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(
                    backgroundColor: _lightPurple,
                    child: Icon(Icons.forum_rounded, color: _purple),
                  ),
                  title: Text(
                    talk.participantNames.isEmpty
                        ? 'メンバー未設定'
                        : talk.participantNames.join(' × '),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    [
                      if (talk.sessionLabel.trim().isNotEmpty) talk.sessionLabel,
                      '${talk.messageCount}発言',
                      if (talk.chekiIds.isNotEmpty) 'チェキ${talk.chekiIds.length}枚',
                    ].join('・'),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _edit(talk);
                      if (value == 'delete') _delete(talk);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('編集')),
                      PopupMenuItem(value: 'delete', child: Text('削除')),
                    ],
                  ),
                  onTap: () => _edit(talk),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageDraft {
  _MessageDraft({required this.speaker, String text = ''})
      : controller = TextEditingController(text: text);

  String speaker;
  final TextEditingController controller;
}

class TalkEditScreen extends StatefulWidget {
  const TalkEditScreen({
    super.key,
    required this.event,
    required this.oshis,
    required this.chekis,
    this.initial,
    this.preselectedChekiIds,
  });

  final OshiEvent event;
  final List<Oshi> oshis;
  final List<ChekiRecord> chekis;
  final TalkLog? initial;
  final List<String>? preselectedChekiIds;

  @override
  State<TalkEditScreen> createState() => _TalkEditScreenState();
}

class _TalkEditScreenState extends State<TalkEditScreen> {
  late Set<String> _participants;
  late Set<String> _chekiIds;
  late final TextEditingController _session;
  late final TextEditingController _ticketCount;
  late final TextEditingController _memo;
  final _extraMember = TextEditingController();
  final List<_MessageDraft> _messages = [];

  List<String> get _speakerOptions => ['自分', ..._participants];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _participants = (initial?.participantNames ?? <String>[]).toSet();
    _chekiIds = (initial?.chekiIds ?? widget.preselectedChekiIds ?? <String>[]).toSet();
    _session = TextEditingController(text: initial?.sessionLabel ?? '');
    _ticketCount = TextEditingController(text: initial?.ticketCount?.toString() ?? '');
    _memo = TextEditingController(text: initial?.memo ?? '');
    if (initial == null || initial.messages.isEmpty) {
      _messages.add(_MessageDraft(speaker: '自分'));
    } else {
      for (final message in initial.messages) {
        _messages.add(_MessageDraft(speaker: message.speaker, text: message.text));
      }
    }
  }

  @override
  void dispose() {
    _session.dispose();
    _ticketCount.dispose();
    _memo.dispose();
    _extraMember.dispose();
    for (final message in _messages) {
      message.controller.dispose();
    }
    super.dispose();
  }

  void _addExtraMember() {
    final name = _extraMember.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _participants.add(name);
      _extraMember.clear();
    });
  }

  void _addMessage() {
    final options = _speakerOptions;
    setState(() {
      _messages.add(
        _MessageDraft(speaker: options.length > 1 ? options[1] : '自分'),
      );
    });
  }

  void _save() {
    final initial = widget.initial;
    final messages = <TalkMessage>[];
    for (var i = 0; i < _messages.length; i++) {
      final draft = _messages[i];
      final text = draft.controller.text.trim();
      if (text.isEmpty) continue;
      messages.add(TalkMessage(speaker: draft.speaker, text: text, order: i));
    }
    Navigator.pop(
      context,
      TalkLog(
        id: initial?.id,
        eventId: widget.event.id,
        participantNames: _participants.toList(),
        talkedAt: initial?.talkedAt ?? DateTime.now(),
        sessionLabel: _session.text.trim(),
        ticketCount: int.tryParse(_ticketCount.text.trim()),
        chekiIds: _chekiIds.toList(),
        memo: _memo.text.trim(),
        messages: messages,
        createdAt: initial?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOshis = widget.oshis.where((e) => !e.isGraduated).toList();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(widget.initial == null ? 'トークを記録' : 'トークを編集',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('参加メンバー', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...activeOshis.map(
                (oshi) => FilterChip(
                  selected: _participants.contains(oshi.name),
                  label: Text(oshi.name),
                  onSelected: (value) => setState(() {
                    value
                        ? _participants.add(oshi.name)
                        : _participants.remove(oshi.name);
                  }),
                ),
              ),
              ..._participants
                  .where((name) => activeOshis.every((e) => e.name != name))
                  .map(
                    (name) => InputChip(
                      label: Text(name),
                      onDeleted: () => setState(() => _participants.remove(name)),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _extraMember,
                  decoration: _decoration('参加メンバーを追加'),
                  onSubmitted: (_) => _addExtraMember(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addExtraMember,
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _session,
                  decoration: _decoration('部・回・特典会枠'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _ticketCount,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('使用枚数'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.chekis.isNotEmpty) ...[
            const Text('関連チェキ', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.chekis
                  .map(
                    (cheki) => FilterChip(
                      selected: _chekiIds.contains(cheki.id),
                      label: Text(
                        cheki.memberNames.isEmpty
                            ? cheki.type.label
                            : '${cheki.memberNames.join('・')} ${cheki.type.label}',
                      ),
                      onSelected: (value) => setState(() {
                        value ? _chekiIds.add(cheki.id) : _chekiIds.remove(cheki.id);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Expanded(
                child: Text('会話', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: _addMessage,
                icon: const Icon(Icons.add_rounded),
                label: const Text('発言追加'),
              ),
            ],
          ),
          ...List.generate(_messages.length, (index) {
            final draft = _messages[index];
            final options = _speakerOptions;
            if (!options.contains(draft.speaker)) draft.speaker = '自分';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 105,
                    child: DropdownButtonFormField<String>(
                      value: draft.speaker,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      items: options
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() => draft.speaker = value ?? '自分'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: draft.controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '話した内容',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _messages.length <= 1
                        ? null
                        : () => setState(() {
                              final removed = _messages.removeAt(index);
                              removed.controller.dispose();
                            }),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _memo,
            minLines: 3,
            maxLines: 6,
            decoration: _decoration('メモ'),
          ),
        ],
      ),
    );
  }
}

class EventTransactionScreen extends StatefulWidget {
  const EventTransactionScreen({
    super.key,
    required this.event,
    required this.oshis,
    required this.onChanged,
  });

  final OshiEvent event;
  final List<Oshi> oshis;
  final Future<void> Function() onChanged;

  @override
  State<EventTransactionScreen> createState() => _EventTransactionScreenState();
}

class _EventTransactionScreenState extends State<EventTransactionScreen> {
  List<OshiTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await ActivityStorage.materializeRecurringTransactions();
    final values = await ActivityStorage.loadTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = values.where((e) => e.eventId == widget.event.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _edit([OshiTransaction? initial]) async {
    final result = await Navigator.of(context).push<OshiTransaction>(
      MaterialPageRoute(
        builder: (_) => TransactionEditScreen(
          eventId: widget.event.id,
          oshis: widget.oshis,
          initial: initial,
        ),
      ),
    );
    if (result == null) return;
    await ActivityStorage.saveTransaction(result);
    await widget.onChanged();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final total = _transactions.fold<int>(0, (sum, e) => sum + e.signedAmount);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('イベント支出', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('支出追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SummaryStrip(values: [('このイベント', _money(-total))]),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            _EmptyCard(
              icon: Icons.receipt_long_outlined,
              text: '支出はまだありません',
              buttonText: '支出を追加',
              onPressed: () => _edit(),
            )
          else
            ..._transactions.map(
              (transaction) => Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: _border),
                ),
                child: ListTile(
                  onTap: transaction.sourceType == null
                      ? () => _edit(transaction)
                      : null,
                  leading: CircleAvatar(
                    backgroundColor: _lightPurple,
                    child: Icon(
                      transaction.type == TransactionType.expense
                          ? Icons.remove_rounded
                          : Icons.add_rounded,
                      color: _purple,
                    ),
                  ),
                  title: Text(transaction.category.label,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(
                    [
                      _date(transaction.date),
                      if (transaction.memo.trim().isNotEmpty) transaction.memo,
                      if (transaction.sourceType != null) '自動連携',
                    ].join('・'),
                  ),
                  trailing: Text(
                    '${transaction.signedAmount < 0 ? '-' : '+'}${_money(transaction.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionEditScreen extends StatefulWidget {
  const TransactionEditScreen({
    super.key,
    this.eventId,
    required this.oshis,
    this.initial,
  });

  final String? eventId;
  final List<Oshi> oshis;
  final OshiTransaction? initial;

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  late TransactionType _type;
  late TransactionCategory _category;
  late DateTime _dateValue;
  late Set<String> _members;
  late final TextEditingController _amount;
  late final TextEditingController _payment;
  late final TextEditingController _memo;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TransactionType.expense;
    _category = initial?.category ?? _categoriesForType(_type).first;
    if (!_categoriesForType(_type).contains(_category)) {
      _category = _categoriesForType(_type).first;
    }
    _dateValue = initial?.date ?? DateTime.now();
    _members = (initial?.memberNames ?? <String>[]).toSet();
    _amount = TextEditingController(text: initial?.amount.toString() ?? '');
    _payment = TextEditingController(text: initial?.paymentMethod ?? '');
    _memo = TextEditingController(text: initial?.memo ?? '');
  }

  List<TransactionCategory> _categoriesForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return const [
          TransactionCategory.ticket,
          TransactionCategory.cheki,
          TransactionCategory.goods,
          TransactionCategory.transport,
          TransactionCategory.hotel,
          TransactionCategory.food,
          TransactionCategory.fanclub,
          TransactionCategory.other,
        ];
      case TransactionType.income:
        return const [
          TransactionCategory.income,
          TransactionCategory.other,
        ];
      case TransactionType.refund:
        return const [
          TransactionCategory.ticket,
          TransactionCategory.cheki,
          TransactionCategory.goods,
          TransactionCategory.fanclub,
          TransactionCategory.other,
        ];
      case TransactionType.adjustment:
        return const [
          TransactionCategory.income,
          TransactionCategory.other,
        ];
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _payment.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dateValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      locale: const Locale('ja', 'JP'),
    );
    if (value != null) setState(() => _dateValue = value);
  }

  void _changeType(TransactionType value) {
    final categories = _categoriesForType(value);
    setState(() {
      _type = value;
      if (!categories.contains(_category)) {
        _category = categories.first;
      }
    });
  }

  void _save() {
    final amount = int.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('金額を入力してください')));
      return;
    }
    final initial = widget.initial;
    Navigator.pop(
      context,
      OshiTransaction(
        id: initial?.id,
        type: _type,
        amount: amount,
        date: _dateValue,
        category: _category,
        paymentMethod: _payment.text.trim(),
        eventId: widget.eventId ?? initial?.eventId,
        memberNames: _members.toList(),
        memo: _memo.text.trim(),
        sourceType: initial?.sourceType,
        sourceId: initial?.sourceId,
        createdAt: initial?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesForType(_type);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(widget.initial == null ? '入出金を追加' : '入出金を編集',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('種別', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.expense, label: Text('出金')),
              ButtonSegment(value: TransactionType.income, label: Text('入金')),
              ButtonSegment(value: TransactionType.refund, label: Text('返金')),
              ButtonSegment(value: TransactionType.adjustment, label: Text('調整')),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (values) => _changeType(values.first),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<TransactionCategory>(
            value: _category,
            decoration: _decoration('カテゴリー'),
            items: categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: _decoration('金額', icon: Icons.currency_yen_rounded),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            leading: const Icon(Icons.calendar_month_rounded, color: _purple),
            title: Text(_type == TransactionType.expense ? '支払日' : '入金・処理日'),
            subtitle: Text(_date(_dateValue)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _payment,
            decoration: _decoration('支払方法・入金元（任意）'),
          ),
          const SizedBox(height: 12),
          if (widget.oshis.isNotEmpty) ...[
            const Text('関連する推し（任意）',
                style: TextStyle(fontWeight: FontWeight.w900)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.oshis
                  .map(
                    (oshi) => FilterChip(
                      selected: _members.contains(oshi.name),
                      label: Text(oshi.name),
                      onSelected: (selected) => setState(() {
                        selected ? _members.add(oshi.name) : _members.remove(oshi.name);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _memo,
            minLines: 3,
            maxLines: 6,
            decoration: _decoration('メモ'),
          ),
        ],
      ),
    );
  }
}

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({
    super.key,
    required this.oshis,
    required this.onChanged,
  });

  final List<Oshi> oshis;
  final Future<void> Function() onChanged;

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  List<RecurringTransaction> _values = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final values = await ActivityStorage.loadRecurringTransactions();
    if (!mounted) return;
    setState(() {
      _values = values..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _edit([RecurringTransaction? initial]) async {
    final result = await Navigator.of(context).push<RecurringTransaction>(
      MaterialPageRoute(
        builder: (_) => RecurringTransactionEditScreen(
          oshis: widget.oshis,
          initial: initial,
        ),
      ),
    );
    if (result == null) return;
    await ActivityStorage.saveRecurringTransaction(result);
    await widget.onChanged();
    await _reload();
  }

  Future<void> _delete(RecurringTransaction value) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('定期入出金を削除しますか？'),
        content: const Text('すでに家計簿へ作成済みの履歴は残ります。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok != true) return;
    await ActivityStorage.deleteRecurringTransaction(value.id);
    await widget.onChanged();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('定期入出金', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('追加'),
      ),
      body: _values.isEmpty
          ? const Center(
              child: _EmptyCard(
                icon: Icons.autorenew_rounded,
                text: '給料・推し活積立・ファンクラブなどを\n定期入出金として登録できます',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final value = _values[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: _border),
                  ),
                  child: ListTile(
                    onTap: () => _edit(value),
                    leading: CircleAvatar(
                      backgroundColor: _lightPurple,
                      foregroundColor: _purple,
                      child: Icon(value.type == TransactionType.income
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(value.name,
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        if (!value.enabled)
                          const Text('停止中',
                              style: TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                    subtitle: Text(
                      '${value.type == TransactionType.income ? '入金' : '支出'}・${value.category.label}・${value.scheduleLabel}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_money(value.amount),
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'delete') _delete(value);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'delete', child: Text('削除')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class RecurringTransactionEditScreen extends StatefulWidget {
  const RecurringTransactionEditScreen({
    super.key,
    required this.oshis,
    this.initial,
  });

  final List<Oshi> oshis;
  final RecurringTransaction? initial;

  @override
  State<RecurringTransactionEditScreen> createState() =>
      _RecurringTransactionEditScreenState();
}

class _RecurringTransactionEditScreenState
    extends State<RecurringTransactionEditScreen> {
  late TransactionType _type;
  late TransactionCategory _category;
  late RecurringFrequency _frequency;
  late int _dayOfMonth;
  late int _monthOfYear;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _enabled;
  late Set<String> _members;
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _memo;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type == TransactionType.income
        ? TransactionType.income
        : TransactionType.expense;
    _category = initial?.category ??
        (_type == TransactionType.income
            ? TransactionCategory.income
            : TransactionCategory.fanclub);
    _frequency = initial?.frequency ?? RecurringFrequency.monthly;
    _dayOfMonth = initial?.dayOfMonth ?? 1;
    _monthOfYear = initial?.monthOfYear ?? DateTime.now().month;
    _startDate = initial?.startDate ?? DateTime.now();
    _endDate = initial?.endDate;
    _enabled = initial?.enabled ?? true;
    _members = (initial?.memberNames ?? <String>[]).toSet();
    _name = TextEditingController(text: initial?.name ?? '');
    _amount = TextEditingController(text: initial?.amount.toString() ?? '');
    _memo = TextEditingController(text: initial?.memo ?? '');
  }

  List<TransactionCategory> get _categories => _type == TransactionType.income
      ? const [TransactionCategory.income, TransactionCategory.other]
      : const [
          TransactionCategory.ticket,
          TransactionCategory.cheki,
          TransactionCategory.goods,
          TransactionCategory.transport,
          TransactionCategory.hotel,
          TransactionCategory.food,
          TransactionCategory.fanclub,
          TransactionCategory.other,
        ];

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      locale: const Locale('ja', 'JP'),
    );
    if (value != null) setState(() => _startDate = value);
  }

  Future<void> _pickEndDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2040),
      locale: const Locale('ja', 'JP'),
    );
    if (value != null) setState(() => _endDate = value);
  }

  void _save() {
    final name = _name.text.trim();
    final amount = int.tryParse(_amount.text.replaceAll(',', '').trim());
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名称と金額を入力してください')),
      );
      return;
    }
    final initial = widget.initial;
    Navigator.pop(
      context,
      RecurringTransaction(
        id: initial?.id,
        name: name,
        type: _type,
        amount: amount,
        category: _category,
        frequency: _frequency,
        dayOfMonth: _dayOfMonth,
        monthOfYear: _frequency == RecurringFrequency.yearly ? _monthOfYear : null,
        startDate: _startDate,
        endDate: _endDate,
        enabled: _enabled,
        memberNames: _members.toList(),
        memo: _memo.text.trim(),
        createdAt: initial?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(widget.initial == null ? '定期入出金を追加' : '定期入出金を編集',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: _decoration('名称')),
          const SizedBox(height: 12),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.income, label: Text('入金')),
              ButtonSegment(value: TransactionType.expense, label: Text('支出')),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (values) {
              setState(() {
                _type = values.first;
                if (!_categories.contains(_category)) {
                  _category = _categories.first;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: _decoration('金額', icon: Icons.currency_yen_rounded),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TransactionCategory>(
            value: _category,
            decoration: _decoration('カテゴリー'),
            items: _categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) => setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          SegmentedButton<RecurringFrequency>(
            segments: const [
              ButtonSegment(value: RecurringFrequency.monthly, label: Text('毎月')),
              ButtonSegment(value: RecurringFrequency.yearly, label: Text('毎年')),
            ],
            selected: {_frequency},
            showSelectedIcon: false,
            onSelectionChanged: (values) => setState(() => _frequency = values.first),
          ),
          const SizedBox(height: 12),
          if (_frequency == RecurringFrequency.yearly) ...[
            DropdownButtonFormField<int>(
              value: _monthOfYear,
              decoration: _decoration('実行月'),
              items: List.generate(12, (i) => i + 1)
                  .map((month) => DropdownMenuItem(value: month, child: Text('$month月')))
                  .toList(),
              onChanged: (value) => setState(() => _monthOfYear = value ?? _monthOfYear),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int>(
            value: _dayOfMonth,
            decoration: _decoration('実行日'),
            items: List.generate(31, (i) => i + 1)
                .map((day) => DropdownMenuItem(value: day, child: Text('$day日')))
                .toList(),
            onChanged: (value) => setState(() => _dayOfMonth = value ?? _dayOfMonth),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            leading: const Icon(Icons.play_circle_outline_rounded, color: _purple),
            title: const Text('開始日'),
            subtitle: Text(_date(_startDate)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            leading: const Icon(Icons.stop_circle_outlined, color: _purple),
            title: const Text('終了日（任意）'),
            subtitle: Text(_endDate == null ? '無期限' : _date(_endDate)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endDate != null)
                  IconButton(
                    onPressed: () => setState(() => _endDate = null),
                    icon: const Icon(Icons.clear_rounded),
                  ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            onTap: _pickEndDate,
          ),
          const SizedBox(height: 12),
          if (widget.oshis.isNotEmpty) ...[
            const Text('関連する推し（任意）', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.oshis
                  .map((oshi) => FilterChip(
                        selected: _members.contains(oshi.name),
                        label: Text(oshi.name),
                        onSelected: (selected) => setState(() {
                          selected ? _members.add(oshi.name) : _members.remove(oshi.name);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _memo,
            minLines: 2,
            maxLines: 5,
            decoration: _decoration('メモ（任意）'),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: _enabled,
            contentPadding: EdgeInsets.zero,
            title: const Text('自動登録を有効にする'),
            subtitle: const Text('アプリを開いた時に、実行日までの未登録分を家計簿へ反映します。'),
            onChanged: (value) => setState(() => _enabled = value),
          ),
        ],
      ),
    );
  }
}

class OshiWalletScreen extends StatefulWidget {
  const OshiWalletScreen({
    super.key,
    required this.oshis,
    required this.events,
    required this.onChanged,
  });

  final List<Oshi> oshis;
  final List<OshiEvent> events;
  final Future<void> Function() onChanged;

  @override
  State<OshiWalletScreen> createState() => _OshiWalletScreenState();
}

class _OshiWalletScreenState extends State<OshiWalletScreen> {
  List<OshiTransaction> _values = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await ActivityStorage.materializeRecurringTransactions();
    final values = await ActivityStorage.loadTransactions();
    if (!mounted) return;
    setState(() => _values = values..sort((a, b) => b.date.compareTo(a.date)));
  }

  List<OshiTransaction> get _monthValues => _values
      .where((e) => e.date.year == _month.year && e.date.month == _month.month)
      .toList();

  Future<void> _add() async {
    final result = await Navigator.of(context).push<OshiTransaction>(
      MaterialPageRoute(
        builder: (_) => TransactionEditScreen(oshis: widget.oshis),
      ),
    );
    if (result == null) return;
    await ActivityStorage.saveTransaction(result);
    await widget.onChanged();
    await _reload();
  }

  Future<void> _openRecurring() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecurringTransactionsScreen(
          oshis: widget.oshis,
          onChanged: () async {
            await widget.onChanged();
            await _reload();
          },
        ),
      ),
    );
    await _reload();
  }

  void _shiftMonth(int amount) {
    setState(() => _month = DateTime(_month.year, _month.month + amount));
  }

  String _eventName(String? id) {
    if (id == null) return '';
    for (final event in widget.events) {
      if (event.id == id) return event.title;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final monthValues = _monthValues;
    final expense = monthValues
        .where((e) => e.type == TransactionType.expense)
        .fold<int>(0, (sum, e) => sum + e.amount);
    final income = monthValues
        .where((e) => e.type != TransactionType.expense)
        .fold<int>(0, (sum, e) => sum + e.amount);
    final balance = income - expense;
    final categories = <TransactionCategory, int>{};
    for (final value in monthValues.where((e) => e.type == TransactionType.expense)) {
      categories[value.category] = (categories[value.category] ?? 0) + value.amount;
    }
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: _purple, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('推し活家計簿',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: _openRecurring,
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text('定期'),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _purple),
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('入出金'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
              Text('${_month.year}年 ${_month.month}月',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 8),
          _SummaryStrip(
            values: [
              ('収入・返金', _money(income)),
              ('推し活支出', _money(expense)),
              ('差引', _money(balance)),
            ],
          ),
          const SizedBox(height: 14),
          if (sortedCategories.isNotEmpty) ...[
            const Text('カテゴリー別', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: sortedCategories
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key.label)),
                            Text(_money(entry.value),
                                style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          const Text('通帳', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (monthValues.isEmpty)
            const _EmptyCard(
              icon: Icons.receipt_long_outlined,
              text: 'この月の入出金はまだありません',
            )
          else
            ...monthValues.map(
              (value) => Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: _border),
                ),
                child: ListTile(
                  title: Text(value.category.label,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(
                    [
                      _date(value.date),
                      if (_eventName(value.eventId).isNotEmpty) _eventName(value.eventId),
                      if (value.memo.trim().isNotEmpty) value.memo,
                    ].join('・'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${value.signedAmount < 0 ? '-' : '+'}${_money(value.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: value.signedAmount < 0 ? null : _purple,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.values});

  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: values
            .map(
              (entry) => Expanded(
                child: Column(
                  children: [
                    Text(entry.$1,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF716B78))),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(entry.$2,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(color: _purple, fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
    this.buttonText,
    this.onPressed,
  });

  final IconData icon;
  final String text;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _purple, size: 36),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onPressed, child: Text(buttonText!)),
          ],
        ],
      ),
    );
  }
}
