import 'package:flutter/material.dart';

import '../utils/member_color.dart';

class MemberColorPicker extends StatelessWidget {
  const MemberColorPicker({
    super.key,
    required this.valueHex,
    required this.onChanged,
  });

  final String? valueHex;
  final ValueChanged<String?> onChanged;

  static const _presets = <_MemberColorPreset>[
    _MemberColorPreset('ピンク', Color(0xFFFF5AA5)),
    _MemberColorPreset('赤', Color(0xFFE53935)),
    _MemberColorPreset('オレンジ', Color(0xFFFF8A00)),
    _MemberColorPreset('黄', Color(0xFFFFD21F)),
    _MemberColorPreset('緑', Color(0xFF34A853)),
    _MemberColorPreset('ミント', Color(0xFF50C9A7)),
    _MemberColorPreset('水色', Color(0xFF59C7F7)),
    _MemberColorPreset('青', Color(0xFF3478F6)),
    _MemberColorPreset('紫', Color(0xFF9B5CFF)),
    _MemberColorPreset('白', Color(0xFFFFFFFF)),
    _MemberColorPreset('黒', Color(0xFF202124)),
  ];

  Future<void> _showCustomColorDialog(BuildContext context) async {
    final controller = TextEditingController(text: valueHex ?? '#');
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('その他のメンバーカラー'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'カラーコード',
                  hintText: '#FF66CC',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    var text = controller.text.trim().toUpperCase();
                    if (!text.startsWith('#')) text = '#$text';
                    if (colorFromHex(text) == null) {
                      setState(() {
                        errorText = '#RRGGBB の形式で入力してください';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, text);
                  },
                  child: const Text('設定'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final selected = colorFromHex(valueHex);
    final textColor = selected == null ? null : readableMemberColor(selected);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6DCF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: Color(0xFF9B5CFF)),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'メンバーカラー',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (selected != null)
                Text(
                  '文字表示サンプル',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in _presets)
                _ColorChoice(
                  label: preset.label,
                  color: preset.color,
                  selected: valueHex?.toUpperCase() ==
                      colorToHex(preset.color).toUpperCase(),
                  onTap: () => onChanged(colorToHex(preset.color)),
                ),
              _OtherChoice(
                selected: selected != null &&
                    !_presets.any((p) =>
                        colorToHex(p.color).toUpperCase() ==
                        valueHex?.toUpperCase()),
                onTap: () => _showCustomColorDialog(context),
              ),
              _NoneChoice(
                selected: valueHex == null,
                onTap: () => onChanged(null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '明るい色でも、名前の文字は見やすい濃さへ自動調整されます。',
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MemberColorPreset {
  const _MemberColorPreset(this.label, this.color);
  final String label;
  final Color color;
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVeryLight = color.computeLuminance() > 0.78;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? const Color(0xFF202124)
                : (isVeryLight ? Colors.black26 : Colors.transparent),
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? const [BoxShadow(blurRadius: 4, color: Color(0x22000000))]
              : null,
        ),
        alignment: Alignment.center,
        child: selected
            ? Icon(
                Icons.check_rounded,
                color: color.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white,
              )
            : Tooltip(message: label, child: const SizedBox.expand()),
      ),
    );
  }
}

class _OtherChoice extends StatelessWidget {
  const _OtherChoice({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.colorize_rounded, size: 18),
      label: const Text('その他'),
      side: selected
          ? const BorderSide(color: Color(0xFF9B5CFF), width: 2)
          : null,
      onPressed: onTap,
    );
  }
}

class _NoneChoice extends StatelessWidget {
  const _NoneChoice({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: const Text('未設定'),
      side: selected
          ? const BorderSide(color: Color(0xFF9B5CFF), width: 2)
          : null,
      onPressed: onTap,
    );
  }
}
