import 'package:flutter/material.dart';

const profileLabels = <String, String>{
  'furigana': 'ふりがな',
  'nickname': 'ニックネーム',
  'birthday': '誕生日（例：4月12日 / 2001-04-12）',
  'hometown': '出身地',
  'height': '身長',
  'hobby': '趣味',
  'skill': '特技',
  'likes': '好きなもの',
  'officialUrl': '公式SNS / URL',
  'profile': 'その他プロフィール',
  'personalNickname': '自分での呼び方',
  'oshiReason': '推したきっかけ',
  'personalMemo': '自分用メモ',
};

class OshiProfileFields extends StatelessWidget {
  const OshiProfileFields({super.key, required this.controllers});
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '基本プロフィール（すべて任意）',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      for (final key in profileLabels.keys) ...[
        if (key == 'personalNickname') ...[
          const SizedBox(height: 12),
          const Text(
            '自分だけの推し情報',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: controllers[key],
            maxLines: key == 'profile' || key == 'personalMemo' ? 3 : 1,
            decoration: InputDecoration(
              labelText: profileLabels[key],
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    ],
  );
}
