import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/oshi.dart';
import '../widgets/group_suggestion_field.dart';
import '../widgets/member_color_picker.dart';
import '../widgets/photo_crop_screen.dart';

class OshiEditScreen extends StatefulWidget {
  const OshiEditScreen({
    super.key,
    required this.oshi,
    this.groupSuggestions = const <String>[],
  });

  final Oshi oshi;
  final List<String> groupSuggestions;

  @override
  State<OshiEditScreen> createState() => _OshiEditScreenState();
}

class _OshiEditScreenState extends State<OshiEditScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const lightPurple = Color(0xFFF2E8FF);
  static const background = Color(0xFFFFF8FF);
  static const maxPhotoHistory = 5;

  late final TextEditingController _nameController;
  late final TextEditingController _groupController;
  late final TextEditingController _favoriteSongController;

  late bool _isPrimary;
  late DateTime? _oshiStartDate;
  late bool _isGraduated;
  late DateTime? _graduatedAt;
  String? _memberColorHex;

  String? _currentPhoto;
  late List<String> _photoHistory;

  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    final oshi = widget.oshi;

    _nameController = TextEditingController(text: oshi.name);
    _groupController = TextEditingController(text: oshi.groupName);
    _favoriteSongController = TextEditingController(text: oshi.favoriteSong);

    _isPrimary = oshi.isPrimary;
    _oshiStartDate = oshi.oshiStartDate;
    _isGraduated = oshi.isGraduated;
    _graduatedAt = oshi.graduatedAt;
    _memberColorHex = oshi.memberColorHex;

    _currentPhoto = oshi.profilePhotoBase64;
    _photoHistory = [...oshi.profilePhotoHistory];

    if (_currentPhoto != null &&
        _currentPhoto!.isNotEmpty &&
        !_photoHistory.contains(_currentPhoto)) {
      _photoHistory.insert(0, _currentPhoto!);
    }

    if (_photoHistory.length > maxPhotoHistory) {
      _photoHistory = _photoHistory.take(maxPhotoHistory).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _favoriteSongController.dispose();
    super.dispose();
  }

  String _dateText(DateTime? date) {
    if (date == null) return '未設定';
    const week = ['月', '火', '水', '木', '金', '土', '日'];
    return '${date.year}年${date.month}月${date.day}日（${week[date.weekday - 1]}）';
  }

  Future<void> _pickOshiStartDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _oshiStartDate ?? now,
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      locale: const Locale('ja', 'JP'),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _oshiStartDate = selected;
    });
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
      final encoded = base64Encode(cropped);

      setState(() {
        _currentPhoto = encoded;
        _photoHistory.remove(encoded);
        _photoHistory.insert(0, encoded);

        if (_photoHistory.length > maxPhotoHistory) {
          _photoHistory = _photoHistory.take(maxPhotoHistory).toList();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _selectHistoryPhoto(String encoded) {
    setState(() {
      _currentPhoto = encoded;
      _photoHistory.remove(encoded);
      _photoHistory.insert(0, encoded);
    });
  }

  void _deleteHistoryPhoto(String encoded) {
    if (encoded == _currentPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('使用中の画像は「現在の写真を外す」から変更できます'),
        ),
      );
      return;
    }

    setState(() {
      _photoHistory.remove(encoded);
    });
  }

  void _removeCurrentPhoto() {
    setState(() {
      _currentPhoto = null;
    });
  }

  Future<void> _moveToGraduated() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _graduatedAt ?? now,
      firstDate: _oshiStartDate ?? DateTime(1970, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      locale: const Locale('ja', 'JP'),
      helpText: '卒業日を選択',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _isGraduated = true;
      _graduatedAt = selected;
      _isPrimary = false;
    });
  }

  void _restoreActive() {
    setState(() {
      _isGraduated = false;
      _graduatedAt = null;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final group = _groupController.text.trim();
    final song = _favoriteSongController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('推しの名前を入力してください')),
      );
      return;
    }

    final oshi = widget.oshi;
    oshi.name = name;
    oshi.groupName = group;
    oshi.oshiStartDate = _oshiStartDate;
    oshi.favoriteSong = song.isEmpty ? 'まだ分からない' : song;
    oshi.memberColorHex = _memberColorHex;

    if (_isGraduated) {
      oshi.graduate(date: _graduatedAt);
    } else {
      oshi.restore();
      oshi.isPrimary = _isPrimary;
    }

    oshi.profilePhotoBase64 = _currentPhoto;
    oshi.profilePhotoHistory = [..._photoHistory];

    Navigator.of(context).pop(oshi);
  }

  MemoryImage? _memoryImage(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(encoded));
    } catch (_) {
      return null;
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
          '推しを編集',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
            children: [
              const Text(
                '基本情報',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _photoSection(),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '推しの名前',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GroupSuggestionField(
                initialValue: _groupController.text,
                suggestions: widget.groupSuggestions,
                onChanged: (value) {
                  _groupController.value = TextEditingValue(
                    text: value,
                    selection: TextSelection.collapsed(offset: value.length),
                  );
                },
              ),
              const SizedBox(height: 16),
              MemberColorPicker(
                valueHex: _memberColorHex,
                onChanged: (value) {
                  setState(() {
                    _memberColorHex = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6DCF8)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFB300),
                  ),
                  title: const Text(
                    '1推しに設定',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text('変更すると現在の1推しと入れ替わります'),
                  value: _isPrimary,
                  activeThumbColor: purple,
                  onChanged: _isGraduated
                      ? null
                      : (value) {
                          setState(() {
                            _isPrimary = value;
                          });
                        },
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                '推し活情報',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickOshiStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6DCF8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: purple),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '推し開始日',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _dateText(_oshiStartDate),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: purple,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                    ],
                  ),
                ),
              ),
              if (_oshiStartDate != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _oshiStartDate = null;
                      });
                    },
                    child: const Text('推し開始日を未設定に戻す'),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _favoriteSongController,
                decoration: const InputDecoration(
                  labelText: '好きな曲',
                  prefixIcon: Icon(Icons.music_note_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoSection() {
    final currentImage = _memoryImage(_currentPhoto);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DCF8)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: lightPurple,
                backgroundImage: currentImage,
                child: currentImage == null
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              currentImage == null ? '推しの写真を追加' : '新しい写真を選ぶ',
            ),
          ),
          if (_currentPhoto != null)
            TextButton(
              onPressed: _removeCurrentPhoto,
              child: const Text('現在の写真を外す'),
            ),
          if (_photoHistory.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '最近使った画像',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoHistory.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final encoded = _photoHistory[index];
                  final image = _memoryImage(encoded);
                  final isCurrent = encoded == _currentPhoto;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _selectHistoryPhoto(encoded),
                        child: Container(
                          width: 62,
                          height: 62,
                          padding: EdgeInsets.all(isCurrent ? 3 : 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent ? purple : const Color(0xFFE6DCF8),
                              width: isCurrent ? 3 : 1,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: lightPurple,
                            backgroundImage: image,
                            child: image == null
                                ? const Icon(Icons.person_rounded, color: purple)
                                : null,
                          ),
                        ),
                      ),
                      if (!isCurrent)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: InkWell(
                            onTap: () => _deleteHistoryPhoto(encoded),
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF5F5965),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '過去の写真は最大5枚まで保存します',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
