import 'package:flutter/material.dart';

/// Color tokens mirroring the dark palette of janilson.alfser.com.br, so the
/// app reads as part of the same design system.
abstract final class AppColors {
  static const bg = Color(0xFF0A0E1A);
  static const bgAlt = Color(0xFF0F1628);
  static const surface = Color(0x990F1628);
  static const surfaceHover = Color(0x9916213E);
  static const border = Color(0x143884F4);
  static const borderHover = Color(0x333884F4);

  static const text = Color(0xFFCDD9E5);
  static const textSecondary = Color(0xFF768390);
  static const textMuted = Color(0xFF545D68);

  static const accent = Color(0xFF3884F4);
  static const accentHover = Color(0xFF58A6FF);
  static const accentSecondary = Color(0xFF0EA5E9);
  static const accentGlow = Color(0x1F3884F4);

  static const tagBg = Color(0x143884F4);
  static const tagText = Color(0xFF58A6FF);

  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFF85149);

  /// Signals a confirmed in-tune reading (gauge target zone, needle, note
  /// label). Kept apart from [accentSecondary] since it needs to read as
  /// unambiguously "good" against the rest of the blue-toned palette.
  static const inTune = Color(0xFF3FB950);
  static const inTuneGlow = Color(0x333FB950);
}
