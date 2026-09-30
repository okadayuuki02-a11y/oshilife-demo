import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_analysis.dart';

class ProfileAutoFillButton extends StatefulWidget {
  const ProfileAutoFillButton({
    super.key,
    required this.nameController,
    required this.profileControllers,
    required this.currentGroupName,
    required this.onGroupDetected,
    this.currentMemberColorHex,
    this.onMemberColorDetected,
  });

  final TextEditingController nameController;
  final Map<String, TextEditingController> profileControllers;
  final String currentGroupName;
  final ValueChanged<String> onGroupDetected;
  final String? currentMemberColorHex;
  final ValueChanged<String>? onMemberColorDetected;

  @override
  State<ProfileAutoFillButton> createState() => _ProfileAutoFillButtonState();
}

class _ProfileAutoFillButtonState extends State<ProfileAutoFillButton> {
  static const _purple = Color(0xFF9B5CFF);
  bool _loading = false;

  Future<void> _runAnalysis() async {
    if (_loading) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 2400,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final result = await ImageAnalysisService.analyzeProfile(
        await file.readAsBytes(),
      );
      if (!mounted) return;
      await _showPreview(result);
    } on ImageAnalysisUnavailable catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('AI画像解析へ切り替え中'),
          content: Text(
            '${error.message}\n\n旧OCRは誤読が多かったため、update12修正版では自動入力に使わないよう停止しています。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィール画像の解析に失敗しました。')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showPreview(ProfileImageAnalysis result) async {
    var onlyEmpty = true;
    final candidates = <MapEntry<String, String>>[
      MapEntry('名前', result.name),
      MapEntry('グループ', result.groupName),
      MapEntry('ふりがな', result.furigana),
      MapEntry('ニックネーム', result.nickname),
      MapEntry('誕生日', result.birthday),
      MapEntry('出身地', result.hometown),
      MapEntry('身長', result.height),
      MapEntry('趣味', result.hobby),
      MapEntry('特技', result.skill),
      MapEntry('好きなもの', result.likes),
      MapEntry('公式SNS / URL', result.officialUrl),
      MapEntry('メンバーカラー', result.memberColor),
    ].where((e) => e.value.trim().isNotEmpty).toList();

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8FF),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
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
                  const Text(
                    'プロフィールを自動入力',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    candidates.isEmpty
                        ? '入力候補を見つけられませんでした。'
                        : '${candidates.length}項目の候補を見つけました。内容を確認してから反映してください。',
                    style: const TextStyle(color: Color(0xFF716B78)),
                  ),
                  const SizedBox(height: 14),
                  if (candidates.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8E0F7)),
                      ),
                      child: Column(
                        children: [
                          for (final entry in candidates)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 104,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF716B78),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: onlyEmpty,
                    activeThumbColor: _purple,
                    title: const Text('入力済みの項目は上書きしない'),
                    subtitle: const Text('空欄だけ自動で埋めます。'),
                    onChanged: (value) =>
                        setSheetState(() => onlyEmpty = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('キャンセル'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: _purple),
                          onPressed: candidates.isEmpty
                              ? null
                              : () => Navigator.pop(ctx, true),
                          child: const Text('フォームに反映'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (apply == true && mounted) _apply(result, onlyEmpty: onlyEmpty);
  }

  void _apply(ProfileImageAnalysis result, {required bool onlyEmpty}) {
    void setText(TextEditingController? controller, String value) {
      if (controller == null || value.trim().isEmpty) return;
      if (onlyEmpty && controller.text.trim().isNotEmpty) return;
      controller.value = TextEditingValue(
        text: value.trim(),
        selection: TextSelection.collapsed(offset: value.trim().length),
      );
    }

    setText(widget.nameController, result.name);
    if (result.groupName.trim().isNotEmpty &&
        (!onlyEmpty || widget.currentGroupName.trim().isEmpty)) {
      widget.onGroupDetected(result.groupName.trim());
    }
    setText(widget.profileControllers['furigana'], result.furigana);
    setText(widget.profileControllers['nickname'], result.nickname);
    setText(widget.profileControllers['birthday'], result.birthday);
    setText(widget.profileControllers['hometown'], result.hometown);
    setText(widget.profileControllers['height'], result.height);
    setText(widget.profileControllers['hobby'], result.hobby);
    setText(widget.profileControllers['skill'], result.skill);
    setText(widget.profileControllers['likes'], result.likes);
    setText(widget.profileControllers['officialUrl'], result.officialUrl);

    final colorHex = memberColorHexFromAnalysis(result.memberColor);
    if (colorHex != null &&
        widget.onMemberColorDetected != null &&
        (!onlyEmpty || widget.currentMemberColorHex == null)) {
      widget.onMemberColorDetected!(colorHex);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('候補を入力しました。内容を確認して保存してください。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _runAnalysis,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF2E8FF),
          foregroundColor: _purple,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(_loading ? '画像を解析中…' : 'プロフィール画像から自動入力'),
      ),
    );
  }
}
