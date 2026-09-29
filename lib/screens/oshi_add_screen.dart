import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/oshi.dart';
import '../widgets/oshi_profile_fields.dart';
import '../widgets/group_suggestion_field.dart';
import '../widgets/member_color_picker.dart';
import '../widgets/photo_crop_screen.dart';

/// OCRなど外部入力の結果を、既存の推し登録フォームへ流し込むための土台。
class OshiAddPrefill {
  const OshiAddPrefill({
    this.name,
    this.groupName,
    this.favoriteSong,
    this.profilePhotoBase64,
    this.memberColorHex,
  });

  final String? name;
  final String? groupName;
  final String? favoriteSong;
  final String? profilePhotoBase64;
  final String? memberColorHex;
}

class OshiAddScreen extends StatefulWidget {
  const OshiAddScreen({
    super.key,
    this.defaultPrimary = false,
    this.groupSuggestions = const <String>[],
    this.prefill,
  });

  final bool defaultPrimary;
  final List<String> groupSuggestions;
  final OshiAddPrefill? prefill;

  @override
  State<OshiAddScreen> createState() => _OshiAddScreenState();
}

class _OshiAddScreenState extends State<OshiAddScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _songController = TextEditingController();
  final _profileFields = {
    for (final key in profileLabels.keys) key: TextEditingController(),
  };

  late bool _isPrimary;
  String _groupName = '';
  DateTime? _oshiStartDate;
  String? _profilePhotoBase64;
  String? _memberColorHex;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _isPrimary = widget.defaultPrimary;
    final prefill = widget.prefill;
    if (prefill != null) {
      _nameController.text = prefill.name ?? '';
      _groupName = prefill.groupName ?? '';
      _songController.text = prefill.favoriteSong ?? '';
      _profilePhotoBase64 = prefill.profilePhotoBase64;
      _memberColorHex = prefill.memberColorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _songController.dispose();
    for (final value in _profileFields.values) {
      value.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return WarekiDatePickerDialog(
          initialDate: _oshiStartDate ?? now,
          firstDate: DateTime(now.year - 15, now.month, now.day),
          lastDate: now,
        );
      },
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _oshiStartDate = selectedDate;
      });
    }
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          settings: const RouteSettings(name: 'oshi_photo_crop'),
          builder: (_) => PhotoCropScreen(imageBytes: bytes),
        ),
      );

      if (cropped == null || !mounted) return;

      setState(() {
        _profilePhotoBase64 = base64Encode(cropped);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  String _dateText() {
    if (_oshiStartDate == null) return '未設定';
    final date = _oshiStartDate!;
    return '${date.year}年${date.month}月${date.day}日（${weekdayJapanese(date.weekday)}）';
  }

  String _warekiText() {
    if (_oshiStartDate == null) return '';
    return warekiDate(_oshiStartDate!);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final photo = _profilePhotoBase64;
    final oshi = Oshi(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      groupName: _groupName.trim(),
      isPrimary: _isPrimary,
      oshiStartDate: _oshiStartDate,
      favoriteSong: _songController.text.trim().isEmpty
          ? 'まだ分からない'
          : _songController.text.trim(),
      memberColorHex: _memberColorHex,
      furigana: _profileFields['furigana']!.text.trim(),
      nickname: _profileFields['nickname']!.text.trim(),
      birthday: DateTime.tryParse(_profileFields['birthday']!.text.trim()),
      hometown: _profileFields['hometown']!.text.trim(),
      height: _profileFields['height']!.text.trim(),
      hobby: _profileFields['hobby']!.text.trim(),
      skill: _profileFields['skill']!.text.trim(),
      likes: _profileFields['likes']!.text.trim(),
      officialUrl: _profileFields['officialUrl']!.text.trim(),
      profile: _profileFields['profile']!.text.trim(),
      personalNickname: _profileFields['personalNickname']!.text.trim(),
      oshiReason: _profileFields['oshiReason']!.text.trim(),
      personalMemo: _profileFields['personalMemo']!.text.trim(),
      profilePhotoBase64: photo,
      profilePhotoHistory: photo == null ? <String>[] : <String>[photo],
    );

    Navigator.pop(context, oshi);
  }

  MemoryImage? _profileImage() {
    final value = _profilePhotoBase64;
    if (value == null || value.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(value));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = _profileImage();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '推しを追加',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                children: [
                  const Text(
                    '基本情報',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE7D8FA)),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: lightPurple,
                              backgroundImage: profileImage,
                              child: profileImage == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 58,
                                      color: purple,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Material(
                                color: purple,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _isPickingPhoto ? null : _pickPhoto,
                                  child: const Padding(
                                    padding: EdgeInsets.all(9),
                                    child: Icon(
                                      Icons.photo_camera_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _isPickingPhoto ? null : _pickPhoto,
                          icon: _isPickingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            profileImage == null ? '推しの写真を追加（任意）' : '写真を変更',
                          ),
                        ),
                        if (_profilePhotoBase64 != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _profilePhotoBase64 = null;
                              });
                            },
                            child: const Text('写真を外す'),
                          ),
                        const Text(
                          '選んだあとに正方形で位置・拡大を調整できます',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '推しの名前',
                      hintText: '例：愛宕 ここ',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '推しの名前を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  GroupSuggestionField(
                    initialValue: _groupName,
                    suggestions: widget.groupSuggestions,
                    requiredField: true,
                    onChanged: (value) {
                      _groupName = value;
                    },
                  ),
                  const SizedBox(height: 18),
                  MemberColorPicker(
                    valueHex: _memberColorHex,
                    onChanged: (value) {
                      setState(() {
                        _memberColorHex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE7D8FA)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      value: _isPrimary,
                      activeThumbColor: purple,
                      title: const Text(
                        '1推しに設定',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        widget.defaultPrimary
                            ? '最初の推しなのでONにしています'
                            : '1推しポイントの対象になります',
                      ),
                      secondary: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFB300),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isPrimary = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '推し活情報',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7D8FA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: purple,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              '推し開始日',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _dateText(),
                                style: const TextStyle(
                                  color: purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_oshiStartDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _warekiText(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _songController,
                    decoration: InputDecoration(
                      labelText: '好きな曲',
                      hintText: '分からない場合は空欄でOK',
                      prefixIcon: const Icon(Icons.music_note_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OshiProfileFields(controllers: _profileFields),
                  const SizedBox(height: 30),
                  FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text(
                      'この推しを登録',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OshiLife専用 西暦＋和暦カレンダー
// ============================================================

class WarekiDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const WarekiDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<WarekiDatePickerDialog> createState() => _WarekiDatePickerDialogState();
}

class _WarekiDatePickerDialogState extends State<WarekiDatePickerDialog> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);

  late DateTime _selectedDate;
  late DateTime _viewMonth;

  bool _yearMode = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    _viewMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _canPreviousMonth {
    final previous = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);

    final minimum = DateTime(widget.firstDate.year, widget.firstDate.month, 1);

    return !previous.isBefore(minimum);
  }

  bool get _canNextMonth {
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);

    final maximum = DateTime(widget.lastDate.year, widget.lastDate.month, 1);

    return !next.isAfter(maximum);
  }

  void _previousMonth() {
    if (!_canPreviousMonth) {
      return;
    }

    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canNextMonth) {
      return;
    }

    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
  }

  void _selectYear(int year) {
    var month = _viewMonth.month;

    if (year == widget.lastDate.year && month > widget.lastDate.month) {
      month = widget.lastDate.month;
    }

    if (year == widget.firstDate.year && month < widget.firstDate.month) {
      month = widget.firstDate.month;
    }

    setState(() {
      _viewMonth = DateTime(year, month, 1);

      _yearMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Column(
          children: [
            _buildTopHeader(),

            const Divider(height: 1),

            Expanded(child: _yearMode ? _buildYearPicker() : _buildCalendar()),

            const Divider(height: 1),

            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: const BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '推し始めた日を選択',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 7),

          Text(
            '${_selectedDate.year}年'
            '${_selectedDate.month}月'
            '${_selectedDate.day}日'
            '（${weekdayJapanese(_selectedDate.weekday)}）',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 3),

          Text(
            warekiDate(_selectedDate),
            style: const TextStyle(
              fontSize: 14,
              color: purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _yearMode = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            monthWarekiLabel(_viewMonth),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: _canPreviousMonth ? _previousMonth : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),

              IconButton(
                onPressed: _canNextMonth ? _nextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Row(
            children: [
              CalendarWeekday(text: '日', isSunday: true),
              CalendarWeekday(text: '月'),
              CalendarWeekday(text: '火'),
              CalendarWeekday(text: '水'),
              CalendarWeekday(text: '木'),
              CalendarWeekday(text: '金'),
              CalendarWeekday(text: '土', isSaturday: true),
            ],
          ),

          const SizedBox(height: 5),

          Expanded(child: _buildDays()),
        ],
      ),
    );
  }

  Widget _buildDays() {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);

    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;

    final leadingSpaces = firstDay.weekday % 7;

    final totalCells = ((leadingSpaces + daysInMonth + 6) ~/ 7) * 7;

    final today = DateTime.now();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final day = index - leadingSpaces + 1;

        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(_viewMonth.year, _viewMonth.month, day);

        final disabled =
            date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

        final selected = _sameDay(date, _selectedDate);

        final isToday = _sameDay(date, today);

        final weekday = date.weekday;

        Color textColor = Colors.black87;

        if (disabled) {
          textColor = Colors.black26;
        } else if (selected) {
          textColor = Colors.white;
        } else if (weekday == DateTime.sunday) {
          textColor = const Color(0xFFD75C72);
        } else if (weekday == DateTime.saturday) {
          textColor = const Color(0xFF5D76C7);
        }

        return Center(
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: disabled
                ? null
                : () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? purple : Colors.transparent,
                border: isToday && !selected
                    ? Border.all(color: purple, width: 1.5)
                    : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearPicker() {
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;

    final years = [for (var year = firstYear; year <= lastYear; year++) year];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '年を選択',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Spacer(),

              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _yearMode = false;
                  });
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('月表示に戻る'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 4 : 3;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 1.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];

                    final selected = year == _viewMonth.year;

                    return InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        _selectYear(year);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: selected ? purple : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selected ? purple : const Color(0xFFE4DDF0),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$year年',
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              warekiYearLabel(year),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? Colors.white70 : purple,
                                fontSize: year == 1989 || year == 2019 ? 9 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),

          const SizedBox(width: 8),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () {
              Navigator.pop(context, _selectedDate);
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 曜日
// ============================================================

class CalendarWeekday extends StatelessWidget {
  final String text;
  final bool isSunday;
  final bool isSaturday;

  const CalendarWeekday({
    super.key,
    required this.text,
    this.isSunday = false,
    this.isSaturday = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.black54;

    if (isSunday) {
      color = const Color(0xFFD75C72);
    }

    if (isSaturday) {
      color = const Color(0xFF5D76C7);
    }

    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ============================================================
// 日付・和暦 共通関数
// ============================================================

String weekdayJapanese(int weekday) {
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  return weekdays[weekday - 1];
}

String warekiDate(DateTime date) {
  String era;
  int eraYear;

  if (!date.isBefore(DateTime(2019, 5, 1))) {
    era = '令和';
    eraYear = date.year - 2018;
  } else if (!date.isBefore(DateTime(1989, 1, 8))) {
    era = '平成';
    eraYear = date.year - 1988;
  } else {
    era = '昭和';
    eraYear = date.year - 1925;
  }

  final yearText = eraYear == 1 ? '元' : '$eraYear';

  return '$era$yearText年'
      '${date.month}月'
      '${date.day}日';
}

String warekiYearLabel(int year) {
  if (year == 2019) {
    return '平成31年 / 令和元年';
  }

  if (year == 1989) {
    return '昭和64年 / 平成元年';
  }

  if (year >= 2020) {
    return '令和${year - 2018}年';
  }

  if (year >= 1990) {
    return '平成${year - 1988}年';
  }

  return '昭和${year - 1925}年';
}

String monthWarekiLabel(DateTime date) {
  String wareki;

  if (date.year == 2019) {
    if (date.month >= 5) {
      wareki = '令和元年';
    } else {
      wareki = '平成31年';
    }
  } else if (date.year == 1989 && date.month == 1) {
    wareki = '昭和64年 / 平成元年';
  } else if (date.year >= 2020) {
    wareki = '令和${date.year - 2018}年';
  } else if (date.year >= 1990) {
    wareki = '平成${date.year - 1988}年';
  } else {
    wareki = '昭和${date.year - 1925}年';
  }

  return '${date.year}年'
      '${date.month}月'
      '（$wareki）';
}
