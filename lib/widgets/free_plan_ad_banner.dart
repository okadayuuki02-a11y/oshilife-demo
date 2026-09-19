import 'package:flutter/material.dart';

class FreePlanAdBanner extends StatelessWidget {
  const FreePlanAdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEADFF5)),
          bottom: BorderSide(color: Color(0xFFEADFF5)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF2E8FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'AD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF9B5CFF),
              ),
            ),
          ),
          const SizedBox(width: 9),
          const Flexible(
            child: Text(
              '広告表示エリア（無料プラン）',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF716B78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
