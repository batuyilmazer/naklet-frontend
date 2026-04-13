import 'package:flutter/material.dart';
import 'app_color_scheme.dart';

/// Dark theme color scheme implementation.
///
/// Uses darker colors suitable for dark backgrounds.
class DarkColorScheme implements AppColorScheme {
  const DarkColorScheme();

  @override
  Color get primary => const Color(0xFFFFB36B);

  @override
  Color get onPrimary => const Color(0xFF24170F);

  @override
  Color get background => const Color(0xFF17110D);

  @override
  Color get textPrimary => const Color(0xFFFFF1E4);

  @override
  Color get textSecondary => const Color(0xFFD0B9A6);

  @override
  Color get textDisabled => const Color(0xFF8C7565);

  @override
  Color get error => const Color(0xFFFF8C7A);

  @override
  Color get success => const Color(0xFF6DDB9A);

  @override
  Color get warning => const Color(0xFFFFC86F);

  @override
  Color get info => const Color(0xFF8DC4FF);

  @override
  Color get surface => const Color(0xFF241A14);

  @override
  Color get onSurface => textPrimary;

  @override
  Color get surfaceVariant => const Color(0xFF352720);

  @override
  Color get border => const Color(0xFF46342A);

  @override
  Color get divider => border;

  @override
  Color get disabled => const Color(0xFF382A22);

  @override
  Color get overlay => const Color(0xB3000000);

  @override
  Color get iconSubtle => textSecondary;

  @override
  Color get iconStrong => textPrimary;

  @override
  ColorScheme get materialColorScheme =>
      ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);
}
