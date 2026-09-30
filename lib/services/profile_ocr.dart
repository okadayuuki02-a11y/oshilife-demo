import 'dart:typed_data';

import 'profile_ocr_stub.dart'
    if (dart.library.html) 'profile_ocr_web.dart' as platform;

Future<String?> recognizeProfileImage(Uint8List bytes) =>
    platform.recognizeProfileImage(bytes);

class ProfileOcrResult {
  const ProfileOcrResult({
    required this.rawText,
    this.name = '',
    this.groupName = '',
    this.furigana = '',
    this.nickname = '',
    this.birthday = '',
    this.hometown = '',
    this.height = '',
    this.hobby = '',
    this.skill = '',
    this.likes = '',
    this.officialUrl = '',
    this.memberColor = '',
  });

  final String rawText;
  final String name;
  final String groupName;
  final String furigana;
  final String nickname;
  final String birthday;
  final String hometown;
  final String height;
  final String hobby;
  final String skill;
  final String likes;
  final String officialUrl;
  final String memberColor;

  int get filledCount => [
    name,
    groupName,
    furigana,
    nickname,
    birthday,
    hometown,
    height,
    hobby,
    skill,
    likes,
    officialUrl,
    memberColor,
  ].where((value) => value.trim().isNotEmpty).length;
}

ProfileOcrResult parseProfileText(String rawText) {
  final normalized = rawText
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'\n+'), '\n')
      .trim();
  final lines = normalized
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String labeled(List<String> labels) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final label in labels) {
        final escaped = RegExp.escape(label);
        final match = RegExp(
          '^$escaped\\s*[：:]?\\s*(.+)\$',
          caseSensitive: false,
        ).firstMatch(line);
        if (match != null && match.group(1)!.trim().isNotEmpty) {
          return match.group(1)!.trim();
        }
        if (RegExp('^$escaped\\s*[：:]?\\s*\$', caseSensitive: false)
                .hasMatch(line) &&
            i + 1 < lines.length) {
          return lines[i + 1].trim();
        }
      }
    }
    return '';
  }

  var name = labeled(['名前', '氏名', 'NAME', 'Name']);
  final group = labeled(['所属グループ', 'グループ', '所属', 'GROUP', 'Group']);
  final furigana = labeled(['ふりがな', 'フリガナ', 'よみ', '読み']);
  final nickname = labeled(['ニックネーム', '愛称', 'あだ名']);
  var birthday = labeled(['誕生日', '生年月日', 'BIRTHDAY', 'Birthday']);
  final hometown = labeled(['出身地', '出身', 'HOMETOWN', 'Hometown']);
  var height = labeled(['身長', 'HEIGHT', 'Height']);
  final hobby = labeled(['趣味', 'HOBBY', 'Hobby']);
  final skill = labeled(['特技', 'SPECIAL SKILL', 'Skill']);
  final likes = labeled(['好きなもの', '好きなこと', '好きな食べ物', 'LIKE', 'Likes']);
  final color = labeled(['メンバーカラー', '担当カラー', '担当色', 'カラー', 'COLOR', 'Color']);

  final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(normalized);
  final accountMatch = RegExp(r'@[A-Za-z0-9_]{2,}').firstMatch(normalized);
  final officialUrl = urlMatch?.group(0) ?? accountMatch?.group(0) ?? '';

  if (birthday.isEmpty) {
    final match = RegExp(
      r'(?:(\d{4})[年./-]\s*)?(\d{1,2})[月./-]\s*(\d{1,2})日?',
    ).firstMatch(normalized);
    if (match != null) {
      final year = match.group(1);
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      if (month != null && day != null) {
        birthday = year == null
            ? '$month月$day日'
            : '${year.padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
    }
  }

  if (height.isEmpty) {
    final match = RegExp(r'(\d{3}(?:\.\d+)?)\s*cm', caseSensitive: false)
        .firstMatch(normalized);
    if (match != null) height = '${match.group(1)}cm';
  }

  if (name.isEmpty) {
    final excluded = <String>{
      group,
      furigana,
      nickname,
      birthday,
      hometown,
      height,
      hobby,
      skill,
      likes,
      color,
    }.where((value) => value.isNotEmpty).toSet();
    for (final line in lines.take(8)) {
      if (excluded.contains(line)) continue;
      if (line.contains('：') || line.contains(':')) continue;
      if (line.startsWith('http') || line.startsWith('@')) continue;
      if (RegExp(r'\d').hasMatch(line)) continue;
      if (line.length < 2 || line.length > 20) continue;
      if (['PROFILE', 'プロフィール', 'MEMBER', 'メンバー'].contains(line.toUpperCase())) {
        continue;
      }
      name = line;
      break;
    }
  }

  return ProfileOcrResult(
    rawText: normalized,
    name: name,
    groupName: group,
    furigana: furigana,
    nickname: nickname,
    birthday: birthday,
    hometown: hometown,
    height: height,
    hobby: hobby,
    skill: skill,
    likes: likes,
    officialUrl: officialUrl,
    memberColor: color,
  );
}

String? memberColorHexFromText(String value) {
  final text = value.toLowerCase();
  const colors = <String, String>{
    '水色': '#63C7E8',
    'ライトブルー': '#63C7E8',
    '青': '#4A77E8',
    'ブルー': '#4A77E8',
    '赤': '#EF5350',
    'レッド': '#EF5350',
    'ピンク': '#F06292',
    '桃': '#F06292',
    '紫': '#9B5CFF',
    'パープル': '#9B5CFF',
    '黄': '#F4C542',
    '黄色': '#F4C542',
    'イエロー': '#F4C542',
    '緑': '#4CAF72',
    'グリーン': '#4CAF72',
    'オレンジ': '#F59A45',
    '橙': '#F59A45',
    '白': '#F5F5F5',
    'ホワイト': '#F5F5F5',
    '黒': '#424242',
    'ブラック': '#424242',
  };
  for (final entry in colors.entries) {
    if (text.contains(entry.key.toLowerCase())) return entry.value;
  }
  return null;
}
