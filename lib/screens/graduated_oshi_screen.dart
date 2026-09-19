import 'package:flutter/material.dart';

import '../models/oshi.dart';
import '../utils/member_color.dart';

class GraduatedOshiScreen extends StatefulWidget {
  final List<Oshi> oshis;

  const GraduatedOshiScreen({
    super.key,
    required this.oshis,
    this.onChanged,
    this.onOpenDetail,
  });

  final Future<void> Function()? onChanged;
  final void Function(Oshi)? onOpenDetail;

  @override
  State<GraduatedOshiScreen> createState() =>
      _GraduatedOshiScreenState();
}

class _GraduatedOshiScreenState
    extends State<GraduatedOshiScreen> {
  static const purple = Color(0xFF9B5CFF);
  static const background = Color(0xFFFFF8FF);
  static const lightPurple = Color(0xFFF2E8FF);

  List<Oshi> get graduatedOshis {
    return widget.oshis
        .where((oshi) => oshi.isGraduated)
        .toList();
  }

  String _dateText(DateTime? date) {
    if (date == null) {
      return '日付未設定';
    }

    return '${date.year}年${date.month}月${date.day}日';
  }

  String _warekiText(DateTime? date) {
    if (date == null) {
      return '';
    }

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

    return '$era$yearText年${date.month}月${date.day}日';
  }

  Future<void> _restoreOshi(Oshi oshi) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '現役推しに戻す',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${oshi.name}を現役の推し一覧に戻しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: purple,
              ),
              child: const Text('戻す'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    setState(() {
      oshi.restore();
    });

    await widget.onChanged?.call();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${oshi.name}を現役推しに戻しました！',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oshis = graduatedOshis;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          '卒業・過去の推し',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: oshis.isEmpty
                ? const _EmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      30,
                    ),
                    itemCount: oshis.length,
                    separatorBuilder: (
                      context,
                      index,
                    ) {
                      return const SizedBox(
                        height: 12,
                      );
                    },
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final oshi = oshis[index];
                      final memberColor = colorFromHex(oshi.memberColorHex) ?? purple;
                      final memberTextColor = readableMemberColor(memberColor);

                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: widget.onOpenDetail == null
                            ? null
                            : () => widget.onOpenDetail!(oshi),
                        child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFE9E0FA,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: softMemberColor(memberColor),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: memberTextColor,
                                    size: 31,
                                  ),
                                ),

                                const SizedBox(width: 13),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        oshi.name,
                                        style: TextStyle(
                                          color: memberTextColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 2,
                                      ),

                                      Text(
                                        oshi.groupName,
                                        style:
                                            const TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF4F1F6,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: const Text(
                                    '過去推し',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.black54,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            const Divider(
                              height: 1,
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: Colors.black45,
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        '卒業・移動日',
                                        style:
                                            TextStyle(
                                          fontSize: 10,
                                          color:
                                              Colors.black45,
                                        ),
                                      ),
                                      Text(
                                        _dateText(
                                          oshi.graduatedAt,
                                        ),
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (oshi.graduatedAt !=
                                          null)
                                        Text(
                                          _warekiText(
                                            oshi.graduatedAt,
                                          ),
                                          style:
                                              const TextStyle(
                                            fontSize: 10,
                                            color: purple,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                TextButton.icon(
                                  onPressed: () {
                                    _restoreOshi(oshi);
                                  },
                                  icon: const Icon(
                                    Icons
                                        .settings_backup_restore_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    '現役に戻す',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 58,
            color: Color(0xFFB7A9CB),
          ),
          SizedBox(height: 14),
          Text(
            '卒業・過去の推しはいません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '移動した推しはここに残ります',
            style: TextStyle(
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}