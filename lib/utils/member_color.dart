import 'dart:math' as math;

import 'package:flutter/material.dart';

Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

String colorToHex(Color color) {
  final value = color.value & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

double _linearize(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  final r = color.red / 255.0;
  final g = color.green / 255.0;
  final b = color.blue / 255.0;
  return 0.2126 * _linearize(r) +
      0.7152 * _linearize(g) +
      0.0722 * _linearize(b);
}

double _contrastRatio(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

/// 登録したメンバーカラーの雰囲気を保ちつつ、白背景上でも文字が
/// 読みやすいように自動で濃くする。
Color readableMemberColor(
  Color memberColor, {
  Color background = Colors.white,
  double minimumContrast = 4.5,
}) {
  if (_contrastRatio(memberColor, background) >= minimumContrast) {
    return memberColor;
  }

  final hsl = HSLColor.fromColor(memberColor);

  // 白・グレー系は彩度がほぼないため、そのまま濃いグレーへ寄せる。
  if (hsl.saturation < 0.08) {
    return const Color(0xFF5F6368);
  }

  var lightness = hsl.lightness;
  for (var i = 0; i < 20; i++) {
    lightness = (lightness - 0.035).clamp(0.12, 0.78).toDouble();
    final candidate = hsl.withLightness(lightness).toColor();
    if (_contrastRatio(candidate, background) >= minimumContrast) {
      return candidate;
    }
  }

  return hsl.withLightness(0.28).toColor();
}

Color softMemberColor(Color memberColor) {
  return Color.alphaBlend(memberColor.withOpacity(0.16), Colors.white);
}
