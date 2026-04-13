import 'package:flutter/material.dart';
import 'app_color_scheme.dart';

/// Light theme color scheme implementation.
///
/// Uses bright colors suitable for light backgrounds.
class LightColorScheme implements AppColorScheme {
  const LightColorScheme();

  @override
  Color get primary => const Color(0xFFCC5A2E);

  @override
  Color get onPrimary => const Color(0xFFFFFAF5);

  @override
  Color get background => const Color(0xFFFFF8F0);

  @override
  Color get textPrimary => const Color(0xFF2B1B12);

  @override
  Color get textSecondary => const Color(0xFF866E61);

  @override
  Color get textDisabled => const Color(0xFFB8A79C);

  @override
  Color get error => const Color(0xFFC64C4C);

  @override
  Color get success => const Color(0xFF2F8F62);

  @override
  Color get warning => const Color(0xFFE59B3A);

  @override
  Color get info => const Color(0xFF5087B8);

  @override
  Color get surface => const Color(0xFFFFFCF8);

  @override
  Color get onSurface => textPrimary;

  @override
  Color get surfaceVariant => const Color(0xFFF4E6D7);

  @override
  Color get border => const Color(0xFFE6D2C0);

  @override
  Color get divider => border;

  @override
  Color get disabled => const Color(0xFFF2E8DE);

  @override
  Color get overlay => const Color(0x80000000);

  @override
  Color get iconSubtle => textSecondary;

  @override
  Color get iconStrong => textPrimary;

  @override
  ColorScheme get materialColorScheme =>
      ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light);
}
